/*******************************************************************************
* Copyright 2019 Intel Corporation
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*******************************************************************************/

#include "ocl/ocl_types.h"

#if INNER_PRODUCT_FWD == 1
__kernel void ref_inner_product_fwd_kernel(__global DATA_T *src,
        __global DATA_T *wht, __global DATA_T *bias, __global DATA_T *dst,
        DATA_T relu_negative_slope) {

    const int mb = get_global_id(0) / OC;
    const int oc = get_global_id(0) % OC;
#    if WITH_BIAS == 1
    DATA_T a = bias[oc];
#    else
    DATA_T a = 0;
#    endif
#    if HAS_SPATIAL == 1
    for (int ic = 0; ic < IC; ++ic)
        for (int kd = 0; kd < KD; ++kd)
            for (int kh = 0; kh < KH; ++kh)
                for (int kw = 0; kw < KW; ++kw) {
                    const uint src_off = SRC_OFF(mb, ic, kd, kh, kw);
                    const uint wht_off = WHT_OFF(oc, ic, kd, kh, kw);
#    else
    for (int ic = 0; ic < IC_TOTAL; ++ic) {
        const uint src_off = mb * IC_TOTAL + ic;
        const uint wht_off = oc * IC_TOTAL + ic;
#    endif
                    a += src[src_off] * wht[wht_off];
                }
#    if WITH_RELU == 1
    dst[mb * OC + oc] = (a < 0.0f) ? relu_negative_slope * a : a;
#    else
    dst[mb * OC + oc] = a;
#    endif
}
#endif

#if INNER_PRODUCT_BWD_DATA == 1
__kernel void ref_inner_product_bwd_data_kernel(__global DATA_T *diff_src,
        __global DATA_T *wht, __global DATA_T *diff_dst) {

    const int mb = get_global_id(0) / IC_TOTAL;
    const int ic = get_global_id(0) % IC_TOTAL;
    float ds = 0.0f;
    for (int oc = 0; oc < OC; ++oc) {
        ds += diff_dst[mb * OC + oc] * wht[oc * IC_TOTAL + ic];
    }
    diff_src[mb * IC_TOTAL + ic] = ds;
}
#endif

#if INNER_PRODUCT_BWD_WEIGHTS == 1
__kernel void ref_inner_product_bwd_weights_kernel(__global DATA_T *src,
        __global DATA_T *diff_wht, __global DATA_T *diff_bias,
        __global DATA_T *diff_dst) {

    const int oc = get_global_id(0) / IC_TOTAL;
    const int ic = get_global_id(0) % IC_TOTAL;

    float ds = 0.0f;
    for (int mb = 0; mb < MB; ++mb) {
        ds += diff_dst[mb * OC + oc] * src[mb * IC_TOTAL + ic];
    }
    diff_wht[oc * IC_TOTAL + ic] = ds;
#    if WITH_BIAS == 1
    if (ic == 0) {
        diff_bias[oc] = 0.0f;
        for (int mb = 0; mb < MB; ++mb) {
            diff_bias[oc] += diff_dst[mb * OC + oc];
        }
    }
#    endif
}
#endif
