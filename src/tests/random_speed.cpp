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





#define BOOST_TEST_MODULE example
#include <boost/test/included/unit_test.hpp>
#include <boost/test/floating_point_comparison.hpp>


#include <cuv/tools/timing.hpp>
#include <cuv/tools/cuv_general.hpp>
#include <cuv/basics/tensor.hpp>
#include <cuv/tensor_ops/tensor_ops.hpp>
#include <cuv/random/random.hpp>

#define MEASURE_TIME(MSG, OPERATION, ITERS)     \
	float MSG;                                  \
	if(1){                                      \
		Timing tim;                             \
		for(int i=0;i<ITERS;i++){               \
			printf(".");fflush(stdout);         \
			OPERATION ;                         \
                        safeThreadSync();               \
		}                                       \
		tim.update(ITERS);                      \
		printf("%s [%s] took %4.4f us/pass\n", #MSG, #OPERATION, 1000000.0f*tim.perf()); \
		MSG = 1000000.0f*tim.perf();            \
	}

using namespace cuv;

struct MyConfig {
	static const int dev = CUDA_TEST_DEVICE;
	MyConfig()   { 
		printf("Testing on device=%d\n",dev);
		initCUDA(dev); 
	}
	~MyConfig()  { exitCUDA();  }
};

BOOST_GLOBAL_FIXTURE( MyConfig );

struct Fix{
	tensor<float,dev_memory_space> v_dev;
	tensor<float,host_memory_space> v_host;
	static const int n;
	Fix()
		:v_dev(n),v_host(n) // needs large sample number.
	{
		initialize_mersenne_twister_seeds();
	}
	~Fix(){
	}
};
const int Fix::n = 150*150*96;


BOOST_FIXTURE_TEST_SUITE( s, Fix )


BOOST_AUTO_TEST_CASE( random_uniform )
{
	MEASURE_TIME(dev, fill_rnd_uniform(v_dev), 10);
	MEASURE_TIME(host, fill_rnd_uniform(v_host), 10);
	printf("Speedup: %3.4f\n", host/dev);
	BOOST_CHECK_LT(dev,host);
}
BOOST_AUTO_TEST_CASE( random_normal )
{
	fill(v_dev,0);
	fill(v_host,0);	
	MEASURE_TIME(dev,add_rnd_normal(v_dev),10);
	MEASURE_TIME(host,add_rnd_normal(v_host),10);
	printf("Speedup: %3.4f\n", host/dev);
	BOOST_CHECK_LT(dev,host);
}
BOOST_AUTO_TEST_CASE( binarize )
{
	fill_rnd_uniform(v_dev);
	fill_rnd_uniform(v_host);
	MEASURE_TIME(dev,rnd_binarize(v_dev),10);
	MEASURE_TIME(host,rnd_binarize(v_host),10);
	printf("Speedup: %3.4f\n", host/dev);
	BOOST_CHECK_LT(dev,host);
}




BOOST_AUTO_TEST_SUITE_END()
