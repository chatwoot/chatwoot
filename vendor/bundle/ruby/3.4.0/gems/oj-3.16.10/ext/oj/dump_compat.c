// Copyright (c) 2012, 2017 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#include "code.h"
#include "dump.h"
#include "rails.h"
#include "trace.h"

// Workaround in case INFINITY is not defined in math.h or if the OS is CentOS
#define OJ_INFINITY (1.0 / 0.0)

bool oj_use_hash_alt  = false;
bool oj_use_array_alt = false;

static bool use_struct_alt    = false;
static bool use_exception_alt = false;
static bool use_bignum_alt    = false;

static void raise_json_err(const char *msg, const char *err_classname) {
    rb_raise(oj_get_json_err_class(err_classname), "%s", msg);
}

static void dump_obj_classname(const char *classname, int depth, Out out) {
    int    d2      = depth + 1;
    size_t len     = strlen(classname);
    size_t sep_len = out->opts->dump_opts.before_size + out->opts->dump_opts.after_size + 2;
    size_t size    = d2 * out->indent + 10 + len + out->opts->create_id_len + sep_len;

    assure_size(out, size);
    *out->cur++ = '{';
    fill_indent(out, d2);
    *out->cur++ = '"';
    APPEND_CHARS(out->cur, out->opts->create_id, out->opts->create_id_len);
    *out->cur++ = '"';
    if (0 < out->opts->dump_opts.before_size) {
        APPEND_CHARS(out->cur, out->opts->dump_opts.before_sep, out->opts->dump_opts.before_size);
    }
    *out->cur++ = ':';
    if (0 < out->opts->dump_opts.after_size) {
        APPEND_CHARS(out->cur, out->opts->dump_opts.after_sep, out->opts->dump_opts.after_size);
    }
    *out->cur++ = '"';
    APPEND_CHARS(out->cur, classname, len);
    *out->cur++ = '"';
}

static void dump_values_array(VALUE *values, int depth, Out out) {
    size_t size;
    int    d2 = depth + 1;

    assure_size(out, d2 * out->indent + 3);
    *out->cur++ = '[';
    if (Qundef == *values) {
        *out->cur++ = ']';
    } else {
        if (out->opts->dump_opts.use) {
            size = d2 * out->opts->dump_opts.indent_size + out->opts->dump_opts.array_size + 2;
            size += out->opts->dump_opts.array_size;
            size += out->opts->dump_opts.indent_size;
        } else {
            size = d2 * out->indent + 3;
        }
        for (; Qundef != *values; values++) {
            assure_size(out, size);
            if (out->opts->dump_opts.use) {
                if (0 < out->opts->dump_opts.array_size) {
                    APPEND_CHARS(out->cur, out->opts->dump_opts.array_nl, out->opts->dump_opts.array_size);
                }
                if (0 < out->opts->dump_opts.indent_size) {
                    int i;

                    for (i = d2; 0 < i; i--) {
                        APPEND_CHARS(out->cur, out->opts->dump_opts.indent_str, out->opts->dump_opts.indent_size);
                    }
                }
            } else {
                fill_indent(out, d2);
            }
            oj_dump_compat_val(*values, d2, out, true);
            if (Qundef != *(values + 1)) {
                *out->cur++ = ',';
            }
        }
        assure_size(out, size);
        if (out->opts->dump_opts.use) {
            if (0 < out->opts->dump_opts.array_size) {
                APPEND_CHARS(out->cur, out->opts->dump_opts.array_nl, out->opts->dump_opts.array_size);
            }
            if (0 < out->opts->dump_opts.indent_size) {
                int i;

                for (i = depth; 0 < i; i--) {
                    APPEND_CHARS(out->cur, out->opts->dump_opts.indent_str, out->opts->dump_opts.indent_size);
                }
            }
        } else {
            fill_indent(out, depth);
        }
        *out->cur++ = ']';
    }
}

static void dump_to_json(VALUE obj, Out out) {
    volatile VALUE rs;
    const char    *s;
    int            len;

    TRACE(out->opts->trace, "to_json", obj, 0, TraceRubyIn);
    if (0 == rb_obj_method_arity(obj, oj_to_json_id)) {
        rs = rb_funcall(obj, oj_to_json_id, 0);
    } else {
        rs = rb_funcall2(obj, oj_to_json_id, out->argc, out->argv);
    }
    TRACE(out->opts->trace, "to_json", obj, 0, TraceRubyOut);

    StringValue(rs);
    s   = RSTRING_PTR(rs);
    len = (int)RSTRING_LEN(rs);

    assure_size(out, len + 1);
    APPEND_CHARS(out->cur, s, len);
    *out->cur = '\0';
}

static void dump_array(VALUE a, int depth, Out out, bool as_ok) {
    size_t size;
    int    i, cnt;
    int    d2 = depth + 1;
    long   id = oj_check_circular(a, out);

    if (0 > id) {
        raise_json_err("Too deeply nested", "NestingError");
        return;
    }
    if (as_ok && !oj_use_array_alt && rb_obj_class(a) != rb_cArray && rb_respond_to(a, oj_to_json_id)) {
        dump_to_json(a, out);
        return;
    }
    cnt         = (int)RARRAY_LEN(a);
    *out->cur++ = '[';
    assure_size(out, 2);
    if (0 == cnt) {
        *out->cur++ = ']';
    } else {
        if (out->opts->dump_opts.use) {
            size = d2 * out->opts->dump_opts.indent_size + out->opts->dump_opts.array_size + 1;
        } else {
            size = d2 * out->indent + 2;
        }
        assure_size(out, size * cnt);
        cnt--;
        for (i = 0; i <= cnt; i++) {
            if (out->opts->dump_opts.use) {
                if (0 < out->opts->dump_opts.array_size) {
                    APPEND_CHARS(out->cur, out->opts->dump_opts.array_nl, out->opts->dump_opts.array_size);
                }
                if (0 < out->opts->dump_opts.indent_size) {
                    int i;
                    for (i = d2; 0 < i; i--) {
                        APPEND_CHARS(out->cur, out->opts->dump_opts.indent_str, out->opts->dump_opts.indent_size);
                    }
                }
            } else {
                fill_indent(out, d2);
            }
            oj_dump_compat_val(RARRAY_AREF(a, i), d2, out, true);
            if (i < cnt) {
                *out->cur++ = ',';
            }
        }
        if (out->opts->dump_opts.use) {
            size = out->opts->dump_opts.array_size + out->opts->dump_opts.indent_size * depth + 1;
            assure_size(out, size);
            if (0 < out->opts->dump_opts.array_size) {
                APPEND_CHARS(out->cur, out->opts->dump_opts.array_nl, out->opts->dump_opts.array_size);
            }
            if (0 < out->opts->dump_opts.indent_size) {
                int i;

                for (i = depth; 0 < i; i--) {
                    APPEND_CHARS(out->cur, out->opts->dump_opts.indent_str, out->opts->dump_opts.indent_size);
                }
            }
        } else {
            size = depth * out->indent + 1;
            assure_size(out, size);
            fill_indent(out, depth);
        }
        *out->cur++ = ']';
    }
    *out->cur = '\0';
}

static ID _dump_id = 0;

static void bigdecimal_alt(VALUE obj, int depth, Out out) {
    struct _attr attrs[] = {
        {"b", 1, Qnil},
        {NULL, 0, Qnil},
    };

    if (0 == _dump_id) {
        _dump_id = rb_intern("_dump");
    }
    attrs[0].value = rb_funcall(obj, _dump_id, 0);

    oj_code_attrs(obj, attrs, depth, out, true);
}

static ID real_id = 0;
static ID imag_id = 0;

static void complex_alt(VALUE obj, int depth, Out out) {
    struct _attr attrs[] = {
        {"r", 1, Qnil},
        {"i", 1, Qnil},
        {NULL, 0, Qnil},
    };

    if (0 == real_id) {
        real_id = rb_intern("real");
        imag_id = rb_intern("imag");
    }
    attrs[0].value = rb_funcall(obj, real_id, 0);
    attrs[1].value = rb_funcall(obj, imag_id, 0);

    oj_code_attrs(obj, attrs, depth, out, true);
}

static ID year_id  = 0;
static ID month_id = 0;
static ID day_id   = 0;
static ID start_id = 0;

static void date_alt(VALUE obj, int depth, Out out) {
    struct _attr attrs[] = {
        {"y", 1, Qnil},
        {"m", 1, Qnil},
        {"d", 1, Qnil},
        {"sg", 2, Qnil},
        {NULL, 0, Qnil},
    };
    if (0 == year_id) {
        year_id  = rb_intern("year");
        month_id = rb_intern("month");
        day_id   = rb_intern("day");
        start_id = rb_intern("start");
    }
    attrs[0].value = rb_funcall(obj, year_id, 0);
    attrs[1].value = rb_funcall(obj, month_id, 0);
    attrs[2].value = rb_funcall(obj, day_id, 0);
    attrs[3].value = rb_funcall(obj, start_id, 0);

    oj_code_attrs(obj, attrs, depth, out, true);
}

static ID hour_id   = 0;
static ID min_id    = 0;
static ID sec_id    = 0;
static ID offset_id = 0;

static void datetime_alt(VALUE obj, int depth, Out out) {
    struct _attr attrs[] = {
        {"y", 1, Qnil},
        {"m", 1, Qnil},
        {"d", 1, Qnil},
        {"H", 1, Qnil},
        {"M", 1, Qnil},
        {"S", 1, Qnil},
        {"of", 2, Qnil},
        {"sg", 2, Qnil},
        {NULL, 0, Qnil},
    };
    if (0 == hour_id) {
        year_id   = rb_intern("year");
        month_id  = rb_intern("month");
        day_id    = rb_intern("day");
        hour_id   = rb_intern("hour");
        min_id    = rb_intern("min");
        sec_id    = rb_intern("sec");
        offset_id = rb_intern("offset");
        start_id  = rb_intern("start");
    }
    attrs[0].value = rb_funcall(obj, year_id, 0);
    attrs[1].value = rb_funcall(obj, month_id, 0);
    attrs[2].value = rb_funcall(obj, day_id, 0);
    attrs[3].value = rb_funcall(obj, hour_id, 0);
    attrs[4].value = rb_funcall(obj, min_id, 0);
    attrs[5].value = rb_funcall(obj, sec_id, 0);
    attrs[6].value = oj_safe_string_convert(rb_funcall(obj, offset_id, 0));
    attrs[7].value = rb_funcall(obj, start_id, 0);

    oj_code_attrs(obj, attrs, depth, out, true);
}

static ID message_id   = 0;
static ID backtrace_id = 0;

static void exception_alt(VALUE obj, int depth, Out out) {
    int    d3      = depth + 2;
    size_t size    = d3 * out->indent + 2;
    size_t sep_len = out->opts->dump_opts.before_size + out->opts->dump_opts.after_size + 2;

    if (0 == message_id) {
        message_id   = rb_intern("message");
        backtrace_id = rb_intern("backtrace");
    }
    dump_obj_classname(rb_class2name(rb_obj_class(obj)), depth, out);

    assure_size(out, size + sep_len + 6);
    *out->cur++ = ',';
    fill_indent(out, d3);
    APPEND_CHARS(out->cur, "\"m\"", 3);
    if (0 < out->opts->dump_opts.before_size) {
        APPEND_CHARS(out->cur, out->opts->dump_opts.before_sep, out->opts->dump_opts.before_size);
    }
    *out->cur++ = ':';
    if (0 < out->opts->dump_opts.after_size) {
        APPEND_CHARS(out->cur, out->opts->dump_opts.after_sep, out->opts->dump_opts.after_size);
    }
    oj_dump_str(rb_funcall(obj, message_id, 0), 0, out, false);
    assure_size(out, size + sep_len + 6);
    *out->cur++ = ',';
    fill_indent(out, d3);
    APPEND_CHARS(out->cur, "\"b\"", 3);
    if (0 < out->opts->dump_opts.before_size) {
        APPEND_CHARS(out->cur, out->opts->dump_opts.before_sep, out->opts->dump_opts.before_size);
    }
    *out->cur++ = ':';
    if (0 < out->opts->dump_opts.after_size) {
        APPEND_CHARS(out->cur, out->opts->dump_opts.after_sep, out->opts->dump_opts.after_size);
    }
    dump_array(rb_funcall(obj, backtrace_id, 0), depth, out, false);
    fill_indent(out, depth);
    *out->cur++ = '}';
    *out->cur   = '\0';
}

static ID table_id = 0;

static void openstruct_alt(VALUE obj, int depth, Out out) {
    struct _attr attrs[] = {
        {"t", 1, Qnil},
        {NULL, 0, Qnil},
    };
    if (0 == table_id) {
        table_id = rb_intern("table");
    }
    attrs[0].value = rb_funcall(obj, table_id, 0);

    oj_code_attrs(obj, attrs, depth, out, true);
}

static void range_alt(VALUE obj, int depth, Out out) {
    int    d3      = depth + 2;
    size_t size    = d3 * out->indent + 2;
    size_t sep_len = out->opts->dump_opts.before_size + out->opts->dump_opts.after_size + 2;
    VALUE  args[]  = {Qundef, Qundef, Qundef, Qundef};

    dump_obj_classname(rb_class2name(rb_obj_class(obj)), depth, out);

    assure_size(out, size + sep_len + 6);
    *out->cur++ = ',';
    fill_indent(out, d3);
    APPEND_CHARS(out->cur, "\"a\"", 3);
    if (0 < out->opts->dump_opts.before_size) {
        APPEND_CHARS(out->cur, out->opts->dump_opts.before_sep, out->opts->dump_opts.before_size);
    }
    *out->cur++ = ':';
    if (0 < out->opts->dump_opts.after_size) {
        APPEND_CHARS(out->cur, out->opts->dump_opts.after_sep, out->opts->dump_opts.after_size);
    }
    args[0] = rb_funcall(obj, oj_begin_id, 0);
    args[1] = rb_funcall(obj, oj_end_id, 0);
    args[2] = rb_funcall(obj, oj_exclude_end_id, 0);
    dump_values_array(args, depth, out);
    fill_indent(out, depth);
    *out->cur++ = '}';
    *out->cur   = '\0';
}

static ID numerator_id   = 0;
static ID denominator_id = 0;

static void rational_alt(VALUE obj, int depth, Out out) {
    struct _attr attrs[] = {
        {"n", 1, Qnil},
        {"d", 1, Qnil},
        {NULL, 0, Qnil},
    };
    if (0 == numerator_id) {
        numerator_id   = rb_intern("numerator");
        denominator_id = rb_intern("denominator");
    }
    attrs[0].value = rb_funcall(obj, numerator_id, 0);
    attrs[1].value = rb_funcall(obj, denominator_id, 0);

    oj_code_attrs(obj, attrs, depth, out, true);
}

static ID options_id = 0;
static ID source_id  = 0;

static void regexp_alt(VALUE obj, int depth, Out out) {
    struct _attr attrs[] = {
        {"o", 1, Qnil},
        {"s", 1, Qnil},
        {NULL, 0, Qnil},
    };
    if (0 == options_id) {
        options_id = rb_intern("options");
        source_id  = rb_intern("source");
    }
    attrs[0].value = rb_funcall(obj, options_id, 0);
    attrs[1].value = rb_funcall(obj, source_id, 0);

    oj_code_attrs(obj, attrs, depth, out, true);
}

static void time_alt(VALUE obj, int depth, Out out) {
    struct _attr attrs[] = {
        {"s", 1, Qundef, 0, Qundef},
        {"n", 1, Qundef, 0, Qundef},
        {NULL, 0, Qnil},
    };
    time_t    sec;
    long long nsec;

    if (16 <= sizeof(struct timespec)) {
        struct timespec ts = rb_time_timespec(obj);

        sec  = (long long)ts.tv_sec;
        nsec = ts.tv_nsec;
    } else {
        sec  = NUM2LL(rb_funcall2(obj, oj_tv_sec_id, 0, 0));
        nsec = NUM2LL(rb_funcall2(obj, oj_tv_nsec_id, 0, 0));
    }

    attrs[0].num = sec;
    attrs[1].num = nsec;

    oj_code_attrs(obj, attrs, depth, out, true);
}

struct _code oj_compat_codes[] = {
    {"BigDecimal", Qnil, bigdecimal_alt, NULL, false},
    {"Complex", Qnil, complex_alt, NULL, false},
    {"Date", Qnil, date_alt, false},
    {"DateTime", Qnil, datetime_alt, NULL, false},
    {"OpenStruct", Qnil, openstruct_alt, NULL, false},
    {"Range", Qnil, range_alt, NULL, false},
    {"Rational", Qnil, rational_alt, NULL, false},
    {"Regexp", Qnil, regexp_alt, NULL, false},
    {"Time", Qnil, time_alt, NULL, false},
    // TBD the rest of the library classes
    {NULL, Qundef, NULL, NULL, false},
};

VALUE
oj_add_to_json(int argc, VALUE *argv, VALUE self) {
    Code a;

    if (0 == argc) {
        for (a = oj_compat_codes; NULL != a->name; a++) {
            if (Qnil == a->clas || Qundef == a->clas) {
                a->clas = rb_const_get_at(rb_cObject, rb_intern(a->name));
            }
            a->active = true;
        }
        use_struct_alt    = true;
        use_exception_alt = true;
        use_bignum_alt    = true;
        oj_use_hash_alt   = true;
        oj_use_array_alt  = true;
    } else {
        for (; 0 < argc; argc--, argv++) {
            if (rb_cStruct == *argv) {
                use_struct_alt = true;
                continue;
            }
            if (rb_eException == *argv) {
                use_exception_alt = true;
                continue;
            }
            if (rb_cInteger == *argv) {
                use_bignum_alt = true;
                continue;
            }
            if (rb_cHash == *argv) {
                oj_use_hash_alt = true;
                continue;
            }
            if (rb_cArray == *argv) {
                oj_use_array_alt = true;
                continue;
            }
            for (a = oj_compat_codes; NULL != a->name; a++) {
                if (Qnil == a->clas || Qundef == a->clas) {
                    a->clas = rb_const_get_at(rb_cObject, rb_intern(a->name));
                }
                if (*argv == a->clas) {
                    a->active = true;
                    break;
                }
            }
        }
    }
    return Qnil;
}

VALUE
oj_remove_to_json(int argc, VALUE *argv, VALUE self) {
    if (0 == argc) {
        oj_code_set_active(oj_compat_codes, Qnil, false);
        use_struct_alt    = false;
        use_exception_alt = false;
        use_bignum_alt    = false;
        oj_use_hash_alt   = false;
        oj_use_array_alt  = false;
    } else {
        for (; 0 < argc; argc--, argv++) {
            if (rb_cStruct == *argv) {
                use_struct_alt = false;
                continue;
            }
            if (rb_eException == *argv) {
                use_exception_alt = false;
                continue;
            }
            if (rb_cInteger == *argv) {
                use_bignum_alt = false;
                continue;
            }
            if (rb_cHash == *argv) {
                oj_use_hash_alt = false;
                continue;
            }
            if (rb_cArray == *argv) {
                oj_use_array_alt = false;
                continue;
            }
            oj_code_set_active(oj_compat_codes, *argv, false);
        }
    }
    return Qnil;
}

// The JSON gem is inconsistent with handling of infinity. Using
// JSON.dump(0.1/0) returns the string Infinity but (0.1/0).to_json raise and
// exception. Worse, for BigDecimals a quoted "Infinity" is returned.
static void dump_float(VALUE obj, int depth, Out out, bool as_ok) {
    char   buf[64];
    char  *b;
    double d   = rb_num2dbl(obj);
    int    cnt = 0;

    if (0.0 == d) {
        b    = buf;
        *b++ = '0';
        *b++ = '.';
        *b++ = '0';
        *b++ = '\0';
        cnt  = 3;
    } else if (OJ_INFINITY == d) {
        if (WordNan == out->opts->dump_opts.nan_dump) {
            strcpy(buf, "Infinity");
            cnt = 8;
        } else {
            raise_json_err("Infinity not allowed in JSON.", "GeneratorError");
        }
    } else if (-OJ_INFINITY == d) {
        if (WordNan == out->opts->dump_opts.nan_dump) {
            strcpy(buf, "-Infinity");
            cnt = 9;
        } else {
            raise_json_err("-Infinity not allowed in JSON.", "GeneratorError");
        }
    } else if (isnan(d)) {
        if (WordNan == out->opts->dump_opts.nan_dump) {
            strcpy(buf, "NaN");
            cnt = 3;
        } else {
            raise_json_err("NaN not allowed in JSON.", "GeneratorError");
        }
    } else if (d == (double)(long long int)d) {
        cnt = snprintf(buf, sizeof(buf), "%.1f", d);
    } else if (oj_rails_float_opt) {
        cnt = oj_dump_float_printf(buf, sizeof(buf), obj, d, "%0.16g");
    } else {
        volatile VALUE rstr = oj_safe_string_convert(obj);

        strcpy(buf, RSTRING_PTR(rstr));
        cnt = (int)RSTRING_LEN(rstr);
    }
    assure_size(out, cnt);
    APPEND_CHARS(out->cur, buf, cnt);
    *out->cur = '\0';
}

static int hash_cb(VALUE key, VALUE value, VALUE ov) {
    Out out   = (Out)ov;
    int depth = out->depth;

    if (out->omit_nil && Qnil == value) {
        return ST_CONTINUE;
    }
    if (!out->opts->dump_opts.use) {
        assure_size(out, depth * out->indent + 1);
        fill_indent(out, depth);
    } else {
        assure_size(out, depth * out->opts->dump_opts.indent_size + out->opts->dump_opts.hash_size + 1);
        if (0 < out->opts->dump_opts.hash_size) {
            APPEND_CHARS(out->cur, out->opts->dump_opts.hash_nl, out->opts->dump_opts.hash_size);
        }
        if (0 < out->opts->dump_opts.indent_size) {
            int i;
            for (i = depth; 0 < i; i--) {
                APPEND_CHARS(out->cur, out->opts->dump_opts.indent_str, out->opts->dump_opts.indent_size);
            }
        }
    }
    switch (rb_type(key)) {
    case T_STRING: oj_dump_str(key, 0, out, false); break;
    case T_SYMBOL: oj_dump_sym(key, 0, out, false); break;
    default:
        /*rb_raise(rb_eTypeError, "In :compat mode all Hash keys must be Strings or Symbols, not %s.\n",
         * rb_class2name(rb_obj_class(key)));*/
        oj_dump_str(oj_safe_string_convert(key), 0, out, false);
        break;
    }
    if (!out->opts->dump_opts.use) {
        *out->cur++ = ':';
    } else {
        assure_size(out, out->opts->dump_opts.before_size + out->opts->dump_opts.after_size + 2);
        if (0 < out->opts->dump_opts.before_size) {
            APPEND_CHARS(out->cur, out->opts->dump_opts.before_sep, out->opts->dump_opts.before_size);
        }
        *out->cur++ = ':';
        if (0 < out->opts->dump_opts.after_size) {
            APPEND_CHARS(out->cur, out->opts->dump_opts.after_sep, out->opts->dump_opts.after_size);
        }
    }
    oj_dump_compat_val(value, depth, out, true);
    out->depth  = depth;
    *out->cur++ = ',';

    return ST_CONTINUE;
}

static void dump_hash(VALUE obj, int depth, Out out, bool as_ok) {
    int  cnt;
    long id = oj_check_circular(obj, out);

    if (0 > id) {
        raise_json_err("Too deeply nested", "NestingError");
        return;
    }
    if (as_ok && !oj_use_hash_alt && rb_obj_class(obj) != rb_cHash && rb_respond_to(obj, oj_to_json_id)) {
        dump_to_json(obj, out);
        return;
    }
    cnt = (int)RHASH_SIZE(obj);
    assure_size(out, 2);
    if (0 == cnt) {
        APPEND_CHARS(out->cur, "{}", 2);
    } else {
        *out->cur++ = '{';
        out->depth  = depth + 1;
        rb_hash_foreach(obj, hash_cb, (VALUE)out);
        if (',' == *(out->cur - 1)) {
            out->cur--;  // backup to overwrite last comma
        }
        if (!out->opts->dump_opts.use) {
            assure_size(out, depth * out->indent + 2);
            fill_indent(out, depth);
        } else {
            assure_size(out, depth * out->opts->dump_opts.indent_size + out->opts->dump_opts.hash_size + 1);
            if (0 < out->opts->dump_opts.hash_size) {
                APPEND_CHARS(out->cur, out->opts->dump_opts.hash_nl, out->opts->dump_opts.hash_size);
            }
            if (0 < out->opts->dump_opts.indent_size) {
                int i;

                for (i = depth; 0 < i; i--) {
                    APPEND_CHARS(out->cur, out->opts->dump_opts.indent_str, out->opts->dump_opts.indent_size);
                }
            }
        }
        *out->cur++ = '}';
    }
    *out->cur = '\0';
}

// In compat mode only the first call check for to_json. After that to_s is
// called.
static void dump_obj(VALUE obj, int depth, Out out, bool as_ok) {
    if (oj_code_dump(oj_compat_codes, obj, depth, out)) {
        return;
    }
    if (use_exception_alt && rb_obj_is_kind_of(obj, rb_eException)) {
        exception_alt(obj, depth, out);
        return;
    }
    if (Yes == out->opts->raw_json && rb_respond_to(obj, oj_raw_json_id)) {
        oj_dump_raw_json(obj, depth, out);
        return;
    }
    if (as_ok && rb_respond_to(obj, oj_to_json_id)) {
        dump_to_json(obj, out);
        return;
    }
    // Nothing else matched so encode as a JSON object with Ruby obj members
    // as JSON object members.
    oj_dump_obj_to_s(obj, out);
}

static void dump_struct(VALUE obj, int depth, Out out, bool as_ok) {
    VALUE clas = rb_obj_class(obj);

    if (oj_code_dump(oj_compat_codes, obj, depth, out)) {
        return;
    }
    if (rb_cRange == clas) {
        *out->cur++ = '"';
        oj_dump_compat_val(rb_funcall(obj, oj_begin_id, 0), 0, out, false);
        assure_size(out, 3);
        APPEND_CHARS(out->cur, "..", 2);
        if (Qtrue == rb_funcall(obj, oj_exclude_end_id, 0)) {
            *out->cur++ = '.';
        }
        oj_dump_compat_val(rb_funcall(obj, oj_end_id, 0), 0, out, false);
        *out->cur++ = '"';

        return;
    }
    if (as_ok && rb_respond_to(obj, oj_to_json_id)) {
        dump_to_json(obj, out);

        return;
    }
    if (use_struct_alt) {
        int         d3        = depth + 2;
        size_t      size      = d3 * out->indent + 2;
        size_t      sep_len   = out->opts->dump_opts.before_size + out->opts->dump_opts.after_size + 2;
        const char *classname = rb_class2name(rb_obj_class(obj));
        VALUE       args[100];
        int         cnt;
        int         i;

        if (NULL == classname || '#' == *classname) {
            raise_json_err("Only named structs are supported.", "JSONError");
        }
#ifdef RSTRUCT_LEN
#if RSTRUCT_LEN_RETURNS_INTEGER_OBJECT
        cnt = (int)NUM2LONG(RSTRUCT_LEN(obj));
#else   // RSTRUCT_LEN_RETURNS_INTEGER_OBJECT
        cnt = (int)RSTRUCT_LEN(obj);
#endif  // RSTRUCT_LEN_RETURNS_INTEGER_OBJECT
#else
        // This is a bit risky as a struct in C ruby is not the same as a Struct
        // class in interpreted Ruby so length() may not be defined.
        cnt = FIX2INT(rb_funcall2(obj, oj_length_id, 0, 0));
#endif
        if (sizeof(args) / sizeof(*args) <= (size_t)cnt) {
            // TBD allocate and try again
            cnt = 99;
        }
        dump_obj_classname(rb_class2name(rb_obj_class(obj)), depth, out);

        assure_size(out, size + sep_len + 6);
        *out->cur++ = ',';
        fill_indent(out, d3);
        APPEND_CHARS(out->cur, "\"v\"", 3);
        if (0 < out->opts->dump_opts.before_size) {
            APPEND_CHARS(out->cur, out->opts->dump_opts.before_sep, out->opts->dump_opts.before_size);
        }
        *out->cur++ = ':';
        if (0 < out->opts->dump_opts.after_size) {
            APPEND_CHARS(out->cur, out->opts->dump_opts.after_sep, out->opts->dump_opts.after_size);
        }
        for (i = 0; i < cnt; i++) {
#ifdef RSTRUCT_LEN
            args[i] = RSTRUCT_GET(obj, i);
#else
            args[i] = rb_struct_aref(obj, INT2FIX(i));
#endif
        }
        args[cnt] = Qundef;
        dump_values_array(args, depth, out);
        fill_indent(out, depth);
        *out->cur++ = '}';
        *out->cur   = '\0';
    } else {
        oj_dump_obj_to_s(obj, out);
    }
}

static void dump_bignum(VALUE obj, int depth, Out out, bool as_ok) {
    // The json gem uses to_s explicitly. to_s can be overridden while
    // rb_big2str can not so unless overridden by using add_to_json(Integer)
    // this must use to_s to pass the json gem unit tests.
    volatile VALUE rs;
    int            cnt;
    bool           dump_as_string = false;

    if (use_bignum_alt) {
        rs = rb_big2str(obj, 10);
    } else {
        rs = oj_safe_string_convert(obj);
    }
    rb_check_type(rs, T_STRING);
    cnt = (int)RSTRING_LEN(rs);

    if (out->opts->int_range_min != 0 || out->opts->int_range_max != 0) {
        dump_as_string = true;  // Bignum cannot be inside of Fixnum range
        assure_size(out, cnt + 2);
        *out->cur++ = '"';
    } else {
        assure_size(out, cnt);
    }
    APPEND_CHARS(out->cur, RSTRING_PTR(rs), cnt);
    if (dump_as_string) {
        *out->cur++ = '"';
    }
    *out->cur = '\0';
}

static DumpFunc compat_funcs[] = {
    NULL,            // RUBY_T_NONE   = 0x00,
    dump_obj,        // RUBY_T_OBJECT = 0x01,
    oj_dump_class,   // RUBY_T_CLASS  = 0x02,
    oj_dump_class,   // RUBY_T_MODULE = 0x03,
    dump_float,      // RUBY_T_FLOAT  = 0x04,
    oj_dump_str,     // RUBY_T_STRING = 0x05,
    dump_obj,        // RUBY_T_REGEXP = 0x06,
    dump_array,      // RUBY_T_ARRAY  = 0x07,
    dump_hash,       // RUBY_T_HASH   = 0x08,
    dump_struct,     // RUBY_T_STRUCT = 0x09,
    dump_bignum,     // RUBY_T_BIGNUM = 0x0a,
    NULL,            // RUBY_T_FILE   = 0x0b,
    dump_obj,        // RUBY_T_DATA   = 0x0c,
    NULL,            // RUBY_T_MATCH  = 0x0d,
    dump_obj,        // RUBY_T_COMPLEX  = 0x0e,
    dump_obj,        // RUBY_T_RATIONAL = 0x0f,
    NULL,            // 0x10
    oj_dump_nil,     // RUBY_T_NIL    = 0x11,
    oj_dump_true,    // RUBY_T_TRUE   = 0x12,
    oj_dump_false,   // RUBY_T_FALSE  = 0x13,
    oj_dump_sym,     // RUBY_T_SYMBOL = 0x14,
    oj_dump_fixnum,  // RUBY_T_FIXNUM = 0x15,
};

static void set_state_depth(VALUE state, int depth) {
    if (0 == rb_const_defined(rb_cObject, rb_intern("JSON"))) {
        rb_require("oj/json");
    }
    {
        VALUE json_module = rb_const_get_at(rb_cObject, rb_intern("JSON"));
        VALUE ext         = rb_const_get(json_module, rb_intern("Ext"));
        VALUE generator   = rb_const_get(ext, rb_intern("Generator"));
        VALUE state_class = rb_const_get(generator, rb_intern("State"));

        if (state_class == rb_obj_class(state)) {
            rb_funcall(state, rb_intern("depth="), 1, INT2NUM(depth));
        }
    }
}

void oj_dump_compat_val(VALUE obj, int depth, Out out, bool as_ok) {
    int type = rb_type(obj);

    TRACE(out->opts->trace, "dump", obj, depth, TraceIn);
    // The max_nesting logic is that an empty Array or Hash is assumed to have
    // content so the max_nesting should fail but a non-collection value is
    // okay. That means a check for a collectable value is needed before
    // raising.
    if (out->opts->dump_opts.max_depth <= depth) {
        if (RUBY_T_ARRAY == type || RUBY_T_HASH == type) {
            if (0 < out->argc) {
                set_state_depth(*out->argv, depth);
            }
            raise_json_err("Too deeply nested", "NestingError");
        }
    }
    if (0 < type && type <= RUBY_T_FIXNUM) {
        DumpFunc f = compat_funcs[type];

        if (NULL != f) {
            f(obj, depth, out, as_ok);
            TRACE(out->opts->trace, "dump", obj, depth, TraceOut);
            return;
        }
    }
    oj_dump_nil(Qnil, depth, out, false);
    TRACE(out->opts->trace, "dump", Qnil, depth, TraceOut);
}
