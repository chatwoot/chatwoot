// Copyright (c) 2011, 2022 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#include "oj.h"

typedef struct _encoder {
    int              indent;         // indention for dump, default 2
    char             circular;       // YesNo
    char             escape_mode;    // Escape_Mode
    char             mode;           // Mode
    char             time_format;    // TimeFormat
    char             bigdec_as_num;  // YesNo
    char             to_hash;        // YesNo
    char             to_json;        // YesNo
    char             as_json;        // YesNo
    char             raw_json;       // YesNo
    char             trace;          // YesNo
    char             sec_prec_set;   // boolean (0 or 1)
    char             ignore_under;   // YesNo - ignore attrs starting with _ if true in object and custom modes
    int64_t          int_range_min;  // dump numbers below as string
    int64_t          int_range_max;  // dump numbers above as string
    const char*      create_id;      // 0 or string
    size_t           create_id_len;  // length of create_id
    int              sec_prec;       // second precision when dumping time
    char             float_prec;     // float precision, linked to float_fmt
    char             float_fmt[7];   // float format for dumping, if empty use Ruby
    struct _dumpOpts dump_opts;
    struct _rxClass  str_rx;
    VALUE*           ignore;  // Qnil terminated array of classes or NULL
}* Encoder;

/*
    rb_define_module_function(Oj, "encode", encode, -1);
    rb_define_module_function(Oj, "to_file", to_file, -1); // or maybe just write
    rb_define_module_function(Oj, "to_stream", to_stream, -1);
*/

// write(to, obj)
//  if to is a string then open file
//  else if stream then write to stream
//  handle non-blocking

// should each mode have a different encoder or use delegates like the parser?
