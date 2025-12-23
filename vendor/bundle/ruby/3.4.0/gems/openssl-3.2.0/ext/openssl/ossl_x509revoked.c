/*
 * 'OpenSSL for Ruby' project
 * Copyright (C) 2001-2002  Michal Rokos <m.rokos@sh.cvut.cz>
 * All rights reserved.
 */
/*
 * This program is licensed under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#include "ossl.h"

#define NewX509Rev(klass) \
    TypedData_Wrap_Struct((klass), &ossl_x509rev_type, 0)
#define SetX509Rev(obj, rev) do { \
    if (!(rev)) { \
	ossl_raise(rb_eRuntimeError, "REV wasn't initialized!"); \
    } \
    RTYPEDDATA_DATA(obj) = (rev); \
} while (0)
#define GetX509Rev(obj, rev) do { \
    TypedData_Get_Struct((obj), X509_REVOKED, &ossl_x509rev_type, (rev)); \
    if (!(rev)) { \
	ossl_raise(rb_eRuntimeError, "REV wasn't initialized!"); \
    } \
} while (0)

/*
 * Classes
 */
VALUE cX509Rev;
VALUE eX509RevError;

static void
ossl_x509rev_free(void *ptr)
{
    X509_REVOKED_free(ptr);
}

static const rb_data_type_t ossl_x509rev_type = {
    "OpenSSL/X509/REV",
    {
	0, ossl_x509rev_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

/*
 * PUBLIC
 */
VALUE
ossl_x509revoked_new(X509_REVOKED *rev)
{
    X509_REVOKED *new;
    VALUE obj;

    obj = NewX509Rev(cX509Rev);
    if (!rev) {
	new = X509_REVOKED_new();
    } else {
	new = X509_REVOKED_dup(rev);
    }
    if (!new) {
	ossl_raise(eX509RevError, NULL);
    }
    SetX509Rev(obj, new);

    return obj;
}

X509_REVOKED *
DupX509RevokedPtr(VALUE obj)
{
    X509_REVOKED *rev, *new;

    GetX509Rev(obj, rev);
    if (!(new = X509_REVOKED_dup(rev))) {
	ossl_raise(eX509RevError, NULL);
    }

    return new;
}

/*
 * PRIVATE
 */
static VALUE
ossl_x509revoked_alloc(VALUE klass)
{
    X509_REVOKED *rev;
    VALUE obj;

    obj = NewX509Rev(klass);
    if (!(rev = X509_REVOKED_new())) {
	ossl_raise(eX509RevError, NULL);
    }
    SetX509Rev(obj, rev);

    return obj;
}

static VALUE
ossl_x509revoked_initialize(int argc, VALUE *argv, VALUE self)
{
    /* EMPTY */
    return self;
}

static VALUE
ossl_x509revoked_initialize_copy(VALUE self, VALUE other)
{
    X509_REVOKED *rev, *rev_other, *rev_new;

    rb_check_frozen(self);
    GetX509Rev(self, rev);
    GetX509Rev(other, rev_other);

    rev_new = X509_REVOKED_dup(rev_other);
    if (!rev_new)
	ossl_raise(eX509RevError, "X509_REVOKED_dup");

    SetX509Rev(self, rev_new);
    X509_REVOKED_free(rev);

    return self;
}

static VALUE
ossl_x509revoked_get_serial(VALUE self)
{
    X509_REVOKED *rev;

    GetX509Rev(self, rev);

    return asn1integer_to_num(X509_REVOKED_get0_serialNumber(rev));
}

static VALUE
ossl_x509revoked_set_serial(VALUE self, VALUE num)
{
    X509_REVOKED *rev;
    ASN1_INTEGER *asn1int;

    GetX509Rev(self, rev);
    asn1int = num_to_asn1integer(num, NULL);
    if (!X509_REVOKED_set_serialNumber(rev, asn1int)) {
	ASN1_INTEGER_free(asn1int);
	ossl_raise(eX509RevError, "X509_REVOKED_set_serialNumber");
    }
    ASN1_INTEGER_free(asn1int);

    return num;
}

static VALUE
ossl_x509revoked_get_time(VALUE self)
{
    X509_REVOKED *rev;
    const ASN1_TIME *time;

    GetX509Rev(self, rev);
    time = X509_REVOKED_get0_revocationDate(rev);
    if (!time)
	return Qnil;

    return asn1time_to_time(time);
}

static VALUE
ossl_x509revoked_set_time(VALUE self, VALUE time)
{
    X509_REVOKED *rev;
    ASN1_TIME *asn1time;

    GetX509Rev(self, rev);
    asn1time = ossl_x509_time_adjust(NULL, time);
    if (!X509_REVOKED_set_revocationDate(rev, asn1time)) {
	ASN1_TIME_free(asn1time);
	ossl_raise(eX509RevError, "X509_REVOKED_set_revocationDate");
    }
    ASN1_TIME_free(asn1time);

    return time;
}
/*
 * Gets X509v3 extensions as array of X509Ext objects
 */
static VALUE
ossl_x509revoked_get_extensions(VALUE self)
{
    X509_REVOKED *rev;
    int count, i;
    X509_EXTENSION *ext;
    VALUE ary;

    GetX509Rev(self, rev);
    count = X509_REVOKED_get_ext_count(rev);
    if (count < 0) {
	OSSL_Debug("count < 0???");
	return rb_ary_new();
    }
    ary = rb_ary_new2(count);
    for (i=0; i<count; i++) {
	ext = X509_REVOKED_get_ext(rev, i);
	rb_ary_push(ary, ossl_x509ext_new(ext));
    }

    return ary;
}

/*
 * Sets X509_EXTENSIONs
 */
static VALUE
ossl_x509revoked_set_extensions(VALUE self, VALUE ary)
{
    X509_REVOKED *rev;
    X509_EXTENSION *ext;
    long i;
    VALUE item;

    Check_Type(ary, T_ARRAY);
    for (i=0; i<RARRAY_LEN(ary); i++) {
	OSSL_Check_Kind(RARRAY_AREF(ary, i), cX509Ext);
    }
    GetX509Rev(self, rev);
    for (i = X509_REVOKED_get_ext_count(rev); i > 0; i--)
        X509_EXTENSION_free(X509_REVOKED_delete_ext(rev, 0));
    for (i=0; i<RARRAY_LEN(ary); i++) {
	item = RARRAY_AREF(ary, i);
	ext = GetX509ExtPtr(item);
	if(!X509_REVOKED_add_ext(rev, ext, -1)) {
	    ossl_raise(eX509RevError, "X509_REVOKED_add_ext");
	}
    }

    return ary;
}

static VALUE
ossl_x509revoked_add_extension(VALUE self, VALUE ext)
{
    X509_REVOKED *rev;

    GetX509Rev(self, rev);
    if (!X509_REVOKED_add_ext(rev, GetX509ExtPtr(ext), -1)) {
	ossl_raise(eX509RevError, NULL);
    }

    return ext;
}

static VALUE
ossl_x509revoked_to_der(VALUE self)
{
    X509_REVOKED *rev;
    VALUE str;
    int len;
    unsigned char *p;

    GetX509Rev(self, rev);
    len = i2d_X509_REVOKED(rev, NULL);
    if (len <= 0)
	ossl_raise(eX509RevError, "i2d_X509_REVOKED");
    str = rb_str_new(NULL, len);
    p = (unsigned char *)RSTRING_PTR(str);
    if (i2d_X509_REVOKED(rev, &p) <= 0)
	ossl_raise(eX509RevError, "i2d_X509_REVOKED");
    ossl_str_adjust(str, p);
    return str;
}

/*
 * INIT
 */
void
Init_ossl_x509revoked(void)
{
#if 0
    mOSSL = rb_define_module("OpenSSL");
    eOSSLError = rb_define_class_under(mOSSL, "OpenSSLError", rb_eStandardError);
    mX509 = rb_define_module_under(mOSSL, "X509");
#endif

    eX509RevError = rb_define_class_under(mX509, "RevokedError", eOSSLError);

    cX509Rev = rb_define_class_under(mX509, "Revoked", rb_cObject);

    rb_define_alloc_func(cX509Rev, ossl_x509revoked_alloc);
    rb_define_method(cX509Rev, "initialize", ossl_x509revoked_initialize, -1);
    rb_define_method(cX509Rev, "initialize_copy", ossl_x509revoked_initialize_copy, 1);

    rb_define_method(cX509Rev, "serial", ossl_x509revoked_get_serial, 0);
    rb_define_method(cX509Rev, "serial=", ossl_x509revoked_set_serial, 1);
    rb_define_method(cX509Rev, "time", ossl_x509revoked_get_time, 0);
    rb_define_method(cX509Rev, "time=", ossl_x509revoked_set_time, 1);
    rb_define_method(cX509Rev, "extensions", ossl_x509revoked_get_extensions, 0);
    rb_define_method(cX509Rev, "extensions=", ossl_x509revoked_set_extensions, 1);
    rb_define_method(cX509Rev, "add_extension", ossl_x509revoked_add_extension, 1);
    rb_define_method(cX509Rev, "to_der", ossl_x509revoked_to_der, 0);
}
