/*
 * 'OpenSSL for Ruby' project
 * Copyright (C) 2001 Michal Rokos <m.rokos@sh.cvut.cz>
 * All rights reserved.
 */
/*
 * This program is licensed under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#include "ossl.h"

#define NewX509Name(klass) \
    TypedData_Wrap_Struct((klass), &ossl_x509name_type, 0)
#define SetX509Name(obj, name) do { \
    if (!(name)) { \
	ossl_raise(rb_eRuntimeError, "Name wasn't initialized."); \
    } \
    RTYPEDDATA_DATA(obj) = (name); \
} while (0)
#define GetX509Name(obj, name) do { \
    TypedData_Get_Struct((obj), X509_NAME, &ossl_x509name_type, (name)); \
    if (!(name)) { \
	ossl_raise(rb_eRuntimeError, "Name wasn't initialized."); \
    } \
} while (0)

#define OBJECT_TYPE_TEMPLATE \
  rb_const_get(cX509Name, rb_intern("OBJECT_TYPE_TEMPLATE"))
#define DEFAULT_OBJECT_TYPE \
  rb_const_get(cX509Name, rb_intern("DEFAULT_OBJECT_TYPE"))

/*
 * Classes
 */
VALUE cX509Name;
VALUE eX509NameError;

static void
ossl_x509name_free(void *ptr)
{
    X509_NAME_free(ptr);
}

static const rb_data_type_t ossl_x509name_type = {
    "OpenSSL/X509/NAME",
    {
	0, ossl_x509name_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

/*
 * Public
 */
VALUE
ossl_x509name_new(X509_NAME *name)
{
    X509_NAME *new;
    VALUE obj;

    obj = NewX509Name(cX509Name);
    if (!name) {
	new = X509_NAME_new();
    } else {
	new = X509_NAME_dup(name);
    }
    if (!new) {
	ossl_raise(eX509NameError, NULL);
    }
    SetX509Name(obj, new);

    return obj;
}

X509_NAME *
GetX509NamePtr(VALUE obj)
{
    X509_NAME *name;

    GetX509Name(obj, name);

    return name;
}

/*
 * Private
 */
static VALUE
ossl_x509name_alloc(VALUE klass)
{
    X509_NAME *name;
    VALUE obj;

    obj = NewX509Name(klass);
    if (!(name = X509_NAME_new())) {
	ossl_raise(eX509NameError, NULL);
    }
    SetX509Name(obj, name);

    return obj;
}

static ID id_aref;
static VALUE ossl_x509name_add_entry(int, VALUE*, VALUE);
#define rb_aref(obj, key) rb_funcall((obj), id_aref, 1, (key))

static VALUE
ossl_x509name_init_i(RB_BLOCK_CALL_FUNC_ARGLIST(i, args))
{
    VALUE self = rb_ary_entry(args, 0);
    VALUE template = rb_ary_entry(args, 1);
    VALUE entry[3];

    Check_Type(i, T_ARRAY);
    entry[0] = rb_ary_entry(i, 0);
    entry[1] = rb_ary_entry(i, 1);
    entry[2] = rb_ary_entry(i, 2);
    if(NIL_P(entry[2])) entry[2] = rb_aref(template, entry[0]);
    if(NIL_P(entry[2])) entry[2] = DEFAULT_OBJECT_TYPE;
    ossl_x509name_add_entry(3, entry, self);

    return Qnil;
}

/*
 * call-seq:
 *    X509::Name.new                               => name
 *    X509::Name.new(der)                          => name
 *    X509::Name.new(distinguished_name)           => name
 *    X509::Name.new(distinguished_name, template) => name
 *
 * Creates a new Name.
 *
 * A name may be created from a DER encoded string _der_, an Array
 * representing a _distinguished_name_ or a _distinguished_name_ along with a
 * _template_.
 *
 *   name = OpenSSL::X509::Name.new [['CN', 'nobody'], ['DC', 'example']]
 *
 *   name = OpenSSL::X509::Name.new name.to_der
 *
 * See add_entry for a description of the _distinguished_name_ Array's
 * contents
 */
static VALUE
ossl_x509name_initialize(int argc, VALUE *argv, VALUE self)
{
    X509_NAME *name;
    VALUE arg, template;

    GetX509Name(self, name);
    if (rb_scan_args(argc, argv, "02", &arg, &template) == 0) {
	return self;
    }
    else {
	VALUE tmp = rb_check_array_type(arg);
	if (!NIL_P(tmp)) {
	    VALUE args;
	    if(NIL_P(template)) template = OBJECT_TYPE_TEMPLATE;
	    args = rb_ary_new3(2, self, template);
	    rb_block_call(tmp, rb_intern("each"), 0, 0, ossl_x509name_init_i, args);
	}
	else{
	    const unsigned char *p;
	    VALUE str = ossl_to_der_if_possible(arg);
	    X509_NAME *x;
	    StringValue(str);
	    p = (unsigned char *)RSTRING_PTR(str);
	    x = d2i_X509_NAME(&name, &p, RSTRING_LEN(str));
	    DATA_PTR(self) = name;
	    if(!x){
		ossl_raise(eX509NameError, NULL);
	    }
	}
    }

    return self;
}

static VALUE
ossl_x509name_initialize_copy(VALUE self, VALUE other)
{
    X509_NAME *name, *name_other, *name_new;

    rb_check_frozen(self);
    GetX509Name(self, name);
    GetX509Name(other, name_other);

    name_new = X509_NAME_dup(name_other);
    if (!name_new)
	ossl_raise(eX509NameError, "X509_NAME_dup");

    SetX509Name(self, name_new);
    X509_NAME_free(name);

    return self;
}

/*
 * call-seq:
 *    name.add_entry(oid, value [, type], loc: -1, set: 0) => self
 *
 * Adds a new entry with the given _oid_ and _value_ to this name.  The _oid_
 * is an object identifier defined in ASN.1.  Some common OIDs are:
 *
 * C::  Country Name
 * CN:: Common Name
 * DC:: Domain Component
 * O::  Organization Name
 * OU:: Organizational Unit Name
 * ST:: State or Province Name
 *
 * The optional keyword parameters _loc_ and _set_ specify where to insert the
 * new attribute. Refer to the manpage of X509_NAME_add_entry(3) for details.
 * _loc_ defaults to -1 and _set_ defaults to 0. This appends a single-valued
 * RDN to the end.
 */
static
VALUE ossl_x509name_add_entry(int argc, VALUE *argv, VALUE self)
{
    X509_NAME *name;
    VALUE oid, value, type, opts, kwargs[2];
    static ID kwargs_ids[2];
    const char *oid_name;
    int loc = -1, set = 0;

    if (!kwargs_ids[0]) {
	kwargs_ids[0] = rb_intern_const("loc");
	kwargs_ids[1] = rb_intern_const("set");
    }
    rb_scan_args(argc, argv, "21:", &oid, &value, &type, &opts);
    rb_get_kwargs(opts, kwargs_ids, 0, 2, kwargs);
    oid_name = StringValueCStr(oid);
    StringValue(value);
    if(NIL_P(type)) type = rb_aref(OBJECT_TYPE_TEMPLATE, oid);
    if (kwargs[0] != Qundef)
	loc = NUM2INT(kwargs[0]);
    if (kwargs[1] != Qundef)
	set = NUM2INT(kwargs[1]);
    GetX509Name(self, name);
    if (!X509_NAME_add_entry_by_txt(name, oid_name, NUM2INT(type),
				    (unsigned char *)RSTRING_PTR(value),
				    RSTRING_LENINT(value), loc, set))
	ossl_raise(eX509NameError, "X509_NAME_add_entry_by_txt");
    return self;
}

static VALUE
ossl_x509name_to_s_old(VALUE self)
{
    X509_NAME *name;
    char *buf;

    GetX509Name(self, name);
    buf = X509_NAME_oneline(name, NULL, 0);
    if (!buf)
	ossl_raise(eX509NameError, "X509_NAME_oneline");
    return ossl_buf2str(buf, rb_long2int(strlen(buf)));
}

static VALUE
x509name_print(VALUE self, unsigned long iflag)
{
    X509_NAME *name;
    BIO *out;
    int ret;

    GetX509Name(self, name);
    out = BIO_new(BIO_s_mem());
    if (!out)
	ossl_raise(eX509NameError, NULL);
    ret = X509_NAME_print_ex(out, name, 0, iflag);
    if (ret < 0 || (iflag == XN_FLAG_COMPAT && ret == 0)) {
	BIO_free(out);
	ossl_raise(eX509NameError, "X509_NAME_print_ex");
    }
    return ossl_membio2str(out);
}

/*
 * call-seq:
 *    name.to_s         -> string
 *    name.to_s(format) -> string
 *
 * Returns a String representation of the Distinguished Name. _format_ is
 * one of:
 *
 * * OpenSSL::X509::Name::COMPAT
 * * OpenSSL::X509::Name::RFC2253
 * * OpenSSL::X509::Name::ONELINE
 * * OpenSSL::X509::Name::MULTILINE
 *
 * If _format_ is omitted, the largely broken and traditional OpenSSL format
 * (<tt>X509_NAME_oneline()</tt> format) is chosen.
 *
 * <b>Use of this method is discouraged.</b> None of the formats other than
 * OpenSSL::X509::Name::RFC2253 is standardized and may show an inconsistent
 * behavior through \OpenSSL versions.
 *
 * It is recommended to use #to_utf8 instead, which is equivalent to calling
 * <tt>name.to_s(OpenSSL::X509::Name::RFC2253).force_encoding("UTF-8")</tt>.
 */
static VALUE
ossl_x509name_to_s(int argc, VALUE *argv, VALUE self)
{
    rb_check_arity(argc, 0, 1);
    /* name.to_s(nil) was allowed */
    if (!argc || NIL_P(argv[0]))
	return ossl_x509name_to_s_old(self);
    else
	return x509name_print(self, NUM2ULONG(argv[0]));
}

/*
 * call-seq:
 *    name.to_utf8 -> string
 *
 * Returns an UTF-8 representation of the distinguished name, as specified
 * in {RFC 2253}[https://www.ietf.org/rfc/rfc2253.txt].
 */
static VALUE
ossl_x509name_to_utf8(VALUE self)
{
    VALUE str = x509name_print(self, XN_FLAG_RFC2253 & ~ASN1_STRFLGS_ESC_MSB);
    rb_enc_associate_index(str, rb_utf8_encindex());
    return str;
}

/* :nodoc: */
static VALUE
ossl_x509name_inspect(VALUE self)
{
    return rb_enc_sprintf(rb_utf8_encoding(), "#<%"PRIsVALUE" %"PRIsVALUE">",
			  rb_obj_class(self), ossl_x509name_to_utf8(self));
}

/*
 * call-seq:
 *    name.to_a => [[name, data, type], ...]
 *
 * Returns an Array representation of the distinguished name suitable for
 * passing to ::new
 */
static VALUE
ossl_x509name_to_a(VALUE self)
{
    X509_NAME *name;
    X509_NAME_ENTRY *entry;
    int i,entries,nid;
    char long_name[512];
    const char *short_name;
    VALUE ary, vname, ret;
    ASN1_STRING *value;

    GetX509Name(self, name);
    entries = X509_NAME_entry_count(name);
    if (entries < 0) {
	OSSL_Debug("name entries < 0!");
	return rb_ary_new();
    }
    ret = rb_ary_new2(entries);
    for (i=0; i<entries; i++) {
	if (!(entry = X509_NAME_get_entry(name, i))) {
	    ossl_raise(eX509NameError, NULL);
	}
	if (!i2t_ASN1_OBJECT(long_name, sizeof(long_name),
			     X509_NAME_ENTRY_get_object(entry))) {
	    ossl_raise(eX509NameError, NULL);
	}
	nid = OBJ_ln2nid(long_name);
	if (nid == NID_undef) {
	    vname = rb_str_new2((const char *) &long_name);
	} else {
	    short_name = OBJ_nid2sn(nid);
	    vname = rb_str_new2(short_name); /*do not free*/
	}
	value = X509_NAME_ENTRY_get_data(entry);
	ary = rb_ary_new3(3, vname, asn1str_to_str(value), INT2NUM(value->type));
	rb_ary_push(ret, ary);
    }
    return ret;
}

static int
ossl_x509name_cmp0(VALUE self, VALUE other)
{
    X509_NAME *name1, *name2;

    GetX509Name(self, name1);
    GetX509Name(other, name2);

    return X509_NAME_cmp(name1, name2);
}

/*
 * call-seq:
 *    name.cmp(other) -> -1 | 0 | 1 | nil
 *    name <=> other  -> -1 | 0 | 1 | nil
 *
 * Compares this Name with _other_ and returns +0+ if they are the same and +-1+
 * or ++1+ if they are greater or less than each other respectively.
 * Returns +nil+ if they are not comparable (i.e. different types).
 */
static VALUE
ossl_x509name_cmp(VALUE self, VALUE other)
{
    int result;

    if (!rb_obj_is_kind_of(other, cX509Name))
	return Qnil;

    result = ossl_x509name_cmp0(self, other);
    if (result < 0) return INT2FIX(-1);
    if (result > 0) return INT2FIX(1);

    return INT2FIX(0);
}

/*
 * call-seq:
 *   name.eql?(other) -> true | false
 *
 * Returns true if _name_ and _other_ refer to the same hash key.
 */
static VALUE
ossl_x509name_eql(VALUE self, VALUE other)
{
    if (!rb_obj_is_kind_of(other, cX509Name))
	return Qfalse;

    return ossl_x509name_cmp0(self, other) == 0 ? Qtrue : Qfalse;
}

/*
 * call-seq:
 *    name.hash => integer
 *
 * The hash value returned is suitable for use as a certificate's filename in
 * a CA path.
 */
static VALUE
ossl_x509name_hash(VALUE self)
{
    X509_NAME *name;
    unsigned long hash;

    GetX509Name(self, name);

    hash = X509_NAME_hash(name);

    return ULONG2NUM(hash);
}

/*
 * call-seq:
 *    name.hash_old => integer
 *
 * Returns an MD5 based hash used in OpenSSL 0.9.X.
 */
static VALUE
ossl_x509name_hash_old(VALUE self)
{
    X509_NAME *name;
    unsigned long hash;

    GetX509Name(self, name);

    hash = X509_NAME_hash_old(name);

    return ULONG2NUM(hash);
}

/*
 * call-seq:
 *    name.to_der => string
 *
 * Converts the name to DER encoding
 */
static VALUE
ossl_x509name_to_der(VALUE self)
{
    X509_NAME *name;
    VALUE str;
    long len;
    unsigned char *p;

    GetX509Name(self, name);
    if((len = i2d_X509_NAME(name, NULL)) <= 0)
	ossl_raise(eX509NameError, NULL);
    str = rb_str_new(0, len);
    p = (unsigned char *)RSTRING_PTR(str);
    if(i2d_X509_NAME(name, &p) <= 0)
	ossl_raise(eX509NameError, NULL);
    ossl_str_adjust(str, p);

    return str;
}

/*
 * Document-class: OpenSSL::X509::Name
 *
 * An X.509 name represents a hostname, email address or other entity
 * associated with a public key.
 *
 * You can create a Name by parsing a distinguished name String or by
 * supplying the distinguished name as an Array.
 *
 *   name = OpenSSL::X509::Name.parse_rfc2253 'DC=example,CN=nobody'
 *
 *   name = OpenSSL::X509::Name.new [['CN', 'nobody'], ['DC', 'example']]
 */

void
Init_ossl_x509name(void)
{
#undef rb_intern
    VALUE utf8str, ptrstr, ia5str, hash;

#if 0
    mOSSL = rb_define_module("OpenSSL");
    eOSSLError = rb_define_class_under(mOSSL, "OpenSSLError", rb_eStandardError);
    mX509 = rb_define_module_under(mOSSL, "X509");
#endif

    id_aref = rb_intern("[]");
    eX509NameError = rb_define_class_under(mX509, "NameError", eOSSLError);
    cX509Name = rb_define_class_under(mX509, "Name", rb_cObject);

    rb_include_module(cX509Name, rb_mComparable);

    rb_define_alloc_func(cX509Name, ossl_x509name_alloc);
    rb_define_method(cX509Name, "initialize", ossl_x509name_initialize, -1);
    rb_define_method(cX509Name, "initialize_copy", ossl_x509name_initialize_copy, 1);
    rb_define_method(cX509Name, "add_entry", ossl_x509name_add_entry, -1);
    rb_define_method(cX509Name, "to_s", ossl_x509name_to_s, -1);
    rb_define_method(cX509Name, "to_utf8", ossl_x509name_to_utf8, 0);
    rb_define_method(cX509Name, "inspect", ossl_x509name_inspect, 0);
    rb_define_method(cX509Name, "to_a", ossl_x509name_to_a, 0);
    rb_define_method(cX509Name, "cmp", ossl_x509name_cmp, 1);
    rb_define_alias(cX509Name, "<=>", "cmp");
    rb_define_method(cX509Name, "eql?", ossl_x509name_eql, 1);
    rb_define_method(cX509Name, "hash", ossl_x509name_hash, 0);
    rb_define_method(cX509Name, "hash_old", ossl_x509name_hash_old, 0);
    rb_define_method(cX509Name, "to_der", ossl_x509name_to_der, 0);

    utf8str = INT2NUM(V_ASN1_UTF8STRING);
    ptrstr = INT2NUM(V_ASN1_PRINTABLESTRING);
    ia5str = INT2NUM(V_ASN1_IA5STRING);

    /*
     * The default object type for name entries.
     */
    rb_define_const(cX509Name, "DEFAULT_OBJECT_TYPE", utf8str);
    hash = rb_hash_new();
    RHASH_SET_IFNONE(hash, utf8str);
    rb_hash_aset(hash, rb_str_new2("C"), ptrstr);
    rb_hash_aset(hash, rb_str_new2("countryName"), ptrstr);
    rb_hash_aset(hash, rb_str_new2("serialNumber"), ptrstr);
    rb_hash_aset(hash, rb_str_new2("dnQualifier"), ptrstr);
    rb_hash_aset(hash, rb_str_new2("DC"), ia5str);
    rb_hash_aset(hash, rb_str_new2("domainComponent"), ia5str);
    rb_hash_aset(hash, rb_str_new2("emailAddress"), ia5str);

    /*
     * The default object type template for name entries.
     */
    rb_define_const(cX509Name, "OBJECT_TYPE_TEMPLATE", hash);

    /*
     * A flag for #to_s.
     *
     * Breaks the name returned into multiple lines if longer than 80
     * characters.
     */
    rb_define_const(cX509Name, "COMPAT", ULONG2NUM(XN_FLAG_COMPAT));

    /*
     * A flag for #to_s.
     *
     * Returns an RFC2253 format name.
     */
    rb_define_const(cX509Name, "RFC2253", ULONG2NUM(XN_FLAG_RFC2253));

    /*
     * A flag for #to_s.
     *
     * Returns a more readable format than RFC2253.
     */
    rb_define_const(cX509Name, "ONELINE", ULONG2NUM(XN_FLAG_ONELINE));

    /*
     * A flag for #to_s.
     *
     * Returns a multiline format.
     */
    rb_define_const(cX509Name, "MULTILINE", ULONG2NUM(XN_FLAG_MULTILINE));
}
