#include "prism/extension.h"

#ifdef PRISM_EXCLUDE_PACK

void
Init_prism_pack(void) {}

#else

static VALUE rb_cPrism;
static VALUE rb_cPrismPack;
static VALUE rb_cPrismPackDirective;
static VALUE rb_cPrismPackFormat;

static VALUE v3_2_0_symbol;
static VALUE pack_symbol;
static VALUE unpack_symbol;

#if SIZEOF_UINT64_T == SIZEOF_LONG_LONG
# define UINT64T2NUM(x) ULL2NUM(x)
# define NUM2UINT64T(x) (uint64_t)NUM2ULL(x)
#elif SIZEOF_UINT64_T == SIZEOF_LONG
# define UINT64T2NUM(x) ULONG2NUM(x)
# define NUM2UINT64T(x) (uint64_t)NUM2ULONG(x)
#else
// error No uint64_t conversion
#endif

static VALUE
pack_type_to_symbol(pm_pack_type type) {
    switch (type) {
        case PM_PACK_SPACE:
            return ID2SYM(rb_intern("SPACE"));
        case PM_PACK_COMMENT:
            return ID2SYM(rb_intern("COMMENT"));
        case PM_PACK_INTEGER:
            return ID2SYM(rb_intern("INTEGER"));
        case PM_PACK_UTF8:
            return ID2SYM(rb_intern("UTF8"));
        case PM_PACK_BER:
            return ID2SYM(rb_intern("BER"));
        case PM_PACK_FLOAT:
            return ID2SYM(rb_intern("FLOAT"));
        case PM_PACK_STRING_SPACE_PADDED:
            return ID2SYM(rb_intern("STRING_SPACE_PADDED"));
        case PM_PACK_STRING_NULL_PADDED:
            return ID2SYM(rb_intern("STRING_NULL_PADDED"));
        case PM_PACK_STRING_NULL_TERMINATED:
            return ID2SYM(rb_intern("STRING_NULL_TERMINATED"));
        case PM_PACK_STRING_MSB:
            return ID2SYM(rb_intern("STRING_MSB"));
        case PM_PACK_STRING_LSB:
            return ID2SYM(rb_intern("STRING_LSB"));
        case PM_PACK_STRING_HEX_HIGH:
            return ID2SYM(rb_intern("STRING_HEX_HIGH"));
        case PM_PACK_STRING_HEX_LOW:
            return ID2SYM(rb_intern("STRING_HEX_LOW"));
        case PM_PACK_STRING_UU:
            return ID2SYM(rb_intern("STRING_UU"));
        case PM_PACK_STRING_MIME:
            return ID2SYM(rb_intern("STRING_MIME"));
        case PM_PACK_STRING_BASE64:
            return ID2SYM(rb_intern("STRING_BASE64"));
        case PM_PACK_STRING_FIXED:
            return ID2SYM(rb_intern("STRING_FIXED"));
        case PM_PACK_STRING_POINTER:
            return ID2SYM(rb_intern("STRING_POINTER"));
        case PM_PACK_MOVE:
            return ID2SYM(rb_intern("MOVE"));
        case PM_PACK_BACK:
            return ID2SYM(rb_intern("BACK"));
        case PM_PACK_NULL:
            return ID2SYM(rb_intern("NULL"));
        default:
            return Qnil;
    }
}

static VALUE
pack_signed_to_symbol(pm_pack_signed signed_type) {
    switch (signed_type) {
        case PM_PACK_UNSIGNED:
            return ID2SYM(rb_intern("UNSIGNED"));
        case PM_PACK_SIGNED:
            return ID2SYM(rb_intern("SIGNED"));
        case PM_PACK_SIGNED_NA:
            return ID2SYM(rb_intern("SIGNED_NA"));
        default:
            return Qnil;
    }
}

static VALUE
pack_endian_to_symbol(pm_pack_endian endian) {
    switch (endian) {
        case PM_PACK_AGNOSTIC_ENDIAN:
            return ID2SYM(rb_intern("AGNOSTIC_ENDIAN"));
        case PM_PACK_LITTLE_ENDIAN:
            return ID2SYM(rb_intern("LITTLE_ENDIAN"));
        case PM_PACK_BIG_ENDIAN:
            return ID2SYM(rb_intern("BIG_ENDIAN"));
        case PM_PACK_NATIVE_ENDIAN:
            return ID2SYM(rb_intern("NATIVE_ENDIAN"));
        case PM_PACK_ENDIAN_NA:
            return ID2SYM(rb_intern("ENDIAN_NA"));
        default:
            return Qnil;
    }
}

static VALUE
pack_size_to_symbol(pm_pack_size size) {
    switch (size) {
        case PM_PACK_SIZE_SHORT:
            return ID2SYM(rb_intern("SIZE_SHORT"));
        case PM_PACK_SIZE_INT:
            return ID2SYM(rb_intern("SIZE_INT"));
        case PM_PACK_SIZE_LONG:
            return ID2SYM(rb_intern("SIZE_LONG"));
        case PM_PACK_SIZE_LONG_LONG:
            return ID2SYM(rb_intern("SIZE_LONG_LONG"));
        case PM_PACK_SIZE_8:
            return ID2SYM(rb_intern("SIZE_8"));
        case PM_PACK_SIZE_16:
            return ID2SYM(rb_intern("SIZE_16"));
        case PM_PACK_SIZE_32:
            return ID2SYM(rb_intern("SIZE_32"));
        case PM_PACK_SIZE_64:
            return ID2SYM(rb_intern("SIZE_64"));
        case PM_PACK_SIZE_P:
            return ID2SYM(rb_intern("SIZE_P"));
        case PM_PACK_SIZE_NA:
            return ID2SYM(rb_intern("SIZE_NA"));
        default:
            return Qnil;
    }
}

static VALUE
pack_length_type_to_symbol(pm_pack_length_type length_type) {
    switch (length_type) {
        case PM_PACK_LENGTH_FIXED:
            return ID2SYM(rb_intern("LENGTH_FIXED"));
        case PM_PACK_LENGTH_MAX:
            return ID2SYM(rb_intern("LENGTH_MAX"));
        case PM_PACK_LENGTH_RELATIVE:
            return ID2SYM(rb_intern("LENGTH_RELATIVE"));
        case PM_PACK_LENGTH_NA:
            return ID2SYM(rb_intern("LENGTH_NA"));
        default:
            return Qnil;
    }
}

static VALUE
pack_encoding_to_ruby(pm_pack_encoding encoding) {
    int index;
    switch (encoding) {
        case PM_PACK_ENCODING_ASCII_8BIT:
            index = rb_ascii8bit_encindex();
            break;
        case PM_PACK_ENCODING_US_ASCII:
            index = rb_usascii_encindex();
            break;
        case PM_PACK_ENCODING_UTF_8:
            index = rb_utf8_encindex();
            break;
        default:
            return Qnil;
    }
    return rb_enc_from_encoding(rb_enc_from_index(index));
}

/**
 * call-seq:
 *   Pack::parse(version, variant, source) -> Format
 *
 * Parse the given source and return a format object.
 */
static VALUE
pack_parse(VALUE self, VALUE version_symbol, VALUE variant_symbol, VALUE format_string) {
    if (version_symbol != v3_2_0_symbol) {
        rb_raise(rb_eArgError, "invalid version");
    }

    pm_pack_variant variant;
    if (variant_symbol == pack_symbol) {
        variant = PM_PACK_VARIANT_PACK;
    } else if (variant_symbol == unpack_symbol) {
        variant = PM_PACK_VARIANT_UNPACK;
    } else {
        rb_raise(rb_eArgError, "invalid variant");
    }

    StringValue(format_string);

    const char *format = RSTRING_PTR(format_string);
    const char *format_end = format + RSTRING_LEN(format_string);
    pm_pack_encoding encoding = PM_PACK_ENCODING_START;

    VALUE directives_array = rb_ary_new();

    while (format < format_end) {
        pm_pack_type type;
        pm_pack_signed signed_type;
        pm_pack_endian endian;
        pm_pack_size size;
        pm_pack_length_type length_type;
        uint64_t length;

        const char *directive_start = format;

        pm_pack_result parse_result = pm_pack_parse(variant, &format, format_end, &type, &signed_type, &endian,
                                                    &size, &length_type, &length, &encoding);

        const char *directive_end = format;

        switch (parse_result) {
            case PM_PACK_OK:
                break;
            case PM_PACK_ERROR_UNSUPPORTED_DIRECTIVE:
                rb_raise(rb_eArgError, "unsupported directive");
            case PM_PACK_ERROR_UNKNOWN_DIRECTIVE:
                rb_raise(rb_eArgError, "unsupported directive");
            case PM_PACK_ERROR_LENGTH_TOO_BIG:
                rb_raise(rb_eRangeError, "pack length too big");
            case PM_PACK_ERROR_BANG_NOT_ALLOWED:
                rb_raise(rb_eRangeError, "bang not allowed");
            case PM_PACK_ERROR_DOUBLE_ENDIAN:
                rb_raise(rb_eRangeError, "double endian");
            default:
                rb_bug("parse result");
        }

        if (type == PM_PACK_END) {
            break;
        }

        VALUE directive_args[9] = {
            version_symbol,
            variant_symbol,
            rb_usascii_str_new(directive_start, directive_end - directive_start),
            pack_type_to_symbol(type),
            pack_signed_to_symbol(signed_type),
            pack_endian_to_symbol(endian),
            pack_size_to_symbol(size),
            pack_length_type_to_symbol(length_type),
            UINT64T2NUM(length)
        };

        rb_ary_push(directives_array, rb_class_new_instance(9, directive_args, rb_cPrismPackDirective));
    }

    VALUE format_args[2];
    format_args[0] = directives_array;
    format_args[1] = pack_encoding_to_ruby(encoding);
    return rb_class_new_instance(2, format_args, rb_cPrismPackFormat);
}

/**
 * The function that gets called when Ruby initializes the prism extension.
 */
void
Init_prism_pack(void) {
    rb_cPrism = rb_define_module("Prism");
    rb_cPrismPack = rb_define_module_under(rb_cPrism, "Pack");
    rb_cPrismPackDirective = rb_define_class_under(rb_cPrismPack, "Directive", rb_cObject);
    rb_cPrismPackFormat = rb_define_class_under(rb_cPrismPack, "Format", rb_cObject);
    rb_define_singleton_method(rb_cPrismPack, "parse", pack_parse, 3);

    v3_2_0_symbol = ID2SYM(rb_intern("v3_2_0"));
    pack_symbol = ID2SYM(rb_intern("pack"));
    unpack_symbol = ID2SYM(rb_intern("unpack"));
}

#endif
