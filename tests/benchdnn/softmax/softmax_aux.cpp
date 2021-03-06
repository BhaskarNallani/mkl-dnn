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

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "mkldnn.h"

#include "mkldnn_common.hpp"
#include "mkldnn_debug.hpp"

#include "softmax/softmax.hpp"

namespace softmax {

dims_t str2dims(const char *str) {
    dims_t dims;
    do {
        int len;
        int64_t dim;
        int scan = sscanf(str, IFMT "%n", &dim, &len);
        SAFE_V(scan == 1 ? OK : FAIL);
        dims.push_back(dim);
        str += len;
        SAFE_V(*str == 'x' || *str == '\0' ? OK : FAIL);
    } while (*str++ != '\0');
    return dims;
}

#define DPRINT(...) do { \
    int l = snprintf(buffer, rem_len, __VA_ARGS__); \
    buffer += l; rem_len -= l; \
} while(0)

void dims2str(const dims_t &dims, char *buffer) {
    int rem_len = max_dims_len;
    for (size_t d = 0; d < dims.size() - 1; ++d)
        DPRINT(IFMT "x", dims[d]);
    DPRINT(IFMT, dims[dims.size() - 1]);
}

#undef DPRINT

void prb2str(const prb_t *p, char *buffer, bool canonical) {
    char dim_str[32] = {0};
    char dir_str[32] = {0};
    char dt_str[32] = {0};
    char axis_str[32] = {0};
    char tag_str[32] = {0};

    dims2str(p->dims, dim_str);

    snprintf(dir_str, sizeof(dir_str), "--dir=%s ", dir2str(p->dir));
    snprintf(dt_str, sizeof(dt_str), "--dt=%s ", dt2str(p->dt));
    snprintf(axis_str, sizeof(axis_str), "--axis=%d ", p->axis);
    snprintf(tag_str, sizeof(tag_str), "--tag=%s ", tag2str(p->tag));
    snprintf(buffer, max_prb_len, "%s%s%s%s%s",
            p->dir == FWD_D ? "" : dir_str,
            p->dt == mkldnn_f32 ? "" : dt_str,
            p->tag == mkldnn_nchw ? "" : tag_str,
            p->axis == 1 ? "" : axis_str,
            dim_str);
}

}
