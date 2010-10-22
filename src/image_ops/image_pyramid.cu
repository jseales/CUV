#include "image_pyramid.hpp"

#define iDivUp(X,Y) (ceil((X)/(float)(Y)))
#define CB_TILE_W  16
#define CB_TILE_H  16
#define KERNEL_SIZE 5
#define HALF_KERNEL 2
#define NORM_FACTOR 0.00390625f // 1.0/(16^2)

texture<float,         2, cudaReadModeElementType> ip_float_tex; 
texture<unsigned char, 2, cudaReadModeElementType> ip_uc_tex; 
texture<float4,        2, cudaReadModeElementType> ip_float4_tex; 
texture<uchar4,        2, cudaReadModeElementType> ip_uc4_tex; 

template<class T> struct texref{ };
template<> struct texref<float>{ 
	typedef texture<float, 2, cudaReadModeElementType> type;
	static type& get(){ return ip_float_tex; }; 
	__device__ float         operator()(float i, float j){return tex2D(ip_float_tex, i,j);} };
template<> struct texref<unsigned char>{ 
	typedef texture<unsigned char, 2, cudaReadModeElementType> type;
	static type& get(){ return ip_uc_tex; }; 
	__device__ unsigned char operator()(float i, float j){return tex2D(ip_uc_tex,i,j);} };
template<> struct texref<float4>{ 
	typedef texture<float4, 2, cudaReadModeElementType> type;
	static type& get(){ return ip_float4_tex; }; 
	__device__ float4        operator()(float i, float j){return tex2D(ip_float4_tex, i,j);} };
template<> struct texref<uchar4>{ 
	typedef texture<uchar4, 2, cudaReadModeElementType> type;
	static type& get(){ return ip_uc4_tex; }; 
	__device__ uchar4 operator()(float i, float j){return tex2D(ip_uc4_tex,i,j);} };



namespace cuv{
	template<class T> __device__ T plus4(const T& a, const T& b){ 
		T tmp = a;
		tmp.x += b.x;
		tmp.y += b.y;
		tmp.z += b.z;
		return tmp;
	}
	template<class T, class S> __device__ T mul4 (const S& s, const T& a){ 
		T tmp = a;
		tmp.x *= s;
		tmp.y *= s;
		tmp.z *= s;
		return tmp;
	}
	//                         
	// Gaussian 5 x 5 kernel = [1, 4, 6, 4, 1]/16
	//
	template<class S, class T>
	__global__
		void
		gaussian_pyramid_downsample_kernel4val(T* downLevel,
				size_t downLevelPitch,
				unsigned int downWidth, unsigned int downHeight)
		{
			// calculate normalized texture coordinates
			unsigned int x = blockIdx.x * blockDim.x + threadIdx.x;
			unsigned int y = blockIdx.y * blockDim.y + threadIdx.y;

			S buf[KERNEL_SIZE];

			if(x < downWidth && y < downHeight) {

				float u0 = (2.f * x) - HALF_KERNEL;
				float v0 = (2.f * y) - HALF_KERNEL;

				texref<S> tex;
				for(int i = 0; i < KERNEL_SIZE; i++) {
					S tmp;
					tmp = plus4(                   tex(u0    , v0 + i) , tex(u0 + 4, v0 + i));
					tmp = plus4(tmp, mul4(4, plus4(tex(u0 + 1, v0 + i) , tex(u0 + 3, v0 + i))));
					tmp = plus4(tmp, mul4(6,       tex(u0 + 2, v0 + 2)));
					buf[i] = tmp;
				}

				downLevel[y * downLevelPitch + x + 0*downLevelPitch*downHeight] = (buf[0].x + buf[4].x + 4*(buf[1].x + buf[3].x) + 6 * buf[2].x) * NORM_FACTOR;
				downLevel[y * downLevelPitch + x + 1*downLevelPitch*downHeight] = (buf[0].y + buf[4].y + 4*(buf[1].y + buf[3].y) + 6 * buf[2].y) * NORM_FACTOR;
				downLevel[y * downLevelPitch + x + 2*downLevelPitch*downHeight] = (buf[0].z + buf[4].z + 4*(buf[1].z + buf[3].z) + 6 * buf[2].z) * NORM_FACTOR;
			}
		}
	//                         
	// Gaussian 5 x 5 kernel = [1, 4, 6, 4, 1]/16
	// inspired by http://sourceforge.net/projects/openvidia/files/CUDA%20Bayesian%20Optical%20Flow/
	// with bugfix...
	//
	template<class T>
	__global__
		void
		gaussian_pyramid_downsample_kernel(T* downLevel,
				size_t downLevelPitch,
				unsigned int downWidth, unsigned int downHeight)
		{
			// calculate normalized texture coordinates
			unsigned int x = blockIdx.x * blockDim.x + threadIdx.x;
			unsigned int y = blockIdx.y * blockDim.y + threadIdx.y;

			if(x < downWidth && y < downHeight) {
				float buf[KERNEL_SIZE];

				float u0 = (2.f * x) - HALF_KERNEL;
				float v0 = (2.f * y) - HALF_KERNEL;

				texref<T> tex;
				for(int i = 0; i < KERNEL_SIZE; i++) {
					buf[i] = 
						(    tex(u0    , v0 + i) + tex(u0 + 4, v0 + i)) + 
						4 * (tex(u0 + 1, v0 + i) + tex(u0 + 3, v0 + i)) +
						6 *  tex(u0 + 2, v0 + 2);
				}

				downLevel[y * downLevelPitch + x] = (buf[0] + buf[4] + 4*(buf[1] + buf[3]) + 6 * buf[2]) * NORM_FACTOR;
			}
		}
	template<class T>
	__global__
		void
		gaussian_pyramid_upsample_kernel(T* upLevel,
				size_t upLevelPitch,
				unsigned int upWidth, unsigned int upHeight)
		{
			// calculate normalized texture coordinates
			unsigned int x = blockIdx.x * blockDim.x + threadIdx.x;
			unsigned int y = blockIdx.y * blockDim.y + threadIdx.y;

			if(x < upWidth && y < upHeight) {
				float u0 = (x/2.f);
				float v0 = (y/2.f);

				texref<T> tex;
				upLevel[y * upLevelPitch + x] = tex(u0,v0);
			}
		}


	template<class T> struct single_to_4{};
	template<>        struct single_to_4<float>        {typedef float4 type;};
	template<>        struct single_to_4<unsigned char>{typedef uchar4 type;};
	template<class V,class S, class I>
		void gaussian_pyramid_downsample(
				dense_matrix<V,row_major,S,I>& dst,
				const cuda_array<V,S,I>& src,
				const unsigned int interleaved_channels){


			typedef typename single_to_4<V>::type V4;
			cudaChannelFormatDesc channelDesc = cudaCreateChannelDesc<V>();
			cudaChannelFormatDesc channelDesc4 = cudaCreateChannelDesc<V4>();

			typedef typename texref<V>::type textype;
			typedef typename texref<V4>::type textype4;

			textype& tex = texref<V>::get();
			tex.normalized = false;
			tex.filterMode = cudaFilterModePoint;
			tex.addressMode[0] = cudaAddressModeClamp;
			tex.addressMode[1] = cudaAddressModeClamp;
			textype4& tex4 = texref<V4>::get();
			tex4.normalized = false;
			tex4.filterMode = cudaFilterModeLinear;
			tex4.addressMode[0] = cudaAddressModeClamp;
			tex4.addressMode[1] = cudaAddressModeClamp;

			dim3 grid,threads;
			switch(interleaved_channels){
				case 1: // deals with a single channel
					grid = dim3 (iDivUp(dst.w(), CB_TILE_W), iDivUp(dst.h(), CB_TILE_H));
					threads = dim3 (CB_TILE_W, CB_TILE_H);
					cuvAssert(dst.w() < src.w());
					cuvAssert(dst.h() < src.h());
					cudaBindTextureToArray(tex, src.ptr(), channelDesc);
					checkCudaError("cudaBindTextureToArray");
					gaussian_pyramid_downsample_kernel<<<grid,threads>>>(dst.ptr(),
							dst.w(),
							dst.w(),
							dst.h());
					cuvSafeCall(cudaThreadSynchronize());
					cudaUnbindTexture(tex);
					checkCudaError("cudaUnbindTexture");
					break;
				case 4: // deals with 4 interleaved channels (and writes to 3(!))
					cuvAssert(dst.w()   < src.w());
					cuvAssert(dst.h() / 3 < src.h()); 
					cuvAssert(dst.h() % 3 == 0); // three channels in destination (non-interleaved)
					cuvAssert(src.dim()==4);
					grid    = dim3(iDivUp(dst.w(), CB_TILE_W), iDivUp(dst.h()/3, CB_TILE_H));
					threads = dim3(CB_TILE_W, CB_TILE_H);
					cudaBindTextureToArray(tex4, src.ptr(), channelDesc4);
					checkCudaError("cudaBindTextureToArray");
					gaussian_pyramid_downsample_kernel4val<V4,V><<<grid,threads>>>(
							dst.ptr(),
							dst.w(),
							dst.w(),
							dst.h()/3);
					cuvSafeCall(cudaThreadSynchronize());
					cudaUnbindTexture(tex4);
					checkCudaError("cudaUnbindTexture");
					break;
				default:
					cuvAssert(false);
			}
			cuvSafeCall(cudaThreadSynchronize());

		}

	// Upsampling with hardware linear interpolation
	template<class V,class S, class I>
		void gaussian_pyramid_upsample(
				dense_matrix<V,row_major,S,I>& dst,
				const cuda_array<V,S,I>& src){
			cuvAssert(dst.w() > src.w());
			cuvAssert(dst.h() > src.h());

			dim3 grid(iDivUp(dst.w(), CB_TILE_W), iDivUp(dst.h(), CB_TILE_H));
			dim3 threads(CB_TILE_W, CB_TILE_H);

			typedef typename texref<V>::type textype;
			textype& tex = texref<V>::get();
			cudaChannelFormatDesc channelDesc = cudaCreateChannelDesc<V>();
			tex.normalized = false;
			tex.filterMode = cudaFilterModeLinear;
			tex.addressMode[0] = cudaAddressModeClamp;
			tex.addressMode[1] = cudaAddressModeClamp;
			cudaBindTextureToArray(tex, src.ptr(), channelDesc);
			checkCudaError("cudaBindTextureToArray");

			gaussian_pyramid_upsample_kernel<<<grid,threads>>>(dst.ptr(),
					dst.w(),
					dst.w(),
					dst.h());
			cuvSafeCall(cudaThreadSynchronize());

			cudaUnbindTexture(tex);
			checkCudaError("cudaUnbindTexture");
		}


	template<class TDest, class T>
	__global__
		void
		get_pixel_classes_kernel(TDest* dst,
				size_t dstPitch, unsigned int dstWidth, unsigned int dstHeight,
				T* src_orig,
				float scale_fact)
		{
			// calculate normalized texture coordinates
			unsigned int x = blockIdx.x * blockDim.x + threadIdx.x;
			unsigned int y = blockIdx.y * blockDim.y + threadIdx.y;
			texref<T> tex;

			const float N = 1.f;
			if(x < dstWidth && y < dstHeight) {
				T orig = src_orig[y*dstPitch + x];
				float u0 = (x/scale_fact);
				float v0 = (y/scale_fact);

				T min_val = tex(u0-N,v0-N);
				unsigned char arg_min = 0;
				T val = tex(u0+N,v0-N);

				dst[y * dstPitch + x] = (TDest) arg_min;
			}
		}


	// determine a number out of [0,3] for every pixel which should vary
	// smoothly and according to detail level in the image
	template<class VDest, class V, class S, class I>
		void get_pixel_classes(
			dense_matrix<VDest,row_major,S,I>& dst,
			const dense_matrix<V,row_major,S,I>& src_orig,
			const cuda_array<V,S,I>&             src_smooth,
			float scale_fact
		){
			cuvAssert(dst.w() == src_orig.w());
			cuvAssert(dst.h() == src_orig.h());

			dim3 grid(iDivUp(dst.w(), CB_TILE_W), iDivUp(dst.h(), CB_TILE_H));
			dim3 threads(CB_TILE_W, CB_TILE_H);

			typedef typename texref<V>::type textype;
			textype& tex = texref<V>::get();
			cudaChannelFormatDesc channelDesc = cudaCreateChannelDesc<V>();
			tex.normalized = false;
			tex.filterMode = cudaFilterModeLinear;
			tex.addressMode[0] = cudaAddressModeClamp;
			tex.addressMode[1] = cudaAddressModeClamp;
			cudaBindTextureToArray(tex, src_smooth.ptr(), channelDesc);
			checkCudaError("cudaBindTextureToArray");

			get_pixel_classes_kernel<<<grid,threads>>>(dst.ptr(),
					dst.w(), dst.w(), dst.h(),
					src_orig.ptr(),
					scale_fact
					);
			cuvSafeCall(cudaThreadSynchronize());

			cudaUnbindTexture(tex);
			checkCudaError("cudaUnbindTexture");
		}

	// explicit instantiation
	template void gaussian_pyramid_downsample(
			dense_matrix<float,row_major,dev_memory_space,unsigned int>& dst,
			const cuda_array<float,dev_memory_space,unsigned int>& src,
			const unsigned int);
	template void gaussian_pyramid_downsample(
			dense_matrix<unsigned char,row_major,dev_memory_space,unsigned int>& dst,
			const cuda_array<unsigned char,dev_memory_space,unsigned int>& src,
			const unsigned int);
	template void gaussian_pyramid_upsample(
			dense_matrix<float,row_major,dev_memory_space,unsigned int>& dst,
			const cuda_array<float,dev_memory_space,unsigned int>& src);
	template void gaussian_pyramid_upsample(
			dense_matrix<unsigned char,row_major,dev_memory_space,unsigned int>& dst,
			const cuda_array<unsigned char,dev_memory_space,unsigned int>& src);
}
