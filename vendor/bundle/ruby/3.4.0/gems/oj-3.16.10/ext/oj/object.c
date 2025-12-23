// Copyright (c) 2012 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#include <stdint.h>
#include <stdio.h>
#include <time.h>

#include "encode.h"
#include "err.h"
#include "intern.h"
#include "odd.h"
#include "oj.h"
#include "parse.h"
#include "resolve.h"
#include "trace.h"
#include "util.h"

inline static long read_long(const char *str, size_t len) {
    long n = 0;

    for (; 0 < len; str++, len--) {
        if ('0' <= *str && *str <= '9') {
            n = n * 10 + (*str - '0');
        } else {
            return -1;
        }
    }
    return n;
}

static VALUE calc_hash_key(ParseInfo pi, Val kval, char k1) {
    volatile VALUE rkey;

    if (':' == k1) {
        return ID2SYM(rb_intern3(kval->key + 1, kval->klen - 1, oj_utf8_encoding));
    }
    if (Yes == pi->options.sym_key) {
        return ID2SYM(rb_intern3(kval->key, kval->klen, oj_utf8_encoding));
    }
#if HAVE_RB_ENC_INTERNED_STR
    rkey = rb_enc_interned_str(kval->key, kval->klen, oj_utf8_encoding);
#else
    rkey = rb_utf8_str_new(kval->key, kval->klen);
    OBJ_FREEZE(rkey);
#endif
    return rkey;
}

static VALUE str_to_value(ParseInfo pi, const char *str, size_t len, const char *orig) {
    volatile VALUE rstr = Qnil;

    if (':' == *orig && 0 < len) {
        rstr = ID2SYM(rb_intern3(str + 1, len - 1, oj_utf8_encoding));
    } else if (pi->circ_array && 3 <= len && '^' == *orig && 'r' == orig[1]) {
        long i = read_long(str + 2, len - 2);

        if (0 > i) {
            oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "not a valid ID number");
            return Qnil;
        }
        rstr = oj_circ_array_get(pi->circ_array, i);
    } else {
        rstr = rb_utf8_str_new(str, len);
    }
    return rstr;
}

// The much faster approach (4x faster)
static int parse_num(const char *str, const char *end, int cnt) {
    int  n = 0;
    char c;
    int  i;

    for (i = cnt; 0 < i; i--, str++) {
        c = *str;
        if (end <= str || c < '0' || '9' < c) {
            return -1;
        }
        n = n * 10 + (c - '0');
    }
    return n;
}

VALUE
oj_parse_xml_time(const char *str, int len) {
    VALUE       args[7];
    const char *end  = str + len;
    const char *orig = str;
    int         n;

    // year
    if (0 > (n = parse_num(str, end, 4))) {
        return Qnil;
    }
    str += 4;
    args[0] = LONG2NUM(n);
    if ('-' != *str++) {
        return Qnil;
    }
    // month
    if (0 > (n = parse_num(str, end, 2))) {
        return Qnil;
    }
    str += 2;
    args[1] = LONG2NUM(n);
    if ('-' != *str++) {
        return Qnil;
    }
    // day
    if (0 > (n = parse_num(str, end, 2))) {
        return Qnil;
    }
    str += 2;
    args[2] = LONG2NUM(n);
    if ('T' != *str++) {
        return Qnil;
    }
    // hour
    if (0 > (n = parse_num(str, end, 2))) {
        return Qnil;
    }
    str += 2;
    args[3] = LONG2NUM(n);
    if (':' != *str++) {
        return Qnil;
    }
    // minute
    if (0 > (n = parse_num(str, end, 2))) {
        return Qnil;
    }
    str += 2;
    args[4] = LONG2NUM(n);
    if (':' != *str++) {
        return Qnil;
    }
    // second
    if (0 > (n = parse_num(str, end, 2))) {
        return Qnil;
    }
    str += 2;
    if (str == end) {
        args[5] = LONG2NUM(n);
        args[6] = LONG2NUM(0);
    } else {
        char c = *str++;

        if ('.' == c) {
            unsigned long long       num            = 0;
            unsigned long long       den            = 1;
            const unsigned long long last_den_limit = ULLONG_MAX / 10;

            for (; str < end; str++) {
                c = *str;
                if (c < '0' || '9' < c) {
                    str++;
                    break;
                }
                if (den > last_den_limit) {
                    // bail to Time.parse if there are more fractional digits than a ULLONG rational can hold
                    return rb_funcall(rb_cTime, oj_parse_id, 1, rb_str_new(orig, len));
                }
                num = num * 10 + (c - '0');
                den *= 10;
            }
            args[5] = rb_funcall(INT2NUM(n), oj_plus_id, 1, rb_rational_new(ULL2NUM(num), ULL2NUM(den)));
        } else {
            args[5] = rb_ll2inum(n);
        }
        if (end < str) {
            args[6] = LONG2NUM(0);
        } else {
            if ('Z' == c) {
                return rb_funcall2(rb_cTime, oj_utc_id, 6, args);
            } else if ('+' == c) {
                int hr = parse_num(str, end, 2);
                int min;

                str += 2;
                if (0 > hr || ':' != *str++) {
                    return Qnil;
                }
                min = parse_num(str, end, 2);
                if (0 > min) {
                    return Qnil;
                }
                args[6] = LONG2NUM(hr * 3600 + min * 60);
            } else if ('-' == c) {
                int hr = parse_num(str, end, 2);
                int min;

                str += 2;
                if (0 > hr || ':' != *str++) {
                    return Qnil;
                }
                min = parse_num(str, end, 2);
                if (0 > min) {
                    return Qnil;
                }
                args[6] = LONG2NUM(-(hr * 3600 + min * 60));
            } else {
                args[6] = LONG2NUM(0);
            }
        }
    }
    return rb_funcall2(rb_cTime, oj_new_id, 7, args);
}

static int hat_cstr(ParseInfo pi, Val parent, Val kval, const char *str, size_t len) {
    const char *key  = kval->key;
    int         klen = kval->klen;

    if (2 == klen) {
        switch (key[1]) {
        case 'o':  // object
        {          // name2class sets an error if the class is not found or created
            VALUE clas = oj_name2class(pi, str, len, Yes == pi->options.auto_define, rb_eArgError);

            if (Qundef != clas) {
                parent->val = rb_obj_alloc(clas);
            }
        } break;
        case 'O':  // odd object
        {
            Odd odd = oj_get_oddc(str, len);

            if (0 == odd) {
                return 0;
            }
            parent->val      = odd->clas;
            parent->odd_args = oj_odd_alloc_args(odd);
            break;
        }
        case 'm': parent->val = ID2SYM(rb_intern3(str + 1, len - 1, oj_utf8_encoding)); break;
        case 's': parent->val = rb_utf8_str_new(str, len); break;
        case 'c':  // class
        {
            VALUE clas = oj_name2class(pi, str, len, Yes == pi->options.auto_define, rb_eArgError);

            if (Qundef == clas) {
                return 0;
            } else {
                parent->val = clas;
            }
            break;
        }
        case 't':  // time
            parent->val = oj_parse_xml_time(str, (int)len);
            break;
        default: return 0; break;
        }
        return 1;  // handled
    }
    return 0;
}

static int hat_num(ParseInfo pi, Val parent, Val kval, NumInfo ni) {
    if (2 == kval->klen) {
        switch (kval->key[1]) {
        case 't':  // time as a float
            if (0 == ni->div || 9 < ni->di) {
                rb_raise(rb_eArgError, "Invalid time decimal representation.");
                // parent->val = rb_time_nano_new(0, 0);
            } else {
                int64_t nsec = ni->num * 1000000000LL / ni->div;

                if (ni->neg) {
                    ni->i = -ni->i;
                    if (0 < nsec) {
                        ni->i--;
                        nsec = 1000000000LL - nsec;
                    }
                }
                if (86400 == ni->exp) {  // UTC time
                    parent->val = rb_time_nano_new(ni->i, (long)nsec);
                    // Since the ruby C routines always create local time, the
                    // offset and then a conversion to UTC keeps makes the time
                    // match the expected value.
                    parent->val = rb_funcall2(parent->val, oj_utc_id, 0, 0);
                } else if (ni->has_exp) {
                    struct timespec ts;
                    ts.tv_sec   = ni->i;
                    ts.tv_nsec  = nsec;
                    parent->val = rb_time_timespec_new(&ts, (int)ni->exp);
                } else {
                    parent->val = rb_time_nano_new(ni->i, (long)nsec);
                }
            }
            break;
        case 'i':                                                                                    // circular index
            if (!ni->infinity && !ni->neg && 1 == ni->div && 0 == ni->exp && 0 != pi->circ_array) {  // fixnum
                if (Qnil == parent->val) {
                    parent->val = rb_hash_new();
                }
                oj_circ_array_set(pi->circ_array, parent->val, ni->i);
            } else {
                return 0;
            }
            break;
        default: return 0; break;
        }
        return 1;  // handled
    }
    return 0;
}

static int hat_value(ParseInfo pi, Val parent, const char *key, size_t klen, volatile VALUE value) {
    if (T_ARRAY == rb_type(value)) {
        int len = (int)RARRAY_LEN(value);

        if (2 == klen && 'u' == key[1]) {
            volatile VALUE sc;
            volatile VALUE e1;
            int            slen;

            if (0 == len) {
                oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "Invalid struct data");
                return 1;
            }
            e1 = *RARRAY_CONST_PTR(value);
            // check for anonymous Struct
            if (T_ARRAY == rb_type(e1)) {
                VALUE          args[1024];
                volatile VALUE rstr;
                int            i, cnt = (int)RARRAY_LEN(e1);

                for (i = 0; i < cnt; i++) {
                    rstr    = RARRAY_AREF(e1, i);
                    args[i] = rb_funcall(rstr, oj_to_sym_id, 0);
                }
                sc = rb_funcall2(rb_cStruct, oj_new_id, cnt, args);
            } else {
                // If struct is not defined then we let this fail and raise an exception.
                sc = oj_name2struct(pi, *RARRAY_CONST_PTR(value), rb_eArgError);
            }
            if (sc == rb_cRange) {
                parent->val = rb_class_new_instance(len - 1, RARRAY_CONST_PTR(value) + 1, rb_cRange);
            } else {
                // Create a properly initialized struct instance without calling the initialize method.
                parent->val = rb_obj_alloc(sc);
                // If the JSON array has more entries than the struct class allows, we record an error.
#ifdef RSTRUCT_LEN
#if RSTRUCT_LEN_RETURNS_INTEGER_OBJECT
                slen = (int)NUM2LONG(RSTRUCT_LEN(parent->val));
#else   // RSTRUCT_LEN_RETURNS_INTEGER_OBJECT
                slen = (int)RSTRUCT_LEN(parent->val);
#endif  // RSTRUCT_LEN_RETURNS_INTEGER_OBJECT
#else
                slen = FIX2INT(rb_funcall2(parent->val, oj_length_id, 0, 0));
#endif
                // MRI >= 1.9
                if (len - 1 > slen) {
                    oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "Invalid struct data");
                } else {
                    int i;

                    for (i = 0; i < len - 1; i++) {
                        rb_struct_aset(parent->val, INT2FIX(i), RARRAY_CONST_PTR(value)[i + 1]);
                    }
                }
            }
            return 1;
        } else if (3 <= klen && '#' == key[1]) {
            volatile const VALUE *a;

            if (2 != len) {
                oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "invalid hash pair");
                return 1;
            }
            parent->val = rb_hash_new();
            a           = RARRAY_CONST_PTR(value);
            rb_hash_aset(parent->val, *a, a[1]);

            return 1;
        }
    }
    return 0;
}

void oj_set_obj_ivar(Val parent, Val kval, VALUE value) {
    if (kval->klen == 5 && strncmp("~mesg", kval->key, 5) == 0 && rb_obj_is_kind_of(parent->val, rb_eException)) {
        parent->val = rb_funcall(parent->val, rb_intern("exception"), 1, value);
    } else if (kval->klen == 3 && strncmp("~bt", kval->key, 3) == 0 && rb_obj_is_kind_of(parent->val, rb_eException)) {
        rb_funcall(parent->val, rb_intern("set_backtrace"), 1, value);
    } else {
        rb_ivar_set(parent->val, oj_attr_intern(kval->key, kval->klen), value);
    }
}

static void hash_set_cstr(ParseInfo pi, Val kval, const char *str, size_t len, const char *orig) {
    const char    *key    = kval->key;
    int            klen   = kval->klen;
    Val            parent = stack_peek(&pi->stack);
    volatile VALUE rval   = Qnil;

WHICH_TYPE:
    switch (rb_type(parent->val)) {
    case T_NIL:
        parent->odd_args = NULL;  // make sure it is NULL in case not odd
        if ('^' != *key || !hat_cstr(pi, parent, kval, str, len)) {
            parent->val = rb_hash_new();
            goto WHICH_TYPE;
        }
        break;
    case T_HASH:
        rb_hash_aset(parent->val, calc_hash_key(pi, kval, parent->k1), str_to_value(pi, str, len, orig));
        break;
    case T_STRING:
        rval = str_to_value(pi, str, len, orig);
        if (4 == klen && 's' == *key && 'e' == key[1] && 'l' == key[2] && 'f' == key[3]) {
            rb_funcall(parent->val, oj_replace_id, 1, rval);
        } else {
            oj_set_obj_ivar(parent, kval, rval);
        }
        break;
    case T_OBJECT:
        rval = str_to_value(pi, str, len, orig);
        oj_set_obj_ivar(parent, kval, rval);
        break;
    case T_CLASS:
        if (NULL == parent->odd_args) {
            oj_set_error_at(pi,
                            oj_parse_error_class,
                            __FILE__,
                            __LINE__,
                            "%s is not an odd class",
                            rb_class2name(rb_obj_class(parent->val)));
            return;
        } else {
            rval = str_to_value(pi, str, len, orig);
            if (0 != oj_odd_set_arg(parent->odd_args, kval->key, kval->klen, rval)) {
                char buf[256];

                if ((int)sizeof(buf) - 1 <= klen) {
                    klen = sizeof(buf) - 2;
                }
                memcpy(buf, key, klen);
                buf[klen] = '\0';
                oj_set_error_at(pi,
                                oj_parse_error_class,
                                __FILE__,
                                __LINE__,
                                "%s is not an attribute of %s",
                                buf,
                                rb_class2name(rb_obj_class(parent->val)));
            }
        }
        break;
    default:
        oj_set_error_at(pi,
                        oj_parse_error_class,
                        __FILE__,
                        __LINE__,
                        "can not add attributes to a %s",
                        rb_class2name(rb_obj_class(parent->val)));
        return;
    }
    TRACE_PARSE_CALL(pi->options.trace, "set_string", pi, rval);
}

static void hash_set_num(ParseInfo pi, Val kval, NumInfo ni) {
    const char    *key    = kval->key;
    int            klen   = kval->klen;
    Val            parent = stack_peek(&pi->stack);
    volatile VALUE rval   = Qnil;

WHICH_TYPE:
    switch (rb_type(parent->val)) {
    case T_NIL:
        parent->odd_args = NULL;  // make sure it is NULL in case not odd
        if ('^' != *key || !hat_num(pi, parent, kval, ni)) {
            parent->val = rb_hash_new();
            goto WHICH_TYPE;
        }
        break;
    case T_HASH:
        rval = oj_num_as_value(ni);
        rb_hash_aset(parent->val, calc_hash_key(pi, kval, parent->k1), rval);
        break;
    case T_OBJECT:
        if (2 == klen && '^' == *key && 'i' == key[1] && !ni->infinity && !ni->neg && 1 == ni->div && 0 == ni->exp &&
            0 != pi->circ_array) {  // fixnum
            oj_circ_array_set(pi->circ_array, parent->val, ni->i);
        } else {
            rval = oj_num_as_value(ni);
            oj_set_obj_ivar(parent, kval, rval);
        }
        break;
    case T_CLASS:
        if (NULL == parent->odd_args) {
            oj_set_error_at(pi,
                            oj_parse_error_class,
                            __FILE__,
                            __LINE__,
                            "%s is not an odd class",
                            rb_class2name(rb_obj_class(parent->val)));
            return;
        } else {
            rval = oj_num_as_value(ni);
            if (0 != oj_odd_set_arg(parent->odd_args, key, klen, rval)) {
                char buf[256];

                if ((int)sizeof(buf) - 1 <= klen) {
                    klen = sizeof(buf) - 2;
                }
                memcpy(buf, key, klen);
                buf[klen] = '\0';
                oj_set_error_at(pi,
                                oj_parse_error_class,
                                __FILE__,
                                __LINE__,
                                "%s is not an attribute of %s",
                                buf,
                                rb_class2name(rb_obj_class(parent->val)));
            }
        }
        break;
    default:
        oj_set_error_at(pi,
                        oj_parse_error_class,
                        __FILE__,
                        __LINE__,
                        "can not add attributes to a %s",
                        rb_class2name(rb_obj_class(parent->val)));
        return;
    }
    TRACE_PARSE_CALL(pi->options.trace, "add_number", pi, rval);
}

static void hash_set_value(ParseInfo pi, Val kval, VALUE value) {
    const char *key    = kval->key;
    int         klen   = kval->klen;
    Val         parent = stack_peek(&pi->stack);

WHICH_TYPE:
    switch (rb_type(parent->val)) {
    case T_NIL:
        parent->odd_args = NULL;  // make sure it is NULL in case not odd
        if ('^' != *key || !hat_value(pi, parent, key, klen, value)) {
            parent->val = rb_hash_new();
            goto WHICH_TYPE;
        }
        break;
    case T_HASH:
        if (rb_cHash != rb_obj_class(parent->val)) {
            if (4 == klen && 's' == *key && 'e' == key[1] && 'l' == key[2] && 'f' == key[3]) {
                rb_funcall(parent->val, oj_replace_id, 1, value);
            } else {
                oj_set_obj_ivar(parent, kval, value);
            }
        } else {
            if (3 <= klen && '^' == *key && '#' == key[1] && T_ARRAY == rb_type(value)) {
                long                  len = RARRAY_LEN(value);
                volatile const VALUE *a   = RARRAY_CONST_PTR(value);

                if (2 != len) {
                    oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "invalid hash pair");
                    return;
                }
                rb_hash_aset(parent->val, *a, a[1]);
            } else {
                rb_hash_aset(parent->val, calc_hash_key(pi, kval, parent->k1), value);
            }
        }
        break;
    case T_ARRAY:
        if (4 == klen && 's' == *key && 'e' == key[1] && 'l' == key[2] && 'f' == key[3]) {
            rb_funcall(parent->val, oj_replace_id, 1, value);
        } else {
            oj_set_obj_ivar(parent, kval, value);
        }
        break;
    case T_STRING:  // for subclassed strings
    case T_OBJECT: oj_set_obj_ivar(parent, kval, value); break;
    case T_MODULE:
    case T_CLASS:
        if (NULL == parent->odd_args) {
            oj_set_error_at(pi,
                            oj_parse_error_class,
                            __FILE__,
                            __LINE__,
                            "%s is not an odd class",
                            rb_class2name(rb_obj_class(parent->val)));
            return;
        } else if (0 != oj_odd_set_arg(parent->odd_args, key, klen, value)) {
            char buf[256];

            if ((int)sizeof(buf) - 1 <= klen) {
                klen = sizeof(buf) - 2;
            }
            memcpy(buf, key, klen);
            buf[klen] = '\0';
            oj_set_error_at(pi,
                            oj_parse_error_class,
                            __FILE__,
                            __LINE__,
                            "%s is not an attribute of %s",
                            buf,
                            rb_class2name(rb_obj_class(parent->val)));
        }
        break;
    default:
        oj_set_error_at(pi,
                        oj_parse_error_class,
                        __FILE__,
                        __LINE__,
                        "can not add attributes to a %s",
                        rb_class2name(rb_obj_class(parent->val)));
        return;
    }
    TRACE_PARSE_CALL(pi->options.trace, "add_value", pi, value);
}

static VALUE start_hash(ParseInfo pi) {
    TRACE_PARSE_IN(pi->options.trace, "start_hash", pi);
    return Qnil;
}

static void end_hash(ParseInfo pi) {
    Val parent = stack_peek(&pi->stack);

    if (Qnil == parent->val) {
        parent->val = rb_hash_new();
    } else if (NULL != parent->odd_args) {
        OddArgs oa = parent->odd_args;

        parent->val = rb_funcall2(oa->odd->create_obj, oa->odd->create_op, oa->odd->attr_cnt, oa->args);
        oj_odd_free(oa);
        parent->odd_args = NULL;
    }
    TRACE_PARSE_HASH_END(pi->options.trace, pi);
}

static void array_append_cstr(ParseInfo pi, const char *str, size_t len, const char *orig) {
    volatile VALUE rval = Qnil;

    // orig lets us know whether the string was ^r1 or \u005er1
    if (3 <= len && 0 != pi->circ_array && '^' == orig[0] && 0 == rb_array_len(stack_peek(&pi->stack)->val)) {
        if ('i' == str[1]) {
            long i = read_long(str + 2, len - 2);

            if (0 < i) {
                oj_circ_array_set(pi->circ_array, stack_peek(&pi->stack)->val, i);
                return;
            }
        } else if ('r' == str[1]) {
            long i = read_long(str + 2, len - 2);

            if (0 < i) {
                rb_ary_push(stack_peek(&pi->stack)->val, oj_circ_array_get(pi->circ_array, i));
                return;
            }
        }
    }
    rval = str_to_value(pi, str, len, orig);
    rb_ary_push(stack_peek(&pi->stack)->val, rval);
    TRACE_PARSE_CALL(pi->options.trace, "append_string", pi, rval);
}

static void array_append_num(ParseInfo pi, NumInfo ni) {
    volatile VALUE rval = oj_num_as_value(ni);

    rb_ary_push(stack_peek(&pi->stack)->val, rval);
    TRACE_PARSE_CALL(pi->options.trace, "append_number", pi, rval);
}

static void add_cstr(ParseInfo pi, const char *str, size_t len, const char *orig) {
    pi->stack.head->val = str_to_value(pi, str, len, orig);
    TRACE_PARSE_CALL(pi->options.trace, "add_string", pi, pi->stack.head->val);
}

static void add_num(ParseInfo pi, NumInfo ni) {
    pi->stack.head->val = oj_num_as_value(ni);
    TRACE_PARSE_CALL(pi->options.trace, "add_num", pi, pi->stack.head->val);
}

void oj_set_object_callbacks(ParseInfo pi) {
    oj_set_strict_callbacks(pi);
    pi->end_hash          = end_hash;
    pi->start_hash        = start_hash;
    pi->hash_set_cstr     = hash_set_cstr;
    pi->hash_set_num      = hash_set_num;
    pi->hash_set_value    = hash_set_value;
    pi->add_cstr          = add_cstr;
    pi->add_num           = add_num;
    pi->array_append_cstr = array_append_cstr;
    pi->array_append_num  = array_append_num;
}

VALUE
oj_object_parse(int argc, VALUE *argv, VALUE self) {
    struct _parseInfo pi;

    parse_info_init(&pi);
    pi.options   = oj_default_options;
    pi.handler   = Qnil;
    pi.err_class = Qnil;
    oj_set_object_callbacks(&pi);

    if (T_STRING == rb_type(*argv)) {
        return oj_pi_parse(argc, argv, &pi, 0, 0, 1);
    } else {
        return oj_pi_sparse(argc, argv, &pi, 0);
    }
}

VALUE
oj_object_parse_cstr(int argc, VALUE *argv, char *json, size_t len) {
    struct _parseInfo pi;

    parse_info_init(&pi);
    pi.options   = oj_default_options;
    pi.handler   = Qnil;
    pi.err_class = Qnil;
    oj_set_strict_callbacks(&pi);
    pi.end_hash          = end_hash;
    pi.start_hash        = start_hash;
    pi.hash_set_cstr     = hash_set_cstr;
    pi.hash_set_num      = hash_set_num;
    pi.hash_set_value    = hash_set_value;
    pi.add_cstr          = add_cstr;
    pi.add_num           = add_num;
    pi.array_append_cstr = array_append_cstr;
    pi.array_append_num  = array_append_num;

    return oj_pi_parse(argc, argv, &pi, json, len, 1);
}
