//*LB*
// Copyright (c) 2010, University of Bonn, Institute for Computer Science VI
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
//  * Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//  * Neither the name of the University of Bonn 
//    nor the names of its contributors may be used to endorse or promote
//    products derived from this software without specific prior written
//    permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//*LE*



#include <cuv/basics/dia_matrix.hpp>
#include <cuv/convert/convert.hpp>

namespace cuv{

    namespace convert_impl{
        /*
         * Vector Conversion
         */


        // host  --> dev 
        template<class __value_type>
            static void
            convert(
                    tensor <__value_type, dev_memory_space>& dst, 
                    const
                    tensor<__value_type, host_memory_space>& src){
                if(        dst.size() != src.size()){
                    tensor<__value_type,dev_memory_space> d(src.size());
                    dst = d;
                }
                cuvSafeCall(cudaMemcpy(dst.ptr(),src.ptr(),dst.memsize(),cudaMemcpyHostToDevice));
            }

        // dev  --> host  
        template<class __value_type>
            static void
            convert(
                    tensor<__value_type, host_memory_space>& dst, 
                    const
                    tensor<__value_type, dev_memory_space>& src){
                if( dst.size() != src.size()){
                    tensor<__value_type, host_memory_space> h(src.size());
                    dst = h;
                }
                cuvSafeCall(cudaMemcpy(dst.ptr(),src.ptr(),dst.memsize(),cudaMemcpyDeviceToHost));
            }

        // host  --> host
        template<class __value_type>
            static void
            convert(
                    tensor<__value_type, host_memory_space>& dst,
                    const
                    tensor<__value_type, host_memory_space>& src){
                if( dst.size() != src.size()){
                    tensor<__value_type, host_memory_space> h(src.size());
                    dst = h;
                }
                memcpy(dst.ptr(),src.ptr(),dst.memsize());
            }

        /*
         * Matrix Conversion
         */

        // host (row-major) --> dev (col-major) 
        template<class __value_type, class __index_type>
            static void
            convert(        dense_matrix <__value_type, dev_memory_space, column_major, __index_type>& dst, 
                    const dense_matrix<__value_type, host_memory_space, row_major, __index_type>& src){
                if(        dst.h() != src.w()
                        || dst.w() != src.h()){

                    dense_matrix<__value_type, dev_memory_space, column_major, __index_type> d(src.w(),src.h());
                    dst = d;
                }
                cuvAssert(dst.ptr())
                    cuvAssert(src.ptr())
                    convert(dst, src);
            }

        // dev (col-major) --> host (row-major) 
        template<class __value_type, class __index_type>
            static void
            convert(        dense_matrix<__value_type, host_memory_space, row_major, __index_type>& dst, 
                    const dense_matrix<__value_type, dev_memory_space, column_major, __index_type>& src){
                if(        dst.h() != src.w()
                        || dst.w() != src.h()){
                    dense_matrix<__value_type, host_memory_space, row_major, __index_type> h(src.w(),src.h());
                    dst = h;
                }
                cuvAssert(dst.ptr())
                    cuvAssert(src.ptr())
                    convert(dst, src);
            }

        // host (col-major) --> dev (row-major) 
        template<class __value_type, class __index_type>
            static void
            convert(        dense_matrix <__value_type, dev_memory_space, row_major, __index_type>& dst, 
                    const dense_matrix<__value_type, host_memory_space, column_major, __index_type>& src){
                if(        dst.h() != src.w()
                        || dst.w() != src.h()){

                    dense_matrix<__value_type, dev_memory_space, row_major, __index_type> d(src.w(),src.h());
                    dst = d;
                }
                cuvAssert(dst.ptr())
                    cuvAssert(src.ptr())
                    convert(dst, src);
            }

        // dev (row-major) --> host (col-major) 
        template<class __value_type, class __index_type>
            static void
            convert(        dense_matrix<__value_type, host_memory_space, column_major, __index_type>& dst, 
                    const dense_matrix<__value_type, dev_memory_space, row_major, __index_type>& src){
                if(        dst.h() != src.w()
                        || dst.w() != src.h()){
                    dense_matrix<__value_type, host_memory_space, column_major, __index_type> h(src.w(),src.h());
                    dst = h;
                }
                cuvAssert(dst.ptr())
                    cuvAssert(src.ptr())
                    convert(dst, src);
            }

        /*
         * Simple copying
         *
         */

        // host (col-major) --> host (col-major)
        template<class __value_type, class __index_type>
            static void
            convert(        dense_matrix<__value_type, host_memory_space, column_major, __index_type>& dst,
                    const   dense_matrix<__value_type, host_memory_space, column_major, __index_type>& src){
                if(        dst.h() != src.h()
                        || dst.w() != src.w()){
                    dense_matrix<__value_type, host_memory_space, column_major, __index_type> h(src.h(),src.w());
                    dst = h;
                }
                cuvAssert(dst.ptr())
                    cuvAssert(src.ptr())
                    convert(dst, src);
            }

        // host (row-major) --> host (row-major)
        template<class __value_type, class __index_type>
            static void
            convert(        dense_matrix<__value_type, host_memory_space, row_major, __index_type>& dst,
                    const   dense_matrix<__value_type, host_memory_space, row_major, __index_type>& src){
                if(        dst.h() != src.h()
                        || dst.w() != src.w()){
                    dense_matrix<__value_type, host_memory_space, row_major, __index_type> h(src.h(),src.w());
                    dst = h;
                }
                cuvAssert(dst.ptr())
                    cuvAssert(src.ptr())
                    convert(dst, src);
            }

        // dev (col-major) --> host (col-major) 
        template<class __value_type, class __index_type>
            static void
            convert(        dense_matrix<__value_type, host_memory_space, column_major, __index_type>& dst, 
                    const    dense_matrix<__value_type, dev_memory_space, column_major, __index_type>& src){
                if(        dst.h() != src.h()
                        || dst.w() != src.w()){
                    dense_matrix<__value_type, host_memory_space, column_major, __index_type> h(src.h(),src.w());
                    dst = h;
                }
                cuvAssert(dst.ptr())
                    cuvAssert(src.ptr())
                    convert(dst, src);
            }

        // dev (col-major) --> host (col-major) 
        template<class __value_type, class __index_type>
            static void
            convert(         dense_matrix<__value_type, dev_memory_space, column_major, __index_type>& dst, 
                    const   dense_matrix<__value_type, host_memory_space, column_major, __index_type>& src){
                if(        dst.h() != src.h()
                        || dst.w() != src.w()){
                    dense_matrix<__value_type, dev_memory_space, column_major, __index_type> h(src.h(),src.w());
                    dst = h;
                }
                cuvAssert(dst.ptr())
                    cuvAssert(src.ptr())
                    convert(dst, src);
            }

        // dev (row-major) --> host (row-major) 
        template<class __value_type, class __index_type>
            static void
            convert(        dense_matrix<__value_type, host_memory_space, row_major, __index_type>& dst, 
                    const dense_matrix<__value_type, dev_memory_space, row_major, __index_type>& src){
                if(        dst.h() != src.h()
                        || dst.w() != src.w()){
                    dense_matrix<__value_type, host_memory_space, row_major, __index_type> h(src.h(),src.w());
                    dst = h;
                }
                cuvAssert(dst.vec_ptr())
                    cuvAssert(src.vec_ptr())
                    convert(dst, src);
            }

        // host (row-major) --> dev (row-major) 
        template<class __value_type, class __index_type>
            static void
            convert(         dense_matrix<__value_type, dev_memory_space, row_major, __index_type>& dst, 
                    const dense_matrix<__value_type, host_memory_space, row_major, __index_type>& src){
                if(        dst.h() != src.h()
                        || dst.w() != src.w()){
                    dense_matrix<__value_type, dev_memory_space, row_major, __index_type> h(src.h(),src.w());
                    dst = h;
                }
                cuvAssert(dst.vec_ptr())
                    cuvAssert(src.vec_ptr())
                    convert(dst, src);
            }

        /*
         * Host Dia -> Host Dense
         */
        template<class __value_type, class __mem_layout_type, class __index_type>
            static void
            convert(      dense_matrix<__value_type, host_memory_space, __mem_layout_type, __index_type>& dst, 
                    const dia_matrix<__value_type, host_memory_space,  __index_type>& src){
                if(        dst.h() != src.h()
                        || dst.w() != src.w()
                  ){
                    dense_matrix<__value_type,host_memory_space,  __mem_layout_type, __index_type> d(src.h(),src.w());
                    dst = d;
                }
                fill(dst,0);
                const
                    tensor<int, host_memory_space>& off = src.get_offsets();
                using namespace std;
                const int rf = src.row_fact();
                for(unsigned int oi=0; oi < off.size(); oi++){
                    int o = off[oi];
                    __index_type j = 1 *max((int)0, o);
                    __index_type i = rf*max((int)0,-o);
                    for(;i<src.h() && j<src.w(); j++){
                        for(int k=0;k<rf;k++,i++)
                            dst.set(i,j, src(i,j));
                    }
                }
            }

        /*
         * Host Dia -> Dev Dia
         */
        template<class __value_type, class __index_type>
            static void
            convert(      dia_matrix <__value_type, dev_memory_space, __index_type>& dst, 
                    const dia_matrix<__value_type, host_memory_space, __index_type>& src){
                if(        dst.h() != src.h()
                        || dst.w() != src.w()
                        || dst.row_fact() != src.row_fact()
                        || !dst.vec_ptr()
                  ){
                    dst.dealloc();
                    dst = dia_matrix<__value_type,dev_memory_space,__index_type>(src.h(),src.w(),src.num_dia(),src.stride(),src.row_fact());
                }
                cuvAssert(dst.vec_ptr())
                    cuvAssert(src.vec_ptr())
                    cuvAssert(dst.get_offsets().ptr());
                cuvAssert(dst.vec().ptr());
                cuv::convert(dst.get_offsets(), src.get_offsets());
                cuv::convert(dst, src);
                dst.post_update_offsets();
            }

        /*
         * Dev Dia -> Host Dia
         */
        template<class __value_type, class __index_type>
            static void
            convert(      dia_matrix <__value_type,host_memory_space, __index_type>& dst, 
                    const dia_matrix<__value_type,dev_memory_space, __index_type>& src){
                if(        dst.h() != src.h()
                        || dst.w() != src.w()
                        || dst.row_fact() != src.row_fact()
                        || !dst.vec_ptr()
                  ){
                    dst.dealloc();
                    dst = dia_matrix<__value_type,host_memory_space, __index_type>(src.h(),src.w(),src.num_dia(),src.stride(),src.row_fact());
                }
                cuvAssert(dst.get_offsets().ptr());
                cuvAssert(dst.vec().ptr());
                cuv::convert(dst.get_offsets(), src.get_offsets());
                cuv::convert(dst, src);
                dst.post_update_offsets();
            }
    }
    template<class Dst, class Src>
        void convert(Dst& dst, const Src& src)
        {
            /*convert_impl::convert<typename Dst::value_type, typename Dst::index_type>(dst,src); // hmm the compiler should deduce template args, but it fails to do so.*/
            convert_impl::convert<typename Dst::value_type>(dst,src); // hmm the compiler should deduce template args, but it fails to do so.
        };

#define CONV_VEC(X) \
    template void convert<tensor<X, host_memory_space>, tensor<X, host_memory_space> > \
    ( tensor<X, host_memory_space>&, const tensor<X, host_memory_space>&); \
    template void convert<tensor<X, dev_memory_space>, tensor<X, host_memory_space> > \
    ( tensor<X, dev_memory_space>&, const tensor<X, host_memory_space>&); \
    template void convert<tensor<X, host_memory_space>, tensor<X, dev_memory_space> > \
    ( tensor<X, host_memory_space>&, const tensor<X, dev_memory_space>&);

#define CONV_INST(X,Y,Z) \
    template void convert<dense_matrix<X,dev_memory_space,Y>,          dense_matrix<X,host_memory_space,Z> > \
    (                 dense_matrix<X,dev_memory_space,Y>&,   const dense_matrix<X,host_memory_space,Z>&); \
    template void convert<dense_matrix<X,host_memory_space,Y>,         dense_matrix<X,dev_memory_space,Z> > \
    (                 dense_matrix<X,host_memory_space,Y>&,  const dense_matrix<X,dev_memory_space,Z>&);

#define CONV_SIMPLE_INST(X,Y) \
    template void convert<dense_matrix<X,host_memory_space,Y>,         dense_matrix<X,host_memory_space,Y> > \
    (                 dense_matrix<X,host_memory_space,Y>&,  const dense_matrix<X,host_memory_space,Y>&);

    CONV_INST(float,column_major,column_major);
    CONV_INST(float,column_major,row_major);
    CONV_INST(float,row_major,   column_major);
    CONV_INST(float,row_major,   row_major);

    CONV_INST(unsigned char,column_major,column_major);
    CONV_INST(unsigned char,column_major,row_major);
    CONV_INST(unsigned char,row_major,   column_major);
    CONV_INST(unsigned char,row_major,   row_major);

    CONV_INST(signed char,column_major,column_major);
    CONV_INST(signed char,column_major,row_major);
    CONV_INST(signed char,row_major,   column_major);
    CONV_INST(signed char,row_major,   row_major);

    CONV_INST(int,column_major,column_major);
    CONV_INST(int,column_major,row_major);
    CONV_INST(int,row_major,   column_major);
    CONV_INST(int,row_major,   row_major);

    CONV_INST(unsigned int,column_major,column_major);
    CONV_INST(unsigned int,column_major,row_major);
    CONV_INST(unsigned int,row_major,   column_major);
    CONV_INST(unsigned int,row_major,   row_major);

    CONV_SIMPLE_INST(int,column_major);
    CONV_SIMPLE_INST(float,column_major);
    CONV_SIMPLE_INST(signed char,column_major);
    CONV_SIMPLE_INST(unsigned char,column_major);
    CONV_SIMPLE_INST(unsigned int,column_major);

    CONV_SIMPLE_INST(int,row_major);
    CONV_SIMPLE_INST(float,row_major);
    CONV_SIMPLE_INST(signed char,row_major);
    CONV_SIMPLE_INST(unsigned char,row_major);
    CONV_SIMPLE_INST(unsigned int,row_major);

    CONV_VEC(int);
    CONV_VEC(float);
    CONV_VEC(signed char);
    CONV_VEC(unsigned char);
    CONV_VEC(unsigned int);

#define DIA_DENSE_CONV(X,Y,Z) \
    template <>                           \
    void convert(dense_matrix<X,host_memory_space,Y,Z>& dst, const dia_matrix<X,host_memory_space,Z>& src)     \
    {                                                                                \
        typedef dense_matrix<X,host_memory_space,Y,Z> Dst;                                        \
        convert_impl::convert<typename Dst::value_type, typename Dst::memory_layout, typename Dst::index_type>(dst,src);  \
    };   
#define DIA_HOST_DEV_CONV(X,Z) \
    template <>                           \
    void convert(dia_matrix<X,dev_memory_space,Z>& dst, const dia_matrix<X,host_memory_space,Z>& src)     \
    {                                                                                \
        typedef dia_matrix<X,dev_memory_space,Z> Dst;                                        \
        convert_impl::convert<typename Dst::value_type, typename Dst::index_type>(dst,src);  \
    };                                \
    template <>                           \
    void convert(dia_matrix<X,host_memory_space,Z>& dst, const dia_matrix<X,dev_memory_space,Z>& src)     \
    {                                                                                \
        typedef dia_matrix<X,host_memory_space,Z> Dst;                                        \
        convert_impl::convert<typename Dst::value_type, typename Dst::index_type>(dst,src);  \
    };                                

    DIA_DENSE_CONV(float,column_major,unsigned int)
        DIA_DENSE_CONV(float,row_major,unsigned int)
        DIA_HOST_DEV_CONV(float,unsigned int)


} // namespace cuv

