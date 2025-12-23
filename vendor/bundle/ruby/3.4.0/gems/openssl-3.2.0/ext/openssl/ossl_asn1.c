/*
 * 'OpenSSL for Ruby' team members
 * Copyright (C) 2003
 * All rights reserved.
 */
/*
 * This program is licensed under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#include "ossl.h"

static VALUE ossl_asn1_decode0(unsigned char **pp, long length, long *offset,
			       int depth, int yield, long *num_read);
static VALUE ossl_asn1_initialize(int argc, VALUE *argv, VALUE self);

/*
 * DATE conversion
 */
VALUE
asn1time_to_time(const ASN1_TIME *time)
{
    struct tm tm;
    VALUE argv[6];
    int count;

    memset(&tm, 0, sizeof(struct tm));

    switch (time->type) {
    case V_ASN1_UTCTIME:
	count = sscanf((const char *)time->data, "%2d%2d%2d%2d%2d%2dZ",
		&tm.tm_year, &tm.tm_mon, &tm.tm_mday, &tm.tm_hour, &tm.tm_min,
		&tm.tm_sec);

	if (count == 5) {
	    tm.tm_sec = 0;
	} else if (count != 6) {
	    ossl_raise(rb_eTypeError, "bad UTCTIME format: \"%s\"",
		    time->data);
	}
	if (tm.tm_year < 69) {
	    tm.tm_year += 2000;
	} else {
	    tm.tm_year += 1900;
	}
	break;
    case V_ASN1_GENERALIZEDTIME:
	count = sscanf((const char *)time->data, "%4d%2d%2d%2d%2d%2dZ",
		&tm.tm_year, &tm.tm_mon, &tm.tm_mday, &tm.tm_hour, &tm.tm_min,
		&tm.tm_sec);
	if (count == 5) {
		tm.tm_sec = 0;
	}
	else if (count != 6) {
		ossl_raise(rb_eTypeError, "bad GENERALIZEDTIME format: \"%s\"",
			time->data);
	}
	break;
    default:
	rb_warning("unknown time format");
        return Qnil;
    }
    argv[0] = INT2NUM(tm.tm_year);
    argv[1] = INT2NUM(tm.tm_mon);
    argv[2] = INT2NUM(tm.tm_mday);
    argv[3] = INT2NUM(tm.tm_hour);
    argv[4] = INT2NUM(tm.tm_min);
    argv[5] = INT2NUM(tm.tm_sec);

    return rb_funcall2(rb_cTime, rb_intern("utc"), 6, argv);
}

static VALUE
asn1time_to_time_i(VALUE arg)
{
    return asn1time_to_time((ASN1_TIME *)arg);
}

void
ossl_time_split(VALUE time, time_t *sec, int *days)
{
    VALUE num = rb_Integer(time);

    if (FIXNUM_P(num)) {
	time_t t = FIX2LONG(num);
	*sec = t % 86400;
	*days = rb_long2int(t / 86400);
    }
    else {
	*days = NUM2INT(rb_funcall(num, rb_intern("/"), 1, INT2FIX(86400)));
	*sec = NUM2TIMET(rb_funcall(num, rb_intern("%"), 1, INT2FIX(86400)));
    }
}

/*
 * STRING conversion
 */
VALUE
asn1str_to_str(const ASN1_STRING *str)
{
    return rb_str_new((const char *)str->data, str->length);
}

/*
 * ASN1_INTEGER conversions
 */
VALUE
asn1integer_to_num(const ASN1_INTEGER *ai)
{
    BIGNUM *bn;
    VALUE num;

    if (!ai) {
	ossl_raise(rb_eTypeError, "ASN1_INTEGER is NULL!");
    }
    if (ai->type == V_ASN1_ENUMERATED)
	/* const_cast: workaround for old OpenSSL */
	bn = ASN1_ENUMERATED_to_BN((ASN1_ENUMERATED *)ai, NULL);
    else
	bn = ASN1_INTEGER_to_BN(ai, NULL);

    if (!bn)
	ossl_raise(eOSSLError, NULL);
    num = ossl_bn_new(bn);
    BN_free(bn);

    return num;
}

ASN1_INTEGER *
num_to_asn1integer(VALUE obj, ASN1_INTEGER *ai)
{
    BIGNUM *bn;

    if (NIL_P(obj))
	ossl_raise(rb_eTypeError, "Can't convert nil into Integer");

    bn = GetBNPtr(obj);

    if (!(ai = BN_to_ASN1_INTEGER(bn, ai)))
	ossl_raise(eOSSLError, NULL);

    return ai;
}

static VALUE
asn1integer_to_num_i(VALUE arg)
{
    return asn1integer_to_num((ASN1_INTEGER *)arg);
}

/********/
/*
 * ASN1 module
 */
#define ossl_asn1_get_value(o)           rb_attr_get((o),sivVALUE)
#define ossl_asn1_get_tag(o)             rb_attr_get((o),sivTAG)
#define ossl_asn1_get_tagging(o)         rb_attr_get((o),sivTAGGING)
#define ossl_asn1_get_tag_class(o)       rb_attr_get((o),sivTAG_CLASS)
#define ossl_asn1_get_indefinite_length(o) rb_attr_get((o),sivINDEFINITE_LENGTH)

#define ossl_asn1_set_value(o,v)           rb_ivar_set((o),sivVALUE,(v))
#define ossl_asn1_set_tag(o,v)             rb_ivar_set((o),sivTAG,(v))
#define ossl_asn1_set_tagging(o,v)         rb_ivar_set((o),sivTAGGING,(v))
#define ossl_asn1_set_tag_class(o,v)       rb_ivar_set((o),sivTAG_CLASS,(v))
#define ossl_asn1_set_indefinite_length(o,v) rb_ivar_set((o),sivINDEFINITE_LENGTH,(v))

VALUE mASN1;
VALUE eASN1Error;

VALUE cASN1Data;
VALUE cASN1Primitive;
VALUE cASN1Constructive;

VALUE cASN1EndOfContent;
VALUE cASN1Boolean;                           /* BOOLEAN           */
VALUE cASN1Integer, cASN1Enumerated;          /* INTEGER           */
VALUE cASN1BitString;                         /* BIT STRING        */
VALUE cASN1OctetString, cASN1UTF8String;      /* STRINGs           */
VALUE cASN1NumericString, cASN1PrintableString;
VALUE cASN1T61String, cASN1VideotexString;
VALUE cASN1IA5String, cASN1GraphicString;
VALUE cASN1ISO64String, cASN1GeneralString;
VALUE cASN1UniversalString, cASN1BMPString;
VALUE cASN1Null;                              /* NULL              */
VALUE cASN1ObjectId;                          /* OBJECT IDENTIFIER */
VALUE cASN1UTCTime, cASN1GeneralizedTime;     /* TIME              */
VALUE cASN1Sequence, cASN1Set;                /* CONSTRUCTIVE      */

static VALUE sym_IMPLICIT, sym_EXPLICIT;
static VALUE sym_UNIVERSAL, sym_APPLICATION, sym_CONTEXT_SPECIFIC, sym_PRIVATE;
static ID sivVALUE, sivTAG, sivTAG_CLASS, sivTAGGING, sivINDEFINITE_LENGTH, sivUNUSED_BITS;
static ID id_each;

/*
 * Ruby to ASN1 converters
 */
static ASN1_BOOLEAN
obj_to_asn1bool(VALUE obj)
{
    if (NIL_P(obj))
	ossl_raise(rb_eTypeError, "Can't convert nil into Boolean");

     return RTEST(obj) ? 0xff : 0x0;
}

static ASN1_INTEGER*
obj_to_asn1int(VALUE obj)
{
    return num_to_asn1integer(obj, NULL);
}

static ASN1_BIT_STRING*
obj_to_asn1bstr(VALUE obj, long unused_bits)
{
    ASN1_BIT_STRING *bstr;

    if (unused_bits < 0 || unused_bits > 7)
	ossl_raise(eASN1Error, "unused_bits for a bitstring value must be in "\
		   "the range 0 to 7");
    StringValue(obj);
    if(!(bstr = ASN1_BIT_STRING_new()))
	ossl_raise(eASN1Error, NULL);
    ASN1_BIT_STRING_set(bstr, (unsigned char *)RSTRING_PTR(obj), RSTRING_LENINT(obj));
    bstr->flags &= ~(ASN1_STRING_FLAG_BITS_LEFT|0x07); /* clear */
    bstr->flags |= ASN1_STRING_FLAG_BITS_LEFT | unused_bits;

    return bstr;
}

static ASN1_STRING*
obj_to_asn1str(VALUE obj)
{
    ASN1_STRING *str;

    StringValue(obj);
    if(!(str = ASN1_STRING_new()))
	ossl_raise(eASN1Error, NULL);
    ASN1_STRING_set(str, RSTRING_PTR(obj), RSTRING_LENINT(obj));

    return str;
}

static ASN1_NULL*
obj_to_asn1null(VALUE obj)
{
    ASN1_NULL *null;

    if(!NIL_P(obj))
	ossl_raise(eASN1Error, "nil expected");
    if(!(null = ASN1_NULL_new()))
	ossl_raise(eASN1Error, NULL);

    return null;
}

static ASN1_OBJECT*
obj_to_asn1obj(VALUE obj)
{
    ASN1_OBJECT *a1obj;

    StringValueCStr(obj);
    a1obj = OBJ_txt2obj(RSTRING_PTR(obj), 0);
    if(!a1obj) a1obj = OBJ_txt2obj(RSTRING_PTR(obj), 1);
    if(!a1obj) ossl_raise(eASN1Error, "invalid OBJECT ID %"PRIsVALUE, obj);

    return a1obj;
}

static ASN1_UTCTIME *
obj_to_asn1utime(VALUE time)
{
    time_t sec;
    ASN1_UTCTIME *t;

    int off_days;

    ossl_time_split(time, &sec, &off_days);
    if (!(t = ASN1_UTCTIME_adj(NULL, sec, off_days, 0)))
	ossl_raise(eASN1Error, NULL);

    return t;
}

static ASN1_GENERALIZEDTIME *
obj_to_asn1gtime(VALUE time)
{
    time_t sec;
    ASN1_GENERALIZEDTIME *t;

    int off_days;

    ossl_time_split(time, &sec, &off_days);
    if (!(t = ASN1_GENERALIZEDTIME_adj(NULL, sec, off_days, 0)))
	ossl_raise(eASN1Error, NULL);

    return t;
}

static ASN1_STRING*
obj_to_asn1derstr(VALUE obj)
{
    ASN1_STRING *a1str;
    VALUE str;

    str = ossl_to_der(obj);
    if(!(a1str = ASN1_STRING_new()))
	ossl_raise(eASN1Error, NULL);
    ASN1_STRING_set(a1str, RSTRING_PTR(str), RSTRING_LENINT(str));

    return a1str;
}

/*
 * DER to Ruby converters
 */
static VALUE
decode_bool(unsigned char* der, long length)
{
    const unsigned char *p = der;

    if (length != 3)
	ossl_raise(eASN1Error, "invalid length for BOOLEAN");
    if (p[0] != 1 || p[1] != 1)
	ossl_raise(eASN1Error, "invalid BOOLEAN");

    return p[2] ? Qtrue : Qfalse;
}

static VALUE
decode_int(unsigned char* der, long length)
{
    ASN1_INTEGER *ai;
    const unsigned char *p;
    VALUE ret;
    int status = 0;

    p = der;
    if(!(ai = d2i_ASN1_INTEGER(NULL, &p, length)))
	ossl_raise(eASN1Error, NULL);
    ret = rb_protect(asn1integer_to_num_i,
		     (VALUE)ai, &status);
    ASN1_INTEGER_free(ai);
    if(status) rb_jump_tag(status);

    return ret;
}

static VALUE
decode_bstr(unsigned char* der, long length, long *unused_bits)
{
    ASN1_BIT_STRING *bstr;
    const unsigned char *p;
    long len;
    VALUE ret;

    p = der;
    if(!(bstr = d2i_ASN1_BIT_STRING(NULL, &p, length)))
	ossl_raise(eASN1Error, NULL);
    len = bstr->length;
    *unused_bits = 0;
    if(bstr->flags & ASN1_STRING_FLAG_BITS_LEFT)
	*unused_bits = bstr->flags & 0x07;
    ret = rb_str_new((const char *)bstr->data, len);
    ASN1_BIT_STRING_free(bstr);

    return ret;
}

static VALUE
decode_enum(unsigned char* der, long length)
{
    ASN1_ENUMERATED *ai;
    const unsigned char *p;
    VALUE ret;
    int status = 0;

    p = der;
    if(!(ai = d2i_ASN1_ENUMERATED(NULL, &p, length)))
	ossl_raise(eASN1Error, NULL);
    ret = rb_protect(asn1integer_to_num_i,
		     (VALUE)ai, &status);
    ASN1_ENUMERATED_free(ai);
    if(status) rb_jump_tag(status);

    return ret;
}

static VALUE
decode_null(unsigned char* der, long length)
{
    ASN1_NULL *null;
    const unsigned char *p;

    p = der;
    if(!(null = d2i_ASN1_NULL(NULL, &p, length)))
	ossl_raise(eASN1Error, NULL);
    ASN1_NULL_free(null);

    return Qnil;
}

static VALUE
decode_obj(unsigned char* der, long length)
{
    ASN1_OBJECT *obj;
    const unsigned char *p;
    VALUE ret;
    int nid;
    BIO *bio;

    p = der;
    if(!(obj = d2i_ASN1_OBJECT(NULL, &p, length)))
	ossl_raise(eASN1Error, NULL);
    if((nid = OBJ_obj2nid(obj)) != NID_undef){
	ASN1_OBJECT_free(obj);
	ret = rb_str_new2(OBJ_nid2sn(nid));
    }
    else{
	if(!(bio = BIO_new(BIO_s_mem()))){
	    ASN1_OBJECT_free(obj);
	    ossl_raise(eASN1Error, NULL);
	}
	i2a_ASN1_OBJECT(bio, obj);
	ASN1_OBJECT_free(obj);
	ret = ossl_membio2str(bio);
    }

    return ret;
}

static VALUE
decode_time(unsigned char* der, long length)
{
    ASN1_TIME *time;
    const unsigned char *p;
    VALUE ret;
    int status = 0;

    p = der;
    if(!(time = d2i_ASN1_TIME(NULL, &p, length)))
	ossl_raise(eASN1Error, NULL);
    ret = rb_protect(asn1time_to_time_i,
		     (VALUE)time, &status);
    ASN1_TIME_free(time);
    if(status) rb_jump_tag(status);

    return ret;
}

static VALUE
decode_eoc(unsigned char *der, long length)
{
    if (length != 2 || !(der[0] == 0x00 && der[1] == 0x00))
	ossl_raise(eASN1Error, NULL);

    return rb_str_new("", 0);
}

/********/

typedef struct {
    const char *name;
    VALUE *klass;
} ossl_asn1_info_t;

static const ossl_asn1_info_t ossl_asn1_info[] = {
    { "EOC",               &cASN1EndOfContent,    },  /*  0 */
    { "BOOLEAN",           &cASN1Boolean,         },  /*  1 */
    { "INTEGER",           &cASN1Integer,         },  /*  2 */
    { "BIT_STRING",        &cASN1BitString,       },  /*  3 */
    { "OCTET_STRING",      &cASN1OctetString,     },  /*  4 */
    { "NULL",              &cASN1Null,            },  /*  5 */
    { "OBJECT",            &cASN1ObjectId,        },  /*  6 */
    { "OBJECT_DESCRIPTOR", NULL,                  },  /*  7 */
    { "EXTERNAL",          NULL,                  },  /*  8 */
    { "REAL",              NULL,                  },  /*  9 */
    { "ENUMERATED",        &cASN1Enumerated,      },  /* 10 */
    { "EMBEDDED_PDV",      NULL,                  },  /* 11 */
    { "UTF8STRING",        &cASN1UTF8String,      },  /* 12 */
    { "RELATIVE_OID",      NULL,                  },  /* 13 */
    { "[UNIVERSAL 14]",    NULL,                  },  /* 14 */
    { "[UNIVERSAL 15]",    NULL,                  },  /* 15 */
    { "SEQUENCE",          &cASN1Sequence,        },  /* 16 */
    { "SET",               &cASN1Set,             },  /* 17 */
    { "NUMERICSTRING",     &cASN1NumericString,   },  /* 18 */
    { "PRINTABLESTRING",   &cASN1PrintableString, },  /* 19 */
    { "T61STRING",         &cASN1T61String,       },  /* 20 */
    { "VIDEOTEXSTRING",    &cASN1VideotexString,  },  /* 21 */
    { "IA5STRING",         &cASN1IA5String,       },  /* 22 */
    { "UTCTIME",           &cASN1UTCTime,         },  /* 23 */
    { "GENERALIZEDTIME",   &cASN1GeneralizedTime, },  /* 24 */
    { "GRAPHICSTRING",     &cASN1GraphicString,   },  /* 25 */
    { "ISO64STRING",       &cASN1ISO64String,     },  /* 26 */
    { "GENERALSTRING",     &cASN1GeneralString,   },  /* 27 */
    { "UNIVERSALSTRING",   &cASN1UniversalString, },  /* 28 */
    { "CHARACTER_STRING",  NULL,                  },  /* 29 */
    { "BMPSTRING",         &cASN1BMPString,       },  /* 30 */
};

enum {ossl_asn1_info_size = (sizeof(ossl_asn1_info)/sizeof(ossl_asn1_info[0]))};

static VALUE class_tag_map;

static int ossl_asn1_default_tag(VALUE obj);

ASN1_TYPE*
ossl_asn1_get_asn1type(VALUE obj)
{
    ASN1_TYPE *ret;
    VALUE value, rflag;
    void *ptr;
    typedef void free_func_type(void *);
    free_func_type *free_func;
    int tag;

    tag = ossl_asn1_default_tag(obj);
    value = ossl_asn1_get_value(obj);
    switch(tag){
    case V_ASN1_BOOLEAN:
	ptr = (void*)(VALUE)obj_to_asn1bool(value);
	free_func = NULL;
	break;
    case V_ASN1_INTEGER:         /* FALLTHROUGH */
    case V_ASN1_ENUMERATED:
	ptr = obj_to_asn1int(value);
	free_func = (free_func_type *)ASN1_INTEGER_free;
	break;
    case V_ASN1_BIT_STRING:
        rflag = rb_attr_get(obj, sivUNUSED_BITS);
	ptr = obj_to_asn1bstr(value, NUM2INT(rflag));
	free_func = (free_func_type *)ASN1_BIT_STRING_free;
	break;
    case V_ASN1_NULL:
	ptr = obj_to_asn1null(value);
	free_func = (free_func_type *)ASN1_NULL_free;
	break;
    case V_ASN1_OCTET_STRING:    /* FALLTHROUGH */
    case V_ASN1_UTF8STRING:      /* FALLTHROUGH */
    case V_ASN1_NUMERICSTRING:   /* FALLTHROUGH */
    case V_ASN1_PRINTABLESTRING: /* FALLTHROUGH */
    case V_ASN1_T61STRING:       /* FALLTHROUGH */
    case V_ASN1_VIDEOTEXSTRING:  /* FALLTHROUGH */
    case V_ASN1_IA5STRING:       /* FALLTHROUGH */
    case V_ASN1_GRAPHICSTRING:   /* FALLTHROUGH */
    case V_ASN1_ISO64STRING:     /* FALLTHROUGH */
    case V_ASN1_GENERALSTRING:   /* FALLTHROUGH */
    case V_ASN1_UNIVERSALSTRING: /* FALLTHROUGH */
    case V_ASN1_BMPSTRING:
	ptr = obj_to_asn1str(value);
	free_func = (free_func_type *)ASN1_STRING_free;
	break;
    case V_ASN1_OBJECT:
	ptr = obj_to_asn1obj(value);
	free_func = (free_func_type *)ASN1_OBJECT_free;
	break;
    case V_ASN1_UTCTIME:
	ptr = obj_to_asn1utime(value);
	free_func = (free_func_type *)ASN1_TIME_free;
	break;
    case V_ASN1_GENERALIZEDTIME:
	ptr = obj_to_asn1gtime(value);
	free_func = (free_func_type *)ASN1_TIME_free;
	break;
    case V_ASN1_SET:             /* FALLTHROUGH */
    case V_ASN1_SEQUENCE:
	ptr = obj_to_asn1derstr(obj);
	free_func = (free_func_type *)ASN1_STRING_free;
	break;
    default:
	ossl_raise(eASN1Error, "unsupported ASN.1 type");
    }
    if(!(ret = OPENSSL_malloc(sizeof(ASN1_TYPE)))){
	if(free_func) free_func(ptr);
	ossl_raise(eASN1Error, "ASN1_TYPE alloc failure");
    }
    memset(ret, 0, sizeof(ASN1_TYPE));
    ASN1_TYPE_set(ret, tag, ptr);

    return ret;
}

static int
ossl_asn1_default_tag(VALUE obj)
{
    VALUE tmp_class, tag;

    tmp_class = CLASS_OF(obj);
    while (!NIL_P(tmp_class)) {
	tag = rb_hash_lookup(class_tag_map, tmp_class);
	if (tag != Qnil)
	    return NUM2INT(tag);
	tmp_class = rb_class_superclass(tmp_class);
    }

    return -1;
}

static int
ossl_asn1_tag(VALUE obj)
{
    VALUE tag;

    tag = ossl_asn1_get_tag(obj);
    if(NIL_P(tag))
	ossl_raise(eASN1Error, "tag number not specified");

    return NUM2INT(tag);
}

static int
ossl_asn1_tag_class(VALUE obj)
{
    VALUE s;

    s = ossl_asn1_get_tag_class(obj);
    if (NIL_P(s) || s == sym_UNIVERSAL)
	return V_ASN1_UNIVERSAL;
    else if (s == sym_APPLICATION)
	return V_ASN1_APPLICATION;
    else if (s == sym_CONTEXT_SPECIFIC)
	return V_ASN1_CONTEXT_SPECIFIC;
    else if (s == sym_PRIVATE)
	return V_ASN1_PRIVATE;
    else
	ossl_raise(eASN1Error, "invalid tag class");
}

static VALUE
ossl_asn1_class2sym(int tc)
{
    if((tc & V_ASN1_PRIVATE) == V_ASN1_PRIVATE)
	return sym_PRIVATE;
    else if((tc & V_ASN1_CONTEXT_SPECIFIC) == V_ASN1_CONTEXT_SPECIFIC)
	return sym_CONTEXT_SPECIFIC;
    else if((tc & V_ASN1_APPLICATION) == V_ASN1_APPLICATION)
	return sym_APPLICATION;
    else
	return sym_UNIVERSAL;
}

/*
 * call-seq:
 *    OpenSSL::ASN1::ASN1Data.new(value, tag, tag_class) => ASN1Data
 *
 * _value_: Please have a look at Constructive and Primitive to see how Ruby
 * types are mapped to ASN.1 types and vice versa.
 *
 * _tag_: An Integer indicating the tag number.
 *
 * _tag_class_: A Symbol indicating the tag class. Please cf. ASN1 for
 * possible values.
 *
 * == Example
 *   asn1_int = OpenSSL::ASN1Data.new(42, 2, :UNIVERSAL) # => Same as OpenSSL::ASN1::Integer.new(42)
 *   tagged_int = OpenSSL::ASN1Data.new(42, 0, :CONTEXT_SPECIFIC) # implicitly 0-tagged INTEGER
 */
static VALUE
ossl_asn1data_initialize(VALUE self, VALUE value, VALUE tag, VALUE tag_class)
{
    if(!SYMBOL_P(tag_class))
	ossl_raise(eASN1Error, "invalid tag class");
    ossl_asn1_set_tag(self, tag);
    ossl_asn1_set_value(self, value);
    ossl_asn1_set_tag_class(self, tag_class);
    ossl_asn1_set_indefinite_length(self, Qfalse);

    return self;
}

static VALUE
to_der_internal(VALUE self, int constructed, int indef_len, VALUE body)
{
    int encoding = constructed ? indef_len ? 2 : 1 : 0;
    int tag_class = ossl_asn1_tag_class(self);
    int tag_number = ossl_asn1_tag(self);
    int default_tag_number = ossl_asn1_default_tag(self);
    int body_length, total_length;
    VALUE str;
    unsigned char *p;

    body_length = RSTRING_LENINT(body);
    if (ossl_asn1_get_tagging(self) == sym_EXPLICIT) {
	int inner_length, e_encoding = indef_len ? 2 : 1;

	if (default_tag_number == -1)
	    ossl_raise(eASN1Error, "explicit tagging of unknown tag");

	inner_length = ASN1_object_size(encoding, body_length, default_tag_number);
	total_length = ASN1_object_size(e_encoding, inner_length, tag_number);
	str = rb_str_new(NULL, total_length);
	p = (unsigned char *)RSTRING_PTR(str);
	/* Put explicit tag */
	ASN1_put_object(&p, e_encoding, inner_length, tag_number, tag_class);
	/* Append inner object */
	ASN1_put_object(&p, encoding, body_length, default_tag_number, V_ASN1_UNIVERSAL);
	memcpy(p, RSTRING_PTR(body), body_length);
	p += body_length;
	if (indef_len) {
	    ASN1_put_eoc(&p); /* For inner object */
	    ASN1_put_eoc(&p); /* For wrapper object */
	}
    }
    else {
	total_length = ASN1_object_size(encoding, body_length, tag_number);
	str = rb_str_new(NULL, total_length);
	p = (unsigned char *)RSTRING_PTR(str);
	ASN1_put_object(&p, encoding, body_length, tag_number, tag_class);
	memcpy(p, RSTRING_PTR(body), body_length);
	p += body_length;
	if (indef_len)
	    ASN1_put_eoc(&p);
    }
    assert(p - (unsigned char *)RSTRING_PTR(str) == total_length);
    return str;
}

static VALUE ossl_asn1prim_to_der(VALUE);
static VALUE ossl_asn1cons_to_der(VALUE);
/*
 * call-seq:
 *    asn1.to_der => DER-encoded String
 *
 * Encodes this ASN1Data into a DER-encoded String value. The result is
 * DER-encoded except for the possibility of indefinite length forms.
 * Indefinite length forms are not allowed in strict DER, so strictly speaking
 * the result of such an encoding would be a BER-encoding.
 */
static VALUE
ossl_asn1data_to_der(VALUE self)
{
    VALUE value = ossl_asn1_get_value(self);

    if (rb_obj_is_kind_of(value, rb_cArray))
	return ossl_asn1cons_to_der(self);
    else {
	if (RTEST(ossl_asn1_get_indefinite_length(self)))
	    ossl_raise(eASN1Error, "indefinite length form cannot be used " \
		       "with primitive encoding");
	return ossl_asn1prim_to_der(self);
    }
}

static VALUE
int_ossl_asn1_decode0_prim(unsigned char **pp, long length, long hlen, int tag,
			   VALUE tc, long *num_read)
{
    VALUE value, asn1data;
    unsigned char *p;
    long flag = 0;

    p = *pp;

    if(tc == sym_UNIVERSAL && tag < ossl_asn1_info_size) {
	switch(tag){
	case V_ASN1_EOC:
	    value = decode_eoc(p, hlen+length);
	    break;
	case V_ASN1_BOOLEAN:
	    value = decode_bool(p, hlen+length);
	    break;
	case V_ASN1_INTEGER:
	    value = decode_int(p, hlen+length);
	    break;
	case V_ASN1_BIT_STRING:
	    value = decode_bstr(p, hlen+length, &flag);
	    break;
	case V_ASN1_NULL:
	    value = decode_null(p, hlen+length);
	    break;
	case V_ASN1_ENUMERATED:
	    value = decode_enum(p, hlen+length);
	    break;
	case V_ASN1_OBJECT:
	    value = decode_obj(p, hlen+length);
	    break;
	case V_ASN1_UTCTIME:           /* FALLTHROUGH */
	case V_ASN1_GENERALIZEDTIME:
	    value = decode_time(p, hlen+length);
	    break;
	default:
	    /* use original value */
	    p += hlen;
	    value = rb_str_new((const char *)p, length);
	    break;
	}
    }
    else {
	p += hlen;
	value = rb_str_new((const char *)p, length);
    }

    *pp += hlen + length;
    *num_read = hlen + length;

    if (tc == sym_UNIVERSAL &&
	tag < ossl_asn1_info_size && ossl_asn1_info[tag].klass) {
	VALUE klass = *ossl_asn1_info[tag].klass;
	VALUE args[4];
	args[0] = value;
	args[1] = INT2NUM(tag);
	args[2] = Qnil;
	args[3] = tc;
	asn1data = rb_obj_alloc(klass);
	ossl_asn1_initialize(4, args, asn1data);
	if(tag == V_ASN1_BIT_STRING){
	    rb_ivar_set(asn1data, sivUNUSED_BITS, LONG2NUM(flag));
	}
    }
    else {
	asn1data = rb_obj_alloc(cASN1Data);
	ossl_asn1data_initialize(asn1data, value, INT2NUM(tag), tc);
    }

    return asn1data;
}

static VALUE
int_ossl_asn1_decode0_cons(unsigned char **pp, long max_len, long length,
			   long *offset, int depth, int yield, int j,
			   int tag, VALUE tc, long *num_read)
{
    VALUE value, asn1data, ary;
    int indefinite;
    long available_len, off = *offset;

    indefinite = (j == 0x21);
    ary = rb_ary_new();

    available_len = indefinite ? max_len : length;
    while (available_len > 0) {
	long inner_read = 0;
	value = ossl_asn1_decode0(pp, available_len, &off, depth + 1, yield, &inner_read);
	*num_read += inner_read;
	available_len -= inner_read;

	if (indefinite &&
	    ossl_asn1_tag(value) == V_ASN1_EOC &&
	    ossl_asn1_get_tag_class(value) == sym_UNIVERSAL) {
	    break;
	}
	rb_ary_push(ary, value);
    }

    if (tc == sym_UNIVERSAL) {
	VALUE args[4];
	if (tag == V_ASN1_SEQUENCE || tag == V_ASN1_SET)
	    asn1data = rb_obj_alloc(*ossl_asn1_info[tag].klass);
	else
	    asn1data = rb_obj_alloc(cASN1Constructive);
	args[0] = ary;
	args[1] = INT2NUM(tag);
	args[2] = Qnil;
	args[3] = tc;
	ossl_asn1_initialize(4, args, asn1data);
    }
    else {
	asn1data = rb_obj_alloc(cASN1Data);
	ossl_asn1data_initialize(asn1data, ary, INT2NUM(tag), tc);
    }

    if (indefinite)
	ossl_asn1_set_indefinite_length(asn1data, Qtrue);
    else
	ossl_asn1_set_indefinite_length(asn1data, Qfalse);

    *offset = off;
    return asn1data;
}

static VALUE
ossl_asn1_decode0(unsigned char **pp, long length, long *offset, int depth,
		  int yield, long *num_read)
{
    unsigned char *start, *p;
    const unsigned char *p0;
    long len = 0, inner_read = 0, off = *offset, hlen;
    int tag, tc, j;
    VALUE asn1data, tag_class;

    p = *pp;
    start = p;
    p0 = p;
    j = ASN1_get_object(&p0, &len, &tag, &tc, length);
    p = (unsigned char *)p0;
    if(j & 0x80) ossl_raise(eASN1Error, NULL);
    if(len > length) ossl_raise(eASN1Error, "value is too short");
    if((tc & V_ASN1_PRIVATE) == V_ASN1_PRIVATE)
	tag_class = sym_PRIVATE;
    else if((tc & V_ASN1_CONTEXT_SPECIFIC) == V_ASN1_CONTEXT_SPECIFIC)
	tag_class = sym_CONTEXT_SPECIFIC;
    else if((tc & V_ASN1_APPLICATION) == V_ASN1_APPLICATION)
	tag_class = sym_APPLICATION;
    else
	tag_class = sym_UNIVERSAL;

    hlen = p - start;

    if(yield) {
	VALUE arg = rb_ary_new();
	rb_ary_push(arg, LONG2NUM(depth));
	rb_ary_push(arg, LONG2NUM(*offset));
	rb_ary_push(arg, LONG2NUM(hlen));
	rb_ary_push(arg, LONG2NUM(len));
	rb_ary_push(arg, (j & V_ASN1_CONSTRUCTED) ? Qtrue : Qfalse);
	rb_ary_push(arg, ossl_asn1_class2sym(tc));
	rb_ary_push(arg, INT2NUM(tag));
	rb_yield(arg);
    }

    if(j & V_ASN1_CONSTRUCTED) {
	*pp += hlen;
	off += hlen;
	asn1data = int_ossl_asn1_decode0_cons(pp, length - hlen, len, &off, depth, yield, j, tag, tag_class, &inner_read);
	inner_read += hlen;
    }
    else {
	if ((j & 0x01) && (len == 0))
	    ossl_raise(eASN1Error, "indefinite length for primitive value");
	asn1data = int_ossl_asn1_decode0_prim(pp, len, hlen, tag, tag_class, &inner_read);
	off += hlen + len;
    }
    if (num_read)
	*num_read = inner_read;
    if (len != 0 && inner_read != hlen + len) {
	ossl_raise(eASN1Error,
		   "Type mismatch. Bytes read: %ld Bytes available: %ld",
		   inner_read, hlen + len);
    }

    *offset = off;
    return asn1data;
}

static void
int_ossl_decode_sanity_check(long len, long read, long offset)
{
    if (len != 0 && (read != len || offset != len)) {
	ossl_raise(eASN1Error,
		   "Type mismatch. Total bytes read: %ld Bytes available: %ld Offset: %ld",
		   read, len, offset);
    }
}

/*
 * call-seq:
 *    OpenSSL::ASN1.traverse(asn1) -> nil
 *
 * If a block is given, it prints out each of the elements encountered.
 * Block parameters are (in that order):
 * * depth: The recursion depth, plus one with each constructed value being encountered (Integer)
 * * offset: Current byte offset (Integer)
 * * header length: Combined length in bytes of the Tag and Length headers. (Integer)
 * * length: The overall remaining length of the entire data (Integer)
 * * constructed: Whether this value is constructed or not (Boolean)
 * * tag_class: Current tag class (Symbol)
 * * tag: The current tag number (Integer)
 *
 * == Example
 *   der = File.binread('asn1data.der')
 *   OpenSSL::ASN1.traverse(der) do | depth, offset, header_len, length, constructed, tag_class, tag|
 *     puts "Depth: #{depth} Offset: #{offset} Length: #{length}"
 *     puts "Header length: #{header_len} Tag: #{tag} Tag class: #{tag_class} Constructed: #{constructed}"
 *   end
 */
static VALUE
ossl_asn1_traverse(VALUE self, VALUE obj)
{
    unsigned char *p;
    VALUE tmp;
    long len, read = 0, offset = 0;

    obj = ossl_to_der_if_possible(obj);
    tmp = rb_str_new4(StringValue(obj));
    p = (unsigned char *)RSTRING_PTR(tmp);
    len = RSTRING_LEN(tmp);
    ossl_asn1_decode0(&p, len, &offset, 0, 1, &read);
    RB_GC_GUARD(tmp);
    int_ossl_decode_sanity_check(len, read, offset);
    return Qnil;
}

/*
 * call-seq:
 *    OpenSSL::ASN1.decode(der) -> ASN1Data
 *
 * Decodes a BER- or DER-encoded value and creates an ASN1Data instance. _der_
 * may be a String or any object that features a +.to_der+ method transforming
 * it into a BER-/DER-encoded String+
 *
 * == Example
 *   der = File.binread('asn1data')
 *   asn1 = OpenSSL::ASN1.decode(der)
 */
static VALUE
ossl_asn1_decode(VALUE self, VALUE obj)
{
    VALUE ret;
    unsigned char *p;
    VALUE tmp;
    long len, read = 0, offset = 0;

    obj = ossl_to_der_if_possible(obj);
    tmp = rb_str_new4(StringValue(obj));
    p = (unsigned char *)RSTRING_PTR(tmp);
    len = RSTRING_LEN(tmp);
    ret = ossl_asn1_decode0(&p, len, &offset, 0, 0, &read);
    RB_GC_GUARD(tmp);
    int_ossl_decode_sanity_check(len, read, offset);
    return ret;
}

/*
 * call-seq:
 *    OpenSSL::ASN1.decode_all(der) -> Array of ASN1Data
 *
 * Similar to #decode with the difference that #decode expects one
 * distinct value represented in _der_. #decode_all on the contrary
 * decodes a sequence of sequential BER/DER values lined up in _der_
 * and returns them as an array.
 *
 * == Example
 *   ders = File.binread('asn1data_seq')
 *   asn1_ary = OpenSSL::ASN1.decode_all(ders)
 */
static VALUE
ossl_asn1_decode_all(VALUE self, VALUE obj)
{
    VALUE ary, val;
    unsigned char *p;
    long len, tmp_len = 0, read = 0, offset = 0;
    VALUE tmp;

    obj = ossl_to_der_if_possible(obj);
    tmp = rb_str_new4(StringValue(obj));
    p = (unsigned char *)RSTRING_PTR(tmp);
    len = RSTRING_LEN(tmp);
    tmp_len = len;
    ary = rb_ary_new();
    while (tmp_len > 0) {
	long tmp_read = 0;
	val = ossl_asn1_decode0(&p, tmp_len, &offset, 0, 0, &tmp_read);
	rb_ary_push(ary, val);
	read += tmp_read;
	tmp_len -= tmp_read;
    }
    RB_GC_GUARD(tmp);
    int_ossl_decode_sanity_check(len, read, offset);
    return ary;
}

/*
 * call-seq:
 *    OpenSSL::ASN1::Primitive.new(value [, tag, tagging, tag_class ]) => Primitive
 *
 * _value_: is mandatory.
 *
 * _tag_: optional, may be specified for tagged values. If no _tag_ is
 * specified, the UNIVERSAL tag corresponding to the Primitive sub-class
 * is used by default.
 *
 * _tagging_: may be used as an encoding hint to encode a value either
 * explicitly or implicitly, see ASN1 for possible values.
 *
 * _tag_class_: if _tag_ and _tagging_ are +nil+ then this is set to
 * +:UNIVERSAL+ by default. If either _tag_ or _tagging_ are set then
 * +:CONTEXT_SPECIFIC+ is used as the default. For possible values please
 * cf. ASN1.
 *
 * == Example
 *   int = OpenSSL::ASN1::Integer.new(42)
 *   zero_tagged_int = OpenSSL::ASN1::Integer.new(42, 0, :IMPLICIT)
 *   private_explicit_zero_tagged_int = OpenSSL::ASN1::Integer.new(42, 0, :EXPLICIT, :PRIVATE)
 */
static VALUE
ossl_asn1_initialize(int argc, VALUE *argv, VALUE self)
{
    VALUE value, tag, tagging, tag_class;
    int default_tag;

    rb_scan_args(argc, argv, "13", &value, &tag, &tagging, &tag_class);
    default_tag = ossl_asn1_default_tag(self);

    if (default_tag == -1 || argc > 1) {
	if(NIL_P(tag))
	    ossl_raise(eASN1Error, "must specify tag number");
	if(!NIL_P(tagging) && !SYMBOL_P(tagging))
	    ossl_raise(eASN1Error, "invalid tagging method");
	if(NIL_P(tag_class)) {
	    if (NIL_P(tagging))
		tag_class = sym_UNIVERSAL;
	    else
		tag_class = sym_CONTEXT_SPECIFIC;
	}
	if(!SYMBOL_P(tag_class))
	    ossl_raise(eASN1Error, "invalid tag class");
    }
    else{
	tag = INT2NUM(default_tag);
	tagging = Qnil;
	tag_class = sym_UNIVERSAL;
    }
    ossl_asn1_set_tag(self, tag);
    ossl_asn1_set_value(self, value);
    ossl_asn1_set_tagging(self, tagging);
    ossl_asn1_set_tag_class(self, tag_class);
    ossl_asn1_set_indefinite_length(self, Qfalse);
    if (default_tag == V_ASN1_BIT_STRING)
	rb_ivar_set(self, sivUNUSED_BITS, INT2FIX(0));

    return self;
}

static VALUE
ossl_asn1eoc_initialize(VALUE self) {
    VALUE tag, tagging, tag_class, value;
    tag = INT2FIX(0);
    tagging = Qnil;
    tag_class = sym_UNIVERSAL;
    value = rb_str_new("", 0);
    ossl_asn1_set_tag(self, tag);
    ossl_asn1_set_value(self, value);
    ossl_asn1_set_tagging(self, tagging);
    ossl_asn1_set_tag_class(self, tag_class);
    ossl_asn1_set_indefinite_length(self, Qfalse);
    return self;
}

static VALUE
ossl_asn1eoc_to_der(VALUE self)
{
    return rb_str_new("\0\0", 2);
}

/*
 * call-seq:
 *    asn1.to_der => DER-encoded String
 *
 * See ASN1Data#to_der for details.
 */
static VALUE
ossl_asn1prim_to_der(VALUE self)
{
    ASN1_TYPE *asn1;
    long alllen, bodylen;
    unsigned char *p0, *p1;
    int j, tag, tc, state;
    VALUE str;

    if (ossl_asn1_default_tag(self) == -1) {
	str = ossl_asn1_get_value(self);
	return to_der_internal(self, 0, 0, StringValue(str));
    }

    asn1 = ossl_asn1_get_asn1type(self);
    alllen = i2d_ASN1_TYPE(asn1, NULL);
    if (alllen < 0) {
	ASN1_TYPE_free(asn1);
	ossl_raise(eASN1Error, "i2d_ASN1_TYPE");
    }
    str = ossl_str_new(NULL, alllen, &state);
    if (state) {
	ASN1_TYPE_free(asn1);
	rb_jump_tag(state);
    }
    p0 = p1 = (unsigned char *)RSTRING_PTR(str);
    i2d_ASN1_TYPE(asn1, &p0);
    ASN1_TYPE_free(asn1);
    assert(p0 - p1 == alllen);

    /* Strip header since to_der_internal() wants only the payload */
    j = ASN1_get_object((const unsigned char **)&p1, &bodylen, &tag, &tc, alllen);
    if (j & 0x80)
	ossl_raise(eASN1Error, "ASN1_get_object"); /* should not happen */

    return to_der_internal(self, 0, 0, rb_str_drop_bytes(str, alllen - bodylen));
}

/*
 * call-seq:
 *    asn1.to_der => DER-encoded String
 *
 * See ASN1Data#to_der for details.
 */
static VALUE
ossl_asn1cons_to_der(VALUE self)
{
    VALUE ary, str;
    long i;
    int indef_len;

    indef_len = RTEST(ossl_asn1_get_indefinite_length(self));
    ary = rb_convert_type(ossl_asn1_get_value(self), T_ARRAY, "Array", "to_a");
    str = rb_str_new(NULL, 0);
    for (i = 0; i < RARRAY_LEN(ary); i++) {
	VALUE item = RARRAY_AREF(ary, i);

	if (indef_len && rb_obj_is_kind_of(item, cASN1EndOfContent)) {
	    if (i != RARRAY_LEN(ary) - 1)
		ossl_raise(eASN1Error, "illegal EOC octets in value");

	    /*
	     * EOC is not really part of the content, but we required to add one
	     * at the end in the past.
	     */
	    break;
	}

	item = ossl_to_der_if_possible(item);
	StringValue(item);
	rb_str_append(str, item);
    }

    return to_der_internal(self, 1, indef_len, str);
}

/*
 * call-seq:
 *    asn1_ary.each { |asn1| block } => asn1_ary
 *
 * Calls the given block once for each element in self, passing that element
 * as parameter _asn1_. If no block is given, an enumerator is returned
 * instead.
 *
 * == Example
 *   asn1_ary.each do |asn1|
 *     puts asn1
 *   end
 */
static VALUE
ossl_asn1cons_each(VALUE self)
{
    rb_block_call(ossl_asn1_get_value(self), id_each, 0, 0, 0, 0);

    return self;
}

/*
 * call-seq:
 *    OpenSSL::ASN1::ObjectId.register(object_id, short_name, long_name)
 *
 * This adds a new ObjectId to the internal tables. Where _object_id_ is the
 * numerical form, _short_name_ is the short name, and _long_name_ is the long
 * name.
 *
 * Returns +true+ if successful. Raises an OpenSSL::ASN1::ASN1Error if it fails.
 *
 */
static VALUE
ossl_asn1obj_s_register(VALUE self, VALUE oid, VALUE sn, VALUE ln)
{
    StringValueCStr(oid);
    StringValueCStr(sn);
    StringValueCStr(ln);

    if(!OBJ_create(RSTRING_PTR(oid), RSTRING_PTR(sn), RSTRING_PTR(ln)))
	ossl_raise(eASN1Error, NULL);

    return Qtrue;
}

/*
 * call-seq:
 *    oid.sn -> string
 *    oid.short_name -> string
 *
 * The short name of the ObjectId, as defined in <openssl/objects.h>.
 */
static VALUE
ossl_asn1obj_get_sn(VALUE self)
{
    VALUE val, ret = Qnil;
    int nid;

    val = ossl_asn1_get_value(self);
    if ((nid = OBJ_txt2nid(StringValueCStr(val))) != NID_undef)
	ret = rb_str_new2(OBJ_nid2sn(nid));

    return ret;
}

/*
 * call-seq:
 *    oid.ln -> string
 *    oid.long_name -> string
 *
 * The long name of the ObjectId, as defined in <openssl/objects.h>.
 */
static VALUE
ossl_asn1obj_get_ln(VALUE self)
{
    VALUE val, ret = Qnil;
    int nid;

    val = ossl_asn1_get_value(self);
    if ((nid = OBJ_txt2nid(StringValueCStr(val))) != NID_undef)
	ret = rb_str_new2(OBJ_nid2ln(nid));

    return ret;
}

/*
 *  call-seq:
 *     oid == other_oid => true or false
 *
 *  Returns +true+ if _other_oid_ is the same as _oid_
 */
static VALUE
ossl_asn1obj_eq(VALUE self, VALUE other)
{
    VALUE valSelf, valOther;
    int nidSelf, nidOther;

    valSelf = ossl_asn1_get_value(self);
    valOther = ossl_asn1_get_value(other);

    if ((nidSelf = OBJ_txt2nid(StringValueCStr(valSelf))) == NID_undef)
	ossl_raise(eASN1Error, "OBJ_txt2nid");

    if ((nidOther = OBJ_txt2nid(StringValueCStr(valOther))) == NID_undef)
	ossl_raise(eASN1Error, "OBJ_txt2nid");

    return nidSelf == nidOther ? Qtrue : Qfalse;
}

static VALUE
asn1obj_get_oid_i(VALUE vobj)
{
    ASN1_OBJECT *a1obj = (void *)vobj;
    VALUE str;
    int len;

    str = rb_usascii_str_new(NULL, 127);
    len = OBJ_obj2txt(RSTRING_PTR(str), RSTRING_LENINT(str), a1obj, 1);
    if (len <= 0 || len == INT_MAX)
	ossl_raise(eASN1Error, "OBJ_obj2txt");
    if (len > RSTRING_LEN(str)) {
	/* +1 is for the \0 terminator added by OBJ_obj2txt() */
	rb_str_resize(str, len + 1);
	len = OBJ_obj2txt(RSTRING_PTR(str), len + 1, a1obj, 1);
	if (len <= 0)
	    ossl_raise(eASN1Error, "OBJ_obj2txt");
    }
    rb_str_set_len(str, len);
    return str;
}

/*
 * call-seq:
 *    oid.oid -> string
 *
 * Returns a String representing the Object Identifier in the dot notation,
 * e.g. "1.2.3.4.5"
 */
static VALUE
ossl_asn1obj_get_oid(VALUE self)
{
    VALUE str;
    ASN1_OBJECT *a1obj;
    int state;

    a1obj = obj_to_asn1obj(ossl_asn1_get_value(self));
    str = rb_protect(asn1obj_get_oid_i, (VALUE)a1obj, &state);
    ASN1_OBJECT_free(a1obj);
    if (state)
	rb_jump_tag(state);
    return str;
}

#define OSSL_ASN1_IMPL_FACTORY_METHOD(klass) \
static VALUE ossl_asn1_##klass(int argc, VALUE *argv, VALUE self)\
{ return rb_funcall3(cASN1##klass, rb_intern("new"), argc, argv); }

OSSL_ASN1_IMPL_FACTORY_METHOD(Boolean)
OSSL_ASN1_IMPL_FACTORY_METHOD(Integer)
OSSL_ASN1_IMPL_FACTORY_METHOD(Enumerated)
OSSL_ASN1_IMPL_FACTORY_METHOD(BitString)
OSSL_ASN1_IMPL_FACTORY_METHOD(OctetString)
OSSL_ASN1_IMPL_FACTORY_METHOD(UTF8String)
OSSL_ASN1_IMPL_FACTORY_METHOD(NumericString)
OSSL_ASN1_IMPL_FACTORY_METHOD(PrintableString)
OSSL_ASN1_IMPL_FACTORY_METHOD(T61String)
OSSL_ASN1_IMPL_FACTORY_METHOD(VideotexString)
OSSL_ASN1_IMPL_FACTORY_METHOD(IA5String)
OSSL_ASN1_IMPL_FACTORY_METHOD(GraphicString)
OSSL_ASN1_IMPL_FACTORY_METHOD(ISO64String)
OSSL_ASN1_IMPL_FACTORY_METHOD(GeneralString)
OSSL_ASN1_IMPL_FACTORY_METHOD(UniversalString)
OSSL_ASN1_IMPL_FACTORY_METHOD(BMPString)
OSSL_ASN1_IMPL_FACTORY_METHOD(Null)
OSSL_ASN1_IMPL_FACTORY_METHOD(ObjectId)
OSSL_ASN1_IMPL_FACTORY_METHOD(UTCTime)
OSSL_ASN1_IMPL_FACTORY_METHOD(GeneralizedTime)
OSSL_ASN1_IMPL_FACTORY_METHOD(Sequence)
OSSL_ASN1_IMPL_FACTORY_METHOD(Set)
OSSL_ASN1_IMPL_FACTORY_METHOD(EndOfContent)

void
Init_ossl_asn1(void)
{
#undef rb_intern
    VALUE ary;
    int i;

#if 0
    mOSSL = rb_define_module("OpenSSL");
    eOSSLError = rb_define_class_under(mOSSL, "OpenSSLError", rb_eStandardError);
#endif

    sym_UNIVERSAL = ID2SYM(rb_intern_const("UNIVERSAL"));
    sym_CONTEXT_SPECIFIC = ID2SYM(rb_intern_const("CONTEXT_SPECIFIC"));
    sym_APPLICATION = ID2SYM(rb_intern_const("APPLICATION"));
    sym_PRIVATE = ID2SYM(rb_intern_const("PRIVATE"));
    sym_EXPLICIT = ID2SYM(rb_intern_const("EXPLICIT"));
    sym_IMPLICIT = ID2SYM(rb_intern_const("IMPLICIT"));

    sivVALUE = rb_intern("@value");
    sivTAG = rb_intern("@tag");
    sivTAGGING = rb_intern("@tagging");
    sivTAG_CLASS = rb_intern("@tag_class");
    sivINDEFINITE_LENGTH = rb_intern("@indefinite_length");
    sivUNUSED_BITS = rb_intern("@unused_bits");

    /*
     * Document-module: OpenSSL::ASN1
     *
     * Abstract Syntax Notation One (or ASN.1) is a notation syntax to
     * describe data structures and is defined in ITU-T X.680. ASN.1 itself
     * does not mandate any encoding or parsing rules, but usually ASN.1 data
     * structures are encoded using the Distinguished Encoding Rules (DER) or
     * less often the Basic Encoding Rules (BER) described in ITU-T X.690. DER
     * and BER encodings are binary Tag-Length-Value (TLV) encodings that are
     * quite concise compared to other popular data description formats such
     * as XML, JSON etc.
     * ASN.1 data structures are very common in cryptographic applications,
     * e.g. X.509 public key certificates or certificate revocation lists
     * (CRLs) are all defined in ASN.1 and DER-encoded. ASN.1, DER and BER are
     * the building blocks of applied cryptography.
     * The ASN1 module provides the necessary classes that allow generation
     * of ASN.1 data structures and the methods to encode them using a DER
     * encoding. The decode method allows parsing arbitrary BER-/DER-encoded
     * data to a Ruby object that can then be modified and re-encoded at will.
     *
     * == ASN.1 class hierarchy
     *
     * The base class representing ASN.1 structures is ASN1Data. ASN1Data offers
     * attributes to read and set the _tag_, the _tag_class_ and finally the
     * _value_ of a particular ASN.1 item. Upon parsing, any tagged values
     * (implicit or explicit) will be represented by ASN1Data instances because
     * their "real type" can only be determined using out-of-band information
     * from the ASN.1 type declaration. Since this information is normally
     * known when encoding a type, all sub-classes of ASN1Data offer an
     * additional attribute _tagging_ that allows to encode a value implicitly
     * (+:IMPLICIT+) or explicitly (+:EXPLICIT+).
     *
     * === Constructive
     *
     * Constructive is, as its name implies, the base class for all
     * constructed encodings, i.e. those that consist of several values,
     * opposed to "primitive" encodings with just one single value. The value of
     * an Constructive is always an Array.
     *
     * ==== ASN1::Set and ASN1::Sequence
     *
     * The most common constructive encodings are SETs and SEQUENCEs, which is
     * why there are two sub-classes of Constructive representing each of
     * them.
     *
     * === Primitive
     *
     * This is the super class of all primitive values. Primitive
     * itself is not used when parsing ASN.1 data, all values are either
     * instances of a corresponding sub-class of Primitive or they are
     * instances of ASN1Data if the value was tagged implicitly or explicitly.
     * Please cf. Primitive documentation for details on sub-classes and
     * their respective mappings of ASN.1 data types to Ruby objects.
     *
     * == Possible values for _tagging_
     *
     * When constructing an ASN1Data object the ASN.1 type definition may
     * require certain elements to be either implicitly or explicitly tagged.
     * This can be achieved by setting the _tagging_ attribute manually for
     * sub-classes of ASN1Data. Use the symbol +:IMPLICIT+ for implicit
     * tagging and +:EXPLICIT+ if the element requires explicit tagging.
     *
     * == Possible values for _tag_class_
     *
     * It is possible to create arbitrary ASN1Data objects that also support
     * a PRIVATE or APPLICATION tag class. Possible values for the _tag_class_
     * attribute are:
     * * +:UNIVERSAL+ (the default for untagged values)
     * * +:CONTEXT_SPECIFIC+ (the default for tagged values)
     * * +:APPLICATION+
     * * +:PRIVATE+
     *
     * == Tag constants
     *
     * There is a constant defined for each universal tag:
     * * OpenSSL::ASN1::EOC (0)
     * * OpenSSL::ASN1::BOOLEAN (1)
     * * OpenSSL::ASN1::INTEGER (2)
     * * OpenSSL::ASN1::BIT_STRING (3)
     * * OpenSSL::ASN1::OCTET_STRING (4)
     * * OpenSSL::ASN1::NULL (5)
     * * OpenSSL::ASN1::OBJECT (6)
     * * OpenSSL::ASN1::ENUMERATED (10)
     * * OpenSSL::ASN1::UTF8STRING (12)
     * * OpenSSL::ASN1::SEQUENCE (16)
     * * OpenSSL::ASN1::SET (17)
     * * OpenSSL::ASN1::NUMERICSTRING (18)
     * * OpenSSL::ASN1::PRINTABLESTRING (19)
     * * OpenSSL::ASN1::T61STRING (20)
     * * OpenSSL::ASN1::VIDEOTEXSTRING (21)
     * * OpenSSL::ASN1::IA5STRING (22)
     * * OpenSSL::ASN1::UTCTIME (23)
     * * OpenSSL::ASN1::GENERALIZEDTIME (24)
     * * OpenSSL::ASN1::GRAPHICSTRING (25)
     * * OpenSSL::ASN1::ISO64STRING (26)
     * * OpenSSL::ASN1::GENERALSTRING (27)
     * * OpenSSL::ASN1::UNIVERSALSTRING (28)
     * * OpenSSL::ASN1::BMPSTRING (30)
     *
     * == UNIVERSAL_TAG_NAME constant
     *
     * An Array that stores the name of a given tag number. These names are
     * the same as the name of the tag constant that is additionally defined,
     * e.g. <tt>UNIVERSAL_TAG_NAME[2] = "INTEGER"</tt> and <tt>OpenSSL::ASN1::INTEGER = 2</tt>.
     *
     * == Example usage
     *
     * === Decoding and viewing a DER-encoded file
     *   require 'openssl'
     *   require 'pp'
     *   der = File.binread('data.der')
     *   asn1 = OpenSSL::ASN1.decode(der)
     *   pp der
     *
     * === Creating an ASN.1 structure and DER-encoding it
     *   require 'openssl'
     *   version = OpenSSL::ASN1::Integer.new(1)
     *   # Explicitly 0-tagged implies context-specific tag class
     *   serial = OpenSSL::ASN1::Integer.new(12345, 0, :EXPLICIT, :CONTEXT_SPECIFIC)
     *   name = OpenSSL::ASN1::PrintableString.new('Data 1')
     *   sequence = OpenSSL::ASN1::Sequence.new( [ version, serial, name ] )
     *   der = sequence.to_der
     */
    mASN1 = rb_define_module_under(mOSSL, "ASN1");

    /* Document-class: OpenSSL::ASN1::ASN1Error
     *
     * Generic error class for all errors raised in ASN1 and any of the
     * classes defined in it.
     */
    eASN1Error = rb_define_class_under(mASN1, "ASN1Error", eOSSLError);
    rb_define_module_function(mASN1, "traverse", ossl_asn1_traverse, 1);
    rb_define_module_function(mASN1, "decode", ossl_asn1_decode, 1);
    rb_define_module_function(mASN1, "decode_all", ossl_asn1_decode_all, 1);
    ary = rb_ary_new();

    /*
     * Array storing tag names at the tag's index.
     */
    rb_define_const(mASN1, "UNIVERSAL_TAG_NAME", ary);
    for(i = 0; i < ossl_asn1_info_size; i++){
	if(ossl_asn1_info[i].name[0] == '[') continue;
	rb_define_const(mASN1, ossl_asn1_info[i].name, INT2NUM(i));
	rb_ary_store(ary, i, rb_str_new2(ossl_asn1_info[i].name));
    }

    /* Document-class: OpenSSL::ASN1::ASN1Data
     *
     * The top-level class representing any ASN.1 object. When parsed by
     * ASN1.decode, tagged values are always represented by an instance
     * of ASN1Data.
     *
     * == The role of ASN1Data for parsing tagged values
     *
     * When encoding an ASN.1 type it is inherently clear what original
     * type (e.g. INTEGER, OCTET STRING etc.) this value has, regardless
     * of its tagging.
     * But opposed to the time an ASN.1 type is to be encoded, when parsing
     * them it is not possible to deduce the "real type" of tagged
     * values. This is why tagged values are generally parsed into ASN1Data
     * instances, but with a different outcome for implicit and explicit
     * tagging.
     *
     * === Example of a parsed implicitly tagged value
     *
     * An implicitly 1-tagged INTEGER value will be parsed as an
     * ASN1Data with
     * * _tag_ equal to 1
     * * _tag_class_ equal to +:CONTEXT_SPECIFIC+
     * * _value_ equal to a String that carries the raw encoding
     *   of the INTEGER.
     * This implies that a subsequent decoding step is required to
     * completely decode implicitly tagged values.
     *
     * === Example of a parsed explicitly tagged value
     *
     * An explicitly 1-tagged INTEGER value will be parsed as an
     * ASN1Data with
     * * _tag_ equal to 1
     * * _tag_class_ equal to +:CONTEXT_SPECIFIC+
     * * _value_ equal to an Array with one single element, an
     *   instance of OpenSSL::ASN1::Integer, i.e. the inner element
     *   is the non-tagged primitive value, and the tagging is represented
     *   in the outer ASN1Data
     *
     * == Example - Decoding an implicitly tagged INTEGER
     *   int = OpenSSL::ASN1::Integer.new(1, 0, :IMPLICIT) # implicit 0-tagged
     *   seq = OpenSSL::ASN1::Sequence.new( [int] )
     *   der = seq.to_der
     *   asn1 = OpenSSL::ASN1.decode(der)
     *   # pp asn1 => #<OpenSSL::ASN1::Sequence:0x87326e0
     *   #              @indefinite_length=false,
     *   #              @tag=16,
     *   #              @tag_class=:UNIVERSAL,
     *   #              @tagging=nil,
     *   #              @value=
     *   #                [#<OpenSSL::ASN1::ASN1Data:0x87326f4
     *   #                   @indefinite_length=false,
     *   #                   @tag=0,
     *   #                   @tag_class=:CONTEXT_SPECIFIC,
     *   #                   @value="\x01">]>
     *   raw_int = asn1.value[0]
     *   # manually rewrite tag and tag class to make it an UNIVERSAL value
     *   raw_int.tag = OpenSSL::ASN1::INTEGER
     *   raw_int.tag_class = :UNIVERSAL
     *   int2 = OpenSSL::ASN1.decode(raw_int)
     *   puts int2.value # => 1
     *
     * == Example - Decoding an explicitly tagged INTEGER
     *   int = OpenSSL::ASN1::Integer.new(1, 0, :EXPLICIT) # explicit 0-tagged
     *   seq = OpenSSL::ASN1::Sequence.new( [int] )
     *   der = seq.to_der
     *   asn1 = OpenSSL::ASN1.decode(der)
     *   # pp asn1 => #<OpenSSL::ASN1::Sequence:0x87326e0
     *   #              @indefinite_length=false,
     *   #              @tag=16,
     *   #              @tag_class=:UNIVERSAL,
     *   #              @tagging=nil,
     *   #              @value=
     *   #                [#<OpenSSL::ASN1::ASN1Data:0x87326f4
     *   #                   @indefinite_length=false,
     *   #                   @tag=0,
     *   #                   @tag_class=:CONTEXT_SPECIFIC,
     *   #                   @value=
     *   #                     [#<OpenSSL::ASN1::Integer:0x85bf308
     *   #                        @indefinite_length=false,
     *   #                        @tag=2,
     *   #                        @tag_class=:UNIVERSAL
     *   #                        @tagging=nil,
     *   #                        @value=1>]>]>
     *   int2 = asn1.value[0].value[0]
     *   puts int2.value # => 1
     */
    cASN1Data = rb_define_class_under(mASN1, "ASN1Data", rb_cObject);
    /*
     * Carries the value of a ASN.1 type.
     * Please confer Constructive and Primitive for the mappings between
     * ASN.1 data types and Ruby classes.
     */
    rb_attr(cASN1Data, rb_intern("value"), 1, 1, 0);
    /*
     * An Integer representing the tag number of this ASN1Data. Never +nil+.
     */
    rb_attr(cASN1Data, rb_intern("tag"), 1, 1, 0);
    /*
     * A Symbol representing the tag class of this ASN1Data. Never +nil+.
     * See ASN1Data for possible values.
     */
    rb_attr(cASN1Data, rb_intern("tag_class"), 1, 1, 0);
    /*
     * Never +nil+. A boolean value indicating whether the encoding uses
     * indefinite length (in the case of parsing) or whether an indefinite
     * length form shall be used (in the encoding case).
     * In DER, every value uses definite length form. But in scenarios where
     * large amounts of data need to be transferred it might be desirable to
     * have some kind of streaming support available.
     * For example, huge OCTET STRINGs are preferably sent in smaller-sized
     * chunks, each at a time.
     * This is possible in BER by setting the length bytes of an encoding
     * to zero and by this indicating that the following value will be
     * sent in chunks. Indefinite length encodings are always constructed.
     * The end of such a stream of chunks is indicated by sending a EOC
     * (End of Content) tag. SETs and SEQUENCEs may use an indefinite length
     * encoding, but also primitive types such as e.g. OCTET STRINGS or
     * BIT STRINGS may leverage this functionality (cf. ITU-T X.690).
     */
    rb_attr(cASN1Data, rb_intern("indefinite_length"), 1, 1, 0);
    rb_define_alias(cASN1Data, "infinite_length", "indefinite_length");
    rb_define_alias(cASN1Data, "infinite_length=", "indefinite_length=");
    rb_define_method(cASN1Data, "initialize", ossl_asn1data_initialize, 3);
    rb_define_method(cASN1Data, "to_der", ossl_asn1data_to_der, 0);

    /* Document-class: OpenSSL::ASN1::Primitive
     *
     * The parent class for all primitive encodings. Attributes are the same as
     * for ASN1Data, with the addition of _tagging_.
     * Primitive values can never be encoded with indefinite length form, thus
     * it is not possible to set the _indefinite_length_ attribute for Primitive
     * and its sub-classes.
     *
     * == Primitive sub-classes and their mapping to Ruby classes
     * * OpenSSL::ASN1::EndOfContent    <=> _value_ is always +nil+
     * * OpenSSL::ASN1::Boolean         <=> _value_ is +true+ or +false+
     * * OpenSSL::ASN1::Integer         <=> _value_ is an OpenSSL::BN
     * * OpenSSL::ASN1::BitString       <=> _value_ is a String
     * * OpenSSL::ASN1::OctetString     <=> _value_ is a String
     * * OpenSSL::ASN1::Null            <=> _value_ is always +nil+
     * * OpenSSL::ASN1::Object          <=> _value_ is a String
     * * OpenSSL::ASN1::Enumerated      <=> _value_ is an OpenSSL::BN
     * * OpenSSL::ASN1::UTF8String      <=> _value_ is a String
     * * OpenSSL::ASN1::NumericString   <=> _value_ is a String
     * * OpenSSL::ASN1::PrintableString <=> _value_ is a String
     * * OpenSSL::ASN1::T61String       <=> _value_ is a String
     * * OpenSSL::ASN1::VideotexString  <=> _value_ is a String
     * * OpenSSL::ASN1::IA5String       <=> _value_ is a String
     * * OpenSSL::ASN1::UTCTime         <=> _value_ is a Time
     * * OpenSSL::ASN1::GeneralizedTime <=> _value_ is a Time
     * * OpenSSL::ASN1::GraphicString   <=> _value_ is a String
     * * OpenSSL::ASN1::ISO64String     <=> _value_ is a String
     * * OpenSSL::ASN1::GeneralString   <=> _value_ is a String
     * * OpenSSL::ASN1::UniversalString <=> _value_ is a String
     * * OpenSSL::ASN1::BMPString       <=> _value_ is a String
     *
     * == OpenSSL::ASN1::BitString
     *
     * === Additional attributes
     * _unused_bits_: if the underlying BIT STRING's
     * length is a multiple of 8 then _unused_bits_ is 0. Otherwise
     * _unused_bits_ indicates the number of bits that are to be ignored in
     * the final octet of the BitString's _value_.
     *
     * == OpenSSL::ASN1::ObjectId
     *
     * NOTE: While OpenSSL::ASN1::ObjectId.new will allocate a new ObjectId,
     * it is not typically allocated this way, but rather that are received from
     * parsed ASN1 encodings.
     *
     * === Additional attributes
     * * _sn_: the short name as defined in <openssl/objects.h>.
     * * _ln_: the long name as defined in <openssl/objects.h>.
     * * _oid_: the object identifier as a String, e.g. "1.2.3.4.5"
     * * _short_name_: alias for _sn_.
     * * _long_name_: alias for _ln_.
     *
     * == Examples
     * With the Exception of OpenSSL::ASN1::EndOfContent, each Primitive class
     * constructor takes at least one parameter, the _value_.
     *
     * === Creating EndOfContent
     *   eoc = OpenSSL::ASN1::EndOfContent.new
     *
     * === Creating any other Primitive
     *   prim = <class>.new(value) # <class> being one of the sub-classes except EndOfContent
     *   prim_zero_tagged_implicit = <class>.new(value, 0, :IMPLICIT)
     *   prim_zero_tagged_explicit = <class>.new(value, 0, :EXPLICIT)
     */
    cASN1Primitive = rb_define_class_under(mASN1, "Primitive", cASN1Data);
    /*
     * May be used as a hint for encoding a value either implicitly or
     * explicitly by setting it either to +:IMPLICIT+ or to +:EXPLICIT+.
     * _tagging_ is not set when a ASN.1 structure is parsed using
     * OpenSSL::ASN1.decode.
     */
    rb_attr(cASN1Primitive, rb_intern("tagging"), 1, 1, Qtrue);
    rb_undef_method(cASN1Primitive, "indefinite_length=");
    rb_undef_method(cASN1Primitive, "infinite_length=");
    rb_define_method(cASN1Primitive, "initialize", ossl_asn1_initialize, -1);
    rb_define_method(cASN1Primitive, "to_der", ossl_asn1prim_to_der, 0);

    /* Document-class: OpenSSL::ASN1::Constructive
     *
     * The parent class for all constructed encodings. The _value_ attribute
     * of a Constructive is always an Array. Attributes are the same as
     * for ASN1Data, with the addition of _tagging_.
     *
     * == SET and SEQUENCE
     *
     * Most constructed encodings come in the form of a SET or a SEQUENCE.
     * These encodings are represented by one of the two sub-classes of
     * Constructive:
     * * OpenSSL::ASN1::Set
     * * OpenSSL::ASN1::Sequence
     * Please note that tagged sequences and sets are still parsed as
     * instances of ASN1Data. Find further details on tagged values
     * there.
     *
     * === Example - constructing a SEQUENCE
     *   int = OpenSSL::ASN1::Integer.new(1)
     *   str = OpenSSL::ASN1::PrintableString.new('abc')
     *   sequence = OpenSSL::ASN1::Sequence.new( [ int, str ] )
     *
     * === Example - constructing a SET
     *   int = OpenSSL::ASN1::Integer.new(1)
     *   str = OpenSSL::ASN1::PrintableString.new('abc')
     *   set = OpenSSL::ASN1::Set.new( [ int, str ] )
     */
    cASN1Constructive = rb_define_class_under(mASN1,"Constructive", cASN1Data);
    rb_include_module(cASN1Constructive, rb_mEnumerable);
    /*
     * May be used as a hint for encoding a value either implicitly or
     * explicitly by setting it either to +:IMPLICIT+ or to +:EXPLICIT+.
     * _tagging_ is not set when a ASN.1 structure is parsed using
     * OpenSSL::ASN1.decode.
     */
    rb_attr(cASN1Constructive, rb_intern("tagging"), 1, 1, Qtrue);
    rb_define_method(cASN1Constructive, "initialize", ossl_asn1_initialize, -1);
    rb_define_method(cASN1Constructive, "to_der", ossl_asn1cons_to_der, 0);
    rb_define_method(cASN1Constructive, "each", ossl_asn1cons_each, 0);

#define OSSL_ASN1_DEFINE_CLASS(name, super) \
do{\
    cASN1##name = rb_define_class_under(mASN1, #name, cASN1##super);\
    rb_define_module_function(mASN1, #name, ossl_asn1_##name, -1);\
}while(0)

    OSSL_ASN1_DEFINE_CLASS(Boolean, Primitive);
    OSSL_ASN1_DEFINE_CLASS(Integer, Primitive);
    OSSL_ASN1_DEFINE_CLASS(Enumerated, Primitive);
    OSSL_ASN1_DEFINE_CLASS(BitString, Primitive);
    OSSL_ASN1_DEFINE_CLASS(OctetString, Primitive);
    OSSL_ASN1_DEFINE_CLASS(UTF8String, Primitive);
    OSSL_ASN1_DEFINE_CLASS(NumericString, Primitive);
    OSSL_ASN1_DEFINE_CLASS(PrintableString, Primitive);
    OSSL_ASN1_DEFINE_CLASS(T61String, Primitive);
    OSSL_ASN1_DEFINE_CLASS(VideotexString, Primitive);
    OSSL_ASN1_DEFINE_CLASS(IA5String, Primitive);
    OSSL_ASN1_DEFINE_CLASS(GraphicString, Primitive);
    OSSL_ASN1_DEFINE_CLASS(ISO64String, Primitive);
    OSSL_ASN1_DEFINE_CLASS(GeneralString, Primitive);
    OSSL_ASN1_DEFINE_CLASS(UniversalString, Primitive);
    OSSL_ASN1_DEFINE_CLASS(BMPString, Primitive);
    OSSL_ASN1_DEFINE_CLASS(Null, Primitive);
    OSSL_ASN1_DEFINE_CLASS(ObjectId, Primitive);
    OSSL_ASN1_DEFINE_CLASS(UTCTime, Primitive);
    OSSL_ASN1_DEFINE_CLASS(GeneralizedTime, Primitive);

    OSSL_ASN1_DEFINE_CLASS(Sequence, Constructive);
    OSSL_ASN1_DEFINE_CLASS(Set, Constructive);

    OSSL_ASN1_DEFINE_CLASS(EndOfContent, Data);


    /* Document-class: OpenSSL::ASN1::ObjectId
     *
     * Represents the primitive object id for OpenSSL::ASN1
     */
#if 0
    cASN1ObjectId = rb_define_class_under(mASN1, "ObjectId", cASN1Primitive);  /* let rdoc know */
#endif
    rb_define_singleton_method(cASN1ObjectId, "register", ossl_asn1obj_s_register, 3);
    rb_define_method(cASN1ObjectId, "sn", ossl_asn1obj_get_sn, 0);
    rb_define_method(cASN1ObjectId, "ln", ossl_asn1obj_get_ln, 0);
    rb_define_method(cASN1ObjectId, "oid", ossl_asn1obj_get_oid, 0);
    rb_define_alias(cASN1ObjectId, "short_name", "sn");
    rb_define_alias(cASN1ObjectId, "long_name", "ln");
    rb_define_method(cASN1ObjectId, "==", ossl_asn1obj_eq, 1);
    rb_attr(cASN1BitString, rb_intern("unused_bits"), 1, 1, 0);

    rb_define_method(cASN1EndOfContent, "initialize", ossl_asn1eoc_initialize, 0);
    rb_define_method(cASN1EndOfContent, "to_der", ossl_asn1eoc_to_der, 0);

    class_tag_map = rb_hash_new();
    rb_gc_register_mark_object(class_tag_map);
    rb_hash_aset(class_tag_map, cASN1EndOfContent, INT2NUM(V_ASN1_EOC));
    rb_hash_aset(class_tag_map, cASN1Boolean, INT2NUM(V_ASN1_BOOLEAN));
    rb_hash_aset(class_tag_map, cASN1Integer, INT2NUM(V_ASN1_INTEGER));
    rb_hash_aset(class_tag_map, cASN1BitString, INT2NUM(V_ASN1_BIT_STRING));
    rb_hash_aset(class_tag_map, cASN1OctetString, INT2NUM(V_ASN1_OCTET_STRING));
    rb_hash_aset(class_tag_map, cASN1Null, INT2NUM(V_ASN1_NULL));
    rb_hash_aset(class_tag_map, cASN1ObjectId, INT2NUM(V_ASN1_OBJECT));
    rb_hash_aset(class_tag_map, cASN1Enumerated, INT2NUM(V_ASN1_ENUMERATED));
    rb_hash_aset(class_tag_map, cASN1UTF8String, INT2NUM(V_ASN1_UTF8STRING));
    rb_hash_aset(class_tag_map, cASN1Sequence, INT2NUM(V_ASN1_SEQUENCE));
    rb_hash_aset(class_tag_map, cASN1Set, INT2NUM(V_ASN1_SET));
    rb_hash_aset(class_tag_map, cASN1NumericString, INT2NUM(V_ASN1_NUMERICSTRING));
    rb_hash_aset(class_tag_map, cASN1PrintableString, INT2NUM(V_ASN1_PRINTABLESTRING));
    rb_hash_aset(class_tag_map, cASN1T61String, INT2NUM(V_ASN1_T61STRING));
    rb_hash_aset(class_tag_map, cASN1VideotexString, INT2NUM(V_ASN1_VIDEOTEXSTRING));
    rb_hash_aset(class_tag_map, cASN1IA5String, INT2NUM(V_ASN1_IA5STRING));
    rb_hash_aset(class_tag_map, cASN1UTCTime, INT2NUM(V_ASN1_UTCTIME));
    rb_hash_aset(class_tag_map, cASN1GeneralizedTime, INT2NUM(V_ASN1_GENERALIZEDTIME));
    rb_hash_aset(class_tag_map, cASN1GraphicString, INT2NUM(V_ASN1_GRAPHICSTRING));
    rb_hash_aset(class_tag_map, cASN1ISO64String, INT2NUM(V_ASN1_ISO64STRING));
    rb_hash_aset(class_tag_map, cASN1GeneralString, INT2NUM(V_ASN1_GENERALSTRING));
    rb_hash_aset(class_tag_map, cASN1UniversalString, INT2NUM(V_ASN1_UNIVERSALSTRING));
    rb_hash_aset(class_tag_map, cASN1BMPString, INT2NUM(V_ASN1_BMPSTRING));

    id_each = rb_intern_const("each");
}
