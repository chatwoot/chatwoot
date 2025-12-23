/*
 * 'OpenSSL for Ruby' project
 * Copyright (C) 2003  Michal Rokos <m.rokos@sh.cvut.cz>
 * Copyright (C) 2003  GOTOU Yuuzou <gotoyuzo@notwork.org>
 * All rights reserved.
 */
/*
 * This program is licensed under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#include "ossl.h"

#if !defined(OPENSSL_NO_OCSP)

#define NewOCSPReq(klass) \
    TypedData_Wrap_Struct((klass), &ossl_ocsp_request_type, 0)
#define SetOCSPReq(obj, req) do { \
    if(!(req)) ossl_raise(rb_eRuntimeError, "Request wasn't initialized!"); \
    RTYPEDDATA_DATA(obj) = (req); \
} while (0)
#define GetOCSPReq(obj, req) do { \
    TypedData_Get_Struct((obj), OCSP_REQUEST, &ossl_ocsp_request_type, (req)); \
    if(!(req)) ossl_raise(rb_eRuntimeError, "Request wasn't initialized!"); \
} while (0)

#define NewOCSPRes(klass) \
    TypedData_Wrap_Struct((klass), &ossl_ocsp_response_type, 0)
#define SetOCSPRes(obj, res) do { \
    if(!(res)) ossl_raise(rb_eRuntimeError, "Response wasn't initialized!"); \
    RTYPEDDATA_DATA(obj) = (res); \
} while (0)
#define GetOCSPRes(obj, res) do { \
    TypedData_Get_Struct((obj), OCSP_RESPONSE, &ossl_ocsp_response_type, (res)); \
    if(!(res)) ossl_raise(rb_eRuntimeError, "Response wasn't initialized!"); \
} while (0)

#define NewOCSPBasicRes(klass) \
    TypedData_Wrap_Struct((klass), &ossl_ocsp_basicresp_type, 0)
#define SetOCSPBasicRes(obj, res) do { \
    if(!(res)) ossl_raise(rb_eRuntimeError, "Response wasn't initialized!"); \
    RTYPEDDATA_DATA(obj) = (res); \
} while (0)
#define GetOCSPBasicRes(obj, res) do { \
    TypedData_Get_Struct((obj), OCSP_BASICRESP, &ossl_ocsp_basicresp_type, (res)); \
    if(!(res)) ossl_raise(rb_eRuntimeError, "Response wasn't initialized!"); \
} while (0)

#define NewOCSPSingleRes(klass) \
    TypedData_Wrap_Struct((klass), &ossl_ocsp_singleresp_type, 0)
#define SetOCSPSingleRes(obj, res) do { \
    if(!(res)) ossl_raise(rb_eRuntimeError, "SingleResponse wasn't initialized!"); \
    RTYPEDDATA_DATA(obj) = (res); \
} while (0)
#define GetOCSPSingleRes(obj, res) do { \
    TypedData_Get_Struct((obj), OCSP_SINGLERESP, &ossl_ocsp_singleresp_type, (res)); \
    if(!(res)) ossl_raise(rb_eRuntimeError, "SingleResponse wasn't initialized!"); \
} while (0)

#define NewOCSPCertId(klass) \
    TypedData_Wrap_Struct((klass), &ossl_ocsp_certid_type, 0)
#define SetOCSPCertId(obj, cid) do { \
    if(!(cid)) ossl_raise(rb_eRuntimeError, "Cert ID wasn't initialized!"); \
    RTYPEDDATA_DATA(obj) = (cid); \
} while (0)
#define GetOCSPCertId(obj, cid) do { \
    TypedData_Get_Struct((obj), OCSP_CERTID, &ossl_ocsp_certid_type, (cid)); \
    if(!(cid)) ossl_raise(rb_eRuntimeError, "Cert ID wasn't initialized!"); \
} while (0)

VALUE mOCSP;
VALUE eOCSPError;
VALUE cOCSPReq;
VALUE cOCSPRes;
VALUE cOCSPBasicRes;
VALUE cOCSPSingleRes;
VALUE cOCSPCertId;

static void
ossl_ocsp_request_free(void *ptr)
{
    OCSP_REQUEST_free(ptr);
}

static const rb_data_type_t ossl_ocsp_request_type = {
    "OpenSSL/OCSP/REQUEST",
    {
	0, ossl_ocsp_request_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static void
ossl_ocsp_response_free(void *ptr)
{
    OCSP_RESPONSE_free(ptr);
}

static const rb_data_type_t ossl_ocsp_response_type = {
    "OpenSSL/OCSP/RESPONSE",
    {
	0, ossl_ocsp_response_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static void
ossl_ocsp_basicresp_free(void *ptr)
{
    OCSP_BASICRESP_free(ptr);
}

static const rb_data_type_t ossl_ocsp_basicresp_type = {
    "OpenSSL/OCSP/BASICRESP",
    {
	0, ossl_ocsp_basicresp_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static void
ossl_ocsp_singleresp_free(void *ptr)
{
    OCSP_SINGLERESP_free(ptr);
}

static const rb_data_type_t ossl_ocsp_singleresp_type = {
    "OpenSSL/OCSP/SINGLERESP",
    {
	0, ossl_ocsp_singleresp_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static void
ossl_ocsp_certid_free(void *ptr)
{
    OCSP_CERTID_free(ptr);
}

static const rb_data_type_t ossl_ocsp_certid_type = {
    "OpenSSL/OCSP/CERTID",
    {
	0, ossl_ocsp_certid_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

/*
 * Public
 */
static VALUE
ossl_ocspcertid_new(OCSP_CERTID *cid)
{
    VALUE obj = NewOCSPCertId(cOCSPCertId);
    SetOCSPCertId(obj, cid);
    return obj;
}

/*
 * OCSP::Request
 */
static VALUE
ossl_ocspreq_alloc(VALUE klass)
{
    OCSP_REQUEST *req;
    VALUE obj;

    obj = NewOCSPReq(klass);
    if (!(req = OCSP_REQUEST_new()))
	ossl_raise(eOCSPError, NULL);
    SetOCSPReq(obj, req);

    return obj;
}

static VALUE
ossl_ocspreq_initialize_copy(VALUE self, VALUE other)
{
    OCSP_REQUEST *req, *req_old, *req_new;

    rb_check_frozen(self);
    GetOCSPReq(self, req_old);
    GetOCSPReq(other, req);

    req_new = ASN1_item_dup(ASN1_ITEM_rptr(OCSP_REQUEST), req);
    if (!req_new)
	ossl_raise(eOCSPError, "ASN1_item_dup");

    SetOCSPReq(self, req_new);
    OCSP_REQUEST_free(req_old);

    return self;
}

/*
 * call-seq:
 *   OpenSSL::OCSP::Request.new              -> request
 *   OpenSSL::OCSP::Request.new(request_der) -> request
 *
 * Creates a new OpenSSL::OCSP::Request.  The request may be created empty or
 * from a _request_der_ string.
 */

static VALUE
ossl_ocspreq_initialize(int argc, VALUE *argv, VALUE self)
{
    VALUE arg;
    OCSP_REQUEST *req, *req_new;
    const unsigned char *p;

    rb_scan_args(argc, argv, "01", &arg);
    if(!NIL_P(arg)){
	GetOCSPReq(self, req);
	arg = ossl_to_der_if_possible(arg);
	StringValue(arg);
	p = (unsigned char *)RSTRING_PTR(arg);
	req_new = d2i_OCSP_REQUEST(NULL, &p, RSTRING_LEN(arg));
	if (!req_new)
	    ossl_raise(eOCSPError, "d2i_OCSP_REQUEST");
	SetOCSPReq(self, req_new);
	OCSP_REQUEST_free(req);
    }

    return self;
}

/*
 * call-seq:
 *   request.add_nonce(nonce = nil) -> request
 *
 * Adds a _nonce_ to the OCSP request.  If no nonce is given a random one will
 * be generated.
 *
 * The nonce is used to prevent replay attacks but some servers do not support
 * it.
 */

static VALUE
ossl_ocspreq_add_nonce(int argc, VALUE *argv, VALUE self)
{
    OCSP_REQUEST *req;
    VALUE val;
    int ret;

    rb_scan_args(argc, argv, "01", &val);
    if(NIL_P(val)) {
	GetOCSPReq(self, req);
	ret = OCSP_request_add1_nonce(req, NULL, -1);
    }
    else{
	StringValue(val);
	GetOCSPReq(self, req);
	ret = OCSP_request_add1_nonce(req, (unsigned char *)RSTRING_PTR(val), RSTRING_LENINT(val));
    }
    if(!ret) ossl_raise(eOCSPError, NULL);

    return self;
}

/*
 * call-seq:
 *   request.check_nonce(response) -> result
 *
 * Checks the nonce validity for this request and _response_.
 *
 * The return value is one of the following:
 *
 * -1 :: nonce in request only.
 *  0 :: nonces both present and not equal.
 *  1 :: nonces present and equal.
 *  2 :: nonces both absent.
 *  3 :: nonce present in response only.
 *
 * For most responses, clients can check _result_ > 0.  If a responder doesn't
 * handle nonces <code>result.nonzero?</code> may be necessary.  A result of
 * <code>0</code> is always an error.
 */

static VALUE
ossl_ocspreq_check_nonce(VALUE self, VALUE basic_resp)
{
    OCSP_REQUEST *req;
    OCSP_BASICRESP *bs;
    int res;

    GetOCSPReq(self, req);
    GetOCSPBasicRes(basic_resp, bs);
    res = OCSP_check_nonce(req, bs);

    return INT2NUM(res);
}

/*
 * call-seq:
 *   request.add_certid(certificate_id) -> request
 *
 * Adds _certificate_id_ to the request.
 */

static VALUE
ossl_ocspreq_add_certid(VALUE self, VALUE certid)
{
    OCSP_REQUEST *req;
    OCSP_CERTID *id, *id_new;

    GetOCSPReq(self, req);
    GetOCSPCertId(certid, id);

    if (!(id_new = OCSP_CERTID_dup(id)))
	ossl_raise(eOCSPError, "OCSP_CERTID_dup");
    if (!OCSP_request_add0_id(req, id_new)) {
	OCSP_CERTID_free(id_new);
	ossl_raise(eOCSPError, "OCSP_request_add0_id");
    }

    return self;
}

/*
 * call-seq:
 *   request.certid -> [certificate_id, ...]
 *
 * Returns all certificate IDs in this request.
 */

static VALUE
ossl_ocspreq_get_certid(VALUE self)
{
    OCSP_REQUEST *req;
    OCSP_ONEREQ *one;
    OCSP_CERTID *id;
    VALUE ary, tmp;
    int i, count;

    GetOCSPReq(self, req);
    count = OCSP_request_onereq_count(req);
    ary = (count > 0) ? rb_ary_new() : Qnil;
    for(i = 0; i < count; i++){
	one = OCSP_request_onereq_get0(req, i);
	tmp = NewOCSPCertId(cOCSPCertId);
	if(!(id = OCSP_CERTID_dup(OCSP_onereq_get0_id(one))))
	    ossl_raise(eOCSPError, NULL);
	SetOCSPCertId(tmp, id);
	rb_ary_push(ary, tmp);
    }

    return ary;
}

/*
 * call-seq:
 *   request.sign(cert, key, certs = nil, flags = 0, digest = nil) -> self
 *
 * Signs this OCSP request using _cert_, _key_ and optional _digest_. If
 * _digest_ is not specified, SHA-1 is used. _certs_ is an optional Array of
 * additional certificates which are included in the request in addition to
 * the signer certificate. Note that if _certs_ is +nil+ or not given, flag
 * OpenSSL::OCSP::NOCERTS is enabled. Pass an empty array to include only the
 * signer certificate.
 *
 * _flags_ is a bitwise OR of the following constants:
 *
 * OpenSSL::OCSP::NOCERTS::
 *   Don't include any certificates in the request. _certs_ will be ignored.
 */
static VALUE
ossl_ocspreq_sign(int argc, VALUE *argv, VALUE self)
{
    VALUE signer_cert, signer_key, certs, flags, digest;
    OCSP_REQUEST *req;
    X509 *signer;
    EVP_PKEY *key;
    STACK_OF(X509) *x509s = NULL;
    unsigned long flg = 0;
    const EVP_MD *md;
    int ret;

    rb_scan_args(argc, argv, "23", &signer_cert, &signer_key, &certs, &flags, &digest);
    GetOCSPReq(self, req);
    signer = GetX509CertPtr(signer_cert);
    key = GetPrivPKeyPtr(signer_key);
    if (!NIL_P(flags))
	flg = NUM2INT(flags);
    if (NIL_P(digest))
	md = NULL;
    else
	md = ossl_evp_get_digestbyname(digest);
    if (NIL_P(certs))
	flg |= OCSP_NOCERTS;
    else
	x509s = ossl_x509_ary2sk(certs);

    ret = OCSP_request_sign(req, signer, key, md, x509s, flg);
    sk_X509_pop_free(x509s, X509_free);
    if (!ret) ossl_raise(eOCSPError, NULL);

    return self;
}

/*
 * call-seq:
 *   request.verify(certificates, store, flags = 0) -> true or false
 *
 * Verifies this request using the given _certificates_ and _store_.
 * _certificates_ is an array of OpenSSL::X509::Certificate, _store_ is an
 * OpenSSL::X509::Store.
 *
 * Note that +false+ is returned if the request does not have a signature.
 * Use #signed? to check whether the request is signed or not.
 */

static VALUE
ossl_ocspreq_verify(int argc, VALUE *argv, VALUE self)
{
    VALUE certs, store, flags;
    OCSP_REQUEST *req;
    STACK_OF(X509) *x509s;
    X509_STORE *x509st;
    int flg, result;

    rb_scan_args(argc, argv, "21", &certs, &store, &flags);
    GetOCSPReq(self, req);
    x509st = GetX509StorePtr(store);
    flg = NIL_P(flags) ? 0 : NUM2INT(flags);
    x509s = ossl_x509_ary2sk(certs);
    result = OCSP_request_verify(req, x509s, x509st, flg);
    sk_X509_pop_free(x509s, X509_free);
    if (result <= 0)
	ossl_clear_error();

    return result > 0 ? Qtrue : Qfalse;
}

/*
 * Returns this request as a DER-encoded string
 */

static VALUE
ossl_ocspreq_to_der(VALUE self)
{
    OCSP_REQUEST *req;
    VALUE str;
    unsigned char *p;
    long len;

    GetOCSPReq(self, req);
    if((len = i2d_OCSP_REQUEST(req, NULL)) <= 0)
	ossl_raise(eOCSPError, NULL);
    str = rb_str_new(0, len);
    p = (unsigned char *)RSTRING_PTR(str);
    if(i2d_OCSP_REQUEST(req, &p) <= 0)
	ossl_raise(eOCSPError, NULL);
    ossl_str_adjust(str, p);

    return str;
}

/*
 * call-seq:
 *    request.signed? -> true or false
 *
 * Returns +true+ if the request is signed, +false+ otherwise. Note that the
 * validity of the signature is *not* checked. Use #verify to verify that.
 */
static VALUE
ossl_ocspreq_signed_p(VALUE self)
{
    OCSP_REQUEST *req;

    GetOCSPReq(self, req);
    return OCSP_request_is_signed(req) ? Qtrue : Qfalse;
}

/*
 * OCSP::Response
 */

/* call-seq:
 *   OpenSSL::OCSP::Response.create(status, basic_response = nil) -> response
 *
 * Creates an OpenSSL::OCSP::Response from _status_ and _basic_response_.
 */

static VALUE
ossl_ocspres_s_create(VALUE klass, VALUE status, VALUE basic_resp)
{
    OCSP_BASICRESP *bs;
    OCSP_RESPONSE *res;
    VALUE obj;
    int st = NUM2INT(status);

    if(NIL_P(basic_resp)) bs = NULL;
    else GetOCSPBasicRes(basic_resp, bs); /* NO NEED TO DUP */
    obj = NewOCSPRes(klass);
    if(!(res = OCSP_response_create(st, bs)))
	ossl_raise(eOCSPError, NULL);
    SetOCSPRes(obj, res);

    return obj;
}

static VALUE
ossl_ocspres_alloc(VALUE klass)
{
    OCSP_RESPONSE *res;
    VALUE obj;

    obj = NewOCSPRes(klass);
    if(!(res = OCSP_RESPONSE_new()))
	ossl_raise(eOCSPError, NULL);
    SetOCSPRes(obj, res);

    return obj;
}

static VALUE
ossl_ocspres_initialize_copy(VALUE self, VALUE other)
{
    OCSP_RESPONSE *res, *res_old, *res_new;

    rb_check_frozen(self);
    GetOCSPRes(self, res_old);
    GetOCSPRes(other, res);

    res_new = ASN1_item_dup(ASN1_ITEM_rptr(OCSP_RESPONSE), res);
    if (!res_new)
	ossl_raise(eOCSPError, "ASN1_item_dup");

    SetOCSPRes(self, res_new);
    OCSP_RESPONSE_free(res_old);

    return self;
}

/*
 * call-seq:
 *   OpenSSL::OCSP::Response.new               -> response
 *   OpenSSL::OCSP::Response.new(response_der) -> response
 *
 * Creates a new OpenSSL::OCSP::Response.  The response may be created empty or
 * from a _response_der_ string.
 */

static VALUE
ossl_ocspres_initialize(int argc, VALUE *argv, VALUE self)
{
    VALUE arg;
    OCSP_RESPONSE *res, *res_new;
    const unsigned char *p;

    rb_scan_args(argc, argv, "01", &arg);
    if(!NIL_P(arg)){
	GetOCSPRes(self, res);
	arg = ossl_to_der_if_possible(arg);
	StringValue(arg);
	p = (unsigned char *)RSTRING_PTR(arg);
	res_new = d2i_OCSP_RESPONSE(NULL, &p, RSTRING_LEN(arg));
	if (!res_new)
	    ossl_raise(eOCSPError, "d2i_OCSP_RESPONSE");
	SetOCSPRes(self, res_new);
	OCSP_RESPONSE_free(res);
    }

    return self;
}

/*
 * call-seq:
 *   response.status -> Integer
 *
 * Returns the status of the response.
 */

static VALUE
ossl_ocspres_status(VALUE self)
{
    OCSP_RESPONSE *res;
    int st;

    GetOCSPRes(self, res);
    st = OCSP_response_status(res);

    return INT2NUM(st);
}

/*
 * call-seq:
 *   response.status_string -> String
 *
 * Returns a status string for the response.
 */

static VALUE
ossl_ocspres_status_string(VALUE self)
{
    OCSP_RESPONSE *res;
    int st;

    GetOCSPRes(self, res);
    st = OCSP_response_status(res);

    return rb_str_new2(OCSP_response_status_str(st));
}

/*
 * call-seq:
 *   response.basic
 *
 * Returns a BasicResponse for this response
 */

static VALUE
ossl_ocspres_get_basic(VALUE self)
{
    OCSP_RESPONSE *res;
    OCSP_BASICRESP *bs;
    VALUE ret;

    GetOCSPRes(self, res);
    ret = NewOCSPBasicRes(cOCSPBasicRes);
    if(!(bs = OCSP_response_get1_basic(res)))
	return Qnil;
    SetOCSPBasicRes(ret, bs);

    return ret;
}

/*
 * call-seq:
 *   response.to_der -> String
 *
 * Returns this response as a DER-encoded string.
 */

static VALUE
ossl_ocspres_to_der(VALUE self)
{
    OCSP_RESPONSE *res;
    VALUE str;
    long len;
    unsigned char *p;

    GetOCSPRes(self, res);
    if((len = i2d_OCSP_RESPONSE(res, NULL)) <= 0)
	ossl_raise(eOCSPError, NULL);
    str = rb_str_new(0, len);
    p = (unsigned char *)RSTRING_PTR(str);
    if(i2d_OCSP_RESPONSE(res, &p) <= 0)
	ossl_raise(eOCSPError, NULL);
    ossl_str_adjust(str, p);

    return str;
}

/*
 * OCSP::BasicResponse
 */
static VALUE
ossl_ocspbres_alloc(VALUE klass)
{
    OCSP_BASICRESP *bs;
    VALUE obj;

    obj = NewOCSPBasicRes(klass);
    if(!(bs = OCSP_BASICRESP_new()))
	ossl_raise(eOCSPError, NULL);
    SetOCSPBasicRes(obj, bs);

    return obj;
}

static VALUE
ossl_ocspbres_initialize_copy(VALUE self, VALUE other)
{
    OCSP_BASICRESP *bs, *bs_old, *bs_new;

    rb_check_frozen(self);
    GetOCSPBasicRes(self, bs_old);
    GetOCSPBasicRes(other, bs);

    bs_new = ASN1_item_dup(ASN1_ITEM_rptr(OCSP_BASICRESP), bs);
    if (!bs_new)
	ossl_raise(eOCSPError, "ASN1_item_dup");

    SetOCSPBasicRes(self, bs_new);
    OCSP_BASICRESP_free(bs_old);

    return self;
}

/*
 * call-seq:
 *   OpenSSL::OCSP::BasicResponse.new(der_string = nil) -> basic_response
 *
 * Creates a new BasicResponse. If _der_string_ is given, decodes _der_string_
 * as DER.
 */

static VALUE
ossl_ocspbres_initialize(int argc, VALUE *argv, VALUE self)
{
    VALUE arg;
    OCSP_BASICRESP *res, *res_new;
    const unsigned char *p;

    rb_scan_args(argc, argv, "01", &arg);
    if (!NIL_P(arg)) {
	GetOCSPBasicRes(self, res);
	arg = ossl_to_der_if_possible(arg);
	StringValue(arg);
	p = (unsigned char *)RSTRING_PTR(arg);
	res_new = d2i_OCSP_BASICRESP(NULL, &p, RSTRING_LEN(arg));
	if (!res_new)
	    ossl_raise(eOCSPError, "d2i_OCSP_BASICRESP");
	SetOCSPBasicRes(self, res_new);
	OCSP_BASICRESP_free(res);
    }

    return self;
}

/*
 * call-seq:
 *   basic_response.copy_nonce(request) -> Integer
 *
 * Copies the nonce from _request_ into this response.  Returns 1 on success
 * and 0 on failure.
 */

static VALUE
ossl_ocspbres_copy_nonce(VALUE self, VALUE request)
{
    OCSP_BASICRESP *bs;
    OCSP_REQUEST *req;
    int ret;

    GetOCSPBasicRes(self, bs);
    GetOCSPReq(request, req);
    ret = OCSP_copy_nonce(bs, req);

    return INT2NUM(ret);
}

/*
 * call-seq:
 *   basic_response.add_nonce(nonce = nil)
 *
 * Adds _nonce_ to this response.  If no nonce was provided a random nonce
 * will be added.
 */

static VALUE
ossl_ocspbres_add_nonce(int argc, VALUE *argv, VALUE self)
{
    OCSP_BASICRESP *bs;
    VALUE val;
    int ret;

    rb_scan_args(argc, argv, "01", &val);
    if(NIL_P(val)) {
	GetOCSPBasicRes(self, bs);
	ret = OCSP_basic_add1_nonce(bs, NULL, -1);
    }
    else{
	StringValue(val);
	GetOCSPBasicRes(self, bs);
	ret = OCSP_basic_add1_nonce(bs, (unsigned char *)RSTRING_PTR(val), RSTRING_LENINT(val));
    }
    if(!ret) ossl_raise(eOCSPError, NULL);

    return self;
}

static VALUE
add_status_convert_time(VALUE obj)
{
    ASN1_TIME *time;

    if (RB_INTEGER_TYPE_P(obj))
	time = X509_gmtime_adj(NULL, NUM2INT(obj));
    else
	time = ossl_x509_time_adjust(NULL, obj);

    if (!time)
	ossl_raise(eOCSPError, NULL);

    return (VALUE)time;
}

/*
 * call-seq:
 *   basic_response.add_status(certificate_id, status, reason, revocation_time, this_update, next_update, extensions) -> basic_response
 *
 * Adds a certificate status for _certificate_id_. _status_ is the status, and
 * must be one of these:
 *
 * - OpenSSL::OCSP::V_CERTSTATUS_GOOD
 * - OpenSSL::OCSP::V_CERTSTATUS_REVOKED
 * - OpenSSL::OCSP::V_CERTSTATUS_UNKNOWN
 *
 * _reason_ and _revocation_time_ can be given only when _status_ is
 * OpenSSL::OCSP::V_CERTSTATUS_REVOKED. _reason_ describes the reason for the
 * revocation, and must be one of OpenSSL::OCSP::REVOKED_STATUS_* constants.
 * _revocation_time_ is the time when the certificate is revoked.
 *
 * _this_update_ and _next_update_ indicate the time at which the status is
 * verified to be correct and the time at or before which newer information
 * will be available, respectively. _next_update_ is optional.
 *
 * _extensions_ is an Array of OpenSSL::X509::Extension to be included in the
 * SingleResponse. This is also optional.
 *
 * Note that the times, _revocation_time_, _this_update_ and _next_update_
 * can be specified in either of Integer or Time object. If they are Integer, it
 * is treated as the relative seconds from the current time.
 */
static VALUE
ossl_ocspbres_add_status(VALUE self, VALUE cid, VALUE status,
			 VALUE reason, VALUE revtime,
			 VALUE thisupd, VALUE nextupd, VALUE ext)
{
    OCSP_BASICRESP *bs;
    OCSP_SINGLERESP *single;
    OCSP_CERTID *id;
    ASN1_TIME *ths = NULL, *nxt = NULL, *rev = NULL;
    int st, rsn = 0, error = 0, rstatus = 0;
    long i;
    VALUE tmp;

    GetOCSPBasicRes(self, bs);
    GetOCSPCertId(cid, id);
    st = NUM2INT(status);
    if (!NIL_P(ext)) { /* All ext's members must be X509::Extension */
	ext = rb_check_array_type(ext);
	for (i = 0; i < RARRAY_LEN(ext); i++)
	    OSSL_Check_Kind(RARRAY_AREF(ext, i), cX509Ext);
    }

    if (st == V_OCSP_CERTSTATUS_REVOKED) {
	rsn = NUM2INT(reason);
	tmp = rb_protect(add_status_convert_time, revtime, &rstatus);
	if (rstatus) goto err;
	rev = (ASN1_TIME *)tmp;
    }

    tmp = rb_protect(add_status_convert_time, thisupd, &rstatus);
    if (rstatus) goto err;
    ths = (ASN1_TIME *)tmp;

    if (!NIL_P(nextupd)) {
	tmp = rb_protect(add_status_convert_time, nextupd, &rstatus);
	if (rstatus) goto err;
	nxt = (ASN1_TIME *)tmp;
    }

    if(!(single = OCSP_basic_add1_status(bs, id, st, rsn, rev, ths, nxt))){
	error = 1;
	goto err;
    }

    if(!NIL_P(ext)){
	X509_EXTENSION *x509ext;

	for(i = 0; i < RARRAY_LEN(ext); i++){
	    x509ext = GetX509ExtPtr(RARRAY_AREF(ext, i));
	    if(!OCSP_SINGLERESP_add_ext(single, x509ext, -1)){
		error = 1;
		goto err;
	    }
	}
    }

 err:
    ASN1_TIME_free(ths);
    ASN1_TIME_free(nxt);
    ASN1_TIME_free(rev);
    if(error) ossl_raise(eOCSPError, NULL);
    if(rstatus) rb_jump_tag(rstatus);

    return self;
}

/*
 * call-seq:
 *   basic_response.status -> statuses
 *
 * Returns an Array of statuses for this response.  Each status contains a
 * CertificateId, the status (0 for good, 1 for revoked, 2 for unknown), the
 * reason for the status, the revocation time, the time of this update, the time
 * for the next update and a list of OpenSSL::X509::Extension.
 *
 * This should be superseded by BasicResponse#responses and #find_response that
 * return SingleResponse.
 */
static VALUE
ossl_ocspbres_get_status(VALUE self)
{
    OCSP_BASICRESP *bs;
    OCSP_SINGLERESP *single;
    OCSP_CERTID *cid;
    ASN1_TIME *revtime, *thisupd, *nextupd;
    int status, reason;
    X509_EXTENSION *x509ext;
    VALUE ret, ary, ext;
    int count, ext_count, i, j;

    GetOCSPBasicRes(self, bs);
    ret = rb_ary_new();
    count = OCSP_resp_count(bs);
    for(i = 0; i < count; i++){
	single = OCSP_resp_get0(bs, i);
	if(!single) continue;

	revtime = thisupd = nextupd = NULL;
	status = OCSP_single_get0_status(single, &reason, &revtime,
					 &thisupd, &nextupd);
	if(status < 0) continue;
	if(!(cid = OCSP_CERTID_dup((OCSP_CERTID *)OCSP_SINGLERESP_get0_id(single)))) /* FIXME */
	    ossl_raise(eOCSPError, NULL);
	ary = rb_ary_new();
	rb_ary_push(ary, ossl_ocspcertid_new(cid));
	rb_ary_push(ary, INT2NUM(status));
	rb_ary_push(ary, INT2NUM(reason));
	rb_ary_push(ary, revtime ? asn1time_to_time(revtime) : Qnil);
	rb_ary_push(ary, thisupd ? asn1time_to_time(thisupd) : Qnil);
	rb_ary_push(ary, nextupd ? asn1time_to_time(nextupd) : Qnil);
	ext = rb_ary_new();
	ext_count = OCSP_SINGLERESP_get_ext_count(single);
	for(j = 0; j < ext_count; j++){
	    x509ext = OCSP_SINGLERESP_get_ext(single, j);
	    rb_ary_push(ext, ossl_x509ext_new(x509ext));
	}
	rb_ary_push(ary, ext);
	rb_ary_push(ret, ary);
    }

    return ret;
}

static VALUE ossl_ocspsres_new(OCSP_SINGLERESP *);

/*
 * call-seq:
 *   basic_response.responses -> Array of SingleResponse
 *
 * Returns an Array of SingleResponse for this BasicResponse.
 */

static VALUE
ossl_ocspbres_get_responses(VALUE self)
{
    OCSP_BASICRESP *bs;
    VALUE ret;
    int count, i;

    GetOCSPBasicRes(self, bs);
    count = OCSP_resp_count(bs);
    ret = rb_ary_new2(count);

    for (i = 0; i < count; i++) {
	OCSP_SINGLERESP *sres, *sres_new;

	sres = OCSP_resp_get0(bs, i);
	sres_new = ASN1_item_dup(ASN1_ITEM_rptr(OCSP_SINGLERESP), sres);
	if (!sres_new)
	    ossl_raise(eOCSPError, "ASN1_item_dup");

	rb_ary_push(ret, ossl_ocspsres_new(sres_new));
    }

    return ret;
}


/*
 * call-seq:
 *   basic_response.find_response(certificate_id) -> SingleResponse | nil
 *
 * Returns a SingleResponse whose CertId matches with _certificate_id_, or +nil+
 * if this BasicResponse does not contain it.
 */
static VALUE
ossl_ocspbres_find_response(VALUE self, VALUE target)
{
    OCSP_BASICRESP *bs;
    OCSP_SINGLERESP *sres, *sres_new;
    OCSP_CERTID *id;
    int n;

    GetOCSPCertId(target, id);
    GetOCSPBasicRes(self, bs);

    if ((n = OCSP_resp_find(bs, id, -1)) == -1)
	return Qnil;

    sres = OCSP_resp_get0(bs, n);
    sres_new = ASN1_item_dup(ASN1_ITEM_rptr(OCSP_SINGLERESP), sres);
    if (!sres_new)
	ossl_raise(eOCSPError, "ASN1_item_dup");

    return ossl_ocspsres_new(sres_new);
}

/*
 * call-seq:
 *   basic_response.sign(cert, key, certs = nil, flags = 0, digest = nil) -> self
 *
 * Signs this OCSP response using the _cert_, _key_ and optional _digest_. This
 * behaves in the similar way as OpenSSL::OCSP::Request#sign.
 *
 * _flags_ can include:
 * OpenSSL::OCSP::NOCERTS::    don't include certificates
 * OpenSSL::OCSP::NOTIME::     don't set producedAt
 * OpenSSL::OCSP::RESPID_KEY:: use signer's public key hash as responderID
 */

static VALUE
ossl_ocspbres_sign(int argc, VALUE *argv, VALUE self)
{
    VALUE signer_cert, signer_key, certs, flags, digest;
    OCSP_BASICRESP *bs;
    X509 *signer;
    EVP_PKEY *key;
    STACK_OF(X509) *x509s = NULL;
    unsigned long flg = 0;
    const EVP_MD *md;
    int ret;

    rb_scan_args(argc, argv, "23", &signer_cert, &signer_key, &certs, &flags, &digest);
    GetOCSPBasicRes(self, bs);
    signer = GetX509CertPtr(signer_cert);
    key = GetPrivPKeyPtr(signer_key);
    if (!NIL_P(flags))
	flg = NUM2INT(flags);
    if (NIL_P(digest))
	md = NULL;
    else
	md = ossl_evp_get_digestbyname(digest);
    if (NIL_P(certs))
	flg |= OCSP_NOCERTS;
    else
	x509s = ossl_x509_ary2sk(certs);

    ret = OCSP_basic_sign(bs, signer, key, md, x509s, flg);
    sk_X509_pop_free(x509s, X509_free);
    if (!ret) ossl_raise(eOCSPError, NULL);

    return self;
}

/*
 * call-seq:
 *   basic_response.verify(certificates, store, flags = 0) -> true or false
 *
 * Verifies the signature of the response using the given _certificates_ and
 * _store_. This works in the similar way as OpenSSL::OCSP::Request#verify.
 */
static VALUE
ossl_ocspbres_verify(int argc, VALUE *argv, VALUE self)
{
    VALUE certs, store, flags;
    OCSP_BASICRESP *bs;
    STACK_OF(X509) *x509s;
    X509_STORE *x509st;
    int flg, result;

    rb_scan_args(argc, argv, "21", &certs, &store, &flags);
    GetOCSPBasicRes(self, bs);
    x509st = GetX509StorePtr(store);
    flg = NIL_P(flags) ? 0 : NUM2INT(flags);
    x509s = ossl_x509_ary2sk(certs);
    result = OCSP_basic_verify(bs, x509s, x509st, flg);
    sk_X509_pop_free(x509s, X509_free);
    if (result <= 0)
	ossl_clear_error();

    return result > 0 ? Qtrue : Qfalse;
}

/*
 * call-seq:
 *   basic_response.to_der -> String
 *
 * Encodes this basic response into a DER-encoded string.
 */
static VALUE
ossl_ocspbres_to_der(VALUE self)
{
    OCSP_BASICRESP *res;
    VALUE str;
    long len;
    unsigned char *p;

    GetOCSPBasicRes(self, res);
    if ((len = i2d_OCSP_BASICRESP(res, NULL)) <= 0)
	ossl_raise(eOCSPError, NULL);
    str = rb_str_new(0, len);
    p = (unsigned char *)RSTRING_PTR(str);
    if (i2d_OCSP_BASICRESP(res, &p) <= 0)
	ossl_raise(eOCSPError, NULL);
    ossl_str_adjust(str, p);

    return str;
}

/*
 * OCSP::SingleResponse
 */
static VALUE
ossl_ocspsres_new(OCSP_SINGLERESP *sres)
{
    VALUE obj;

    obj = NewOCSPSingleRes(cOCSPSingleRes);
    SetOCSPSingleRes(obj, sres);

    return obj;
}

static VALUE
ossl_ocspsres_alloc(VALUE klass)
{
    OCSP_SINGLERESP *sres;
    VALUE obj;

    obj = NewOCSPSingleRes(klass);
    if (!(sres = OCSP_SINGLERESP_new()))
	ossl_raise(eOCSPError, NULL);
    SetOCSPSingleRes(obj, sres);

    return obj;
}

/*
 * call-seq:
 *   OpenSSL::OCSP::SingleResponse.new(der_string) -> SingleResponse
 *
 * Creates a new SingleResponse from _der_string_.
 */
static VALUE
ossl_ocspsres_initialize(VALUE self, VALUE arg)
{
    OCSP_SINGLERESP *res, *res_new;
    const unsigned char *p;

    arg = ossl_to_der_if_possible(arg);
    StringValue(arg);
    GetOCSPSingleRes(self, res);

    p = (unsigned char*)RSTRING_PTR(arg);
    res_new = d2i_OCSP_SINGLERESP(NULL, &p, RSTRING_LEN(arg));
    if (!res_new)
	ossl_raise(eOCSPError, "d2i_OCSP_SINGLERESP");
    SetOCSPSingleRes(self, res_new);
    OCSP_SINGLERESP_free(res);

    return self;
}

static VALUE
ossl_ocspsres_initialize_copy(VALUE self, VALUE other)
{
    OCSP_SINGLERESP *sres, *sres_old, *sres_new;

    rb_check_frozen(self);
    GetOCSPSingleRes(self, sres_old);
    GetOCSPSingleRes(other, sres);

    sres_new = ASN1_item_dup(ASN1_ITEM_rptr(OCSP_SINGLERESP), sres);
    if (!sres_new)
	ossl_raise(eOCSPError, "ASN1_item_dup");

    SetOCSPSingleRes(self, sres_new);
    OCSP_SINGLERESP_free(sres_old);

    return self;
}

/*
 * call-seq:
 *   single_response.check_validity(nsec = 0, maxsec = -1) -> true | false
 *
 * Checks the validity of thisUpdate and nextUpdate fields of this
 * SingleResponse. This checks the current time is within the range thisUpdate
 * to nextUpdate.
 *
 * It is possible that the OCSP request takes a few seconds or the time is not
 * accurate. To avoid rejecting a valid response, this method allows the times
 * to be within _nsec_ seconds of the current time.
 *
 * Some responders don't set the nextUpdate field. This may cause a very old
 * response to be considered valid. The _maxsec_ parameter can be used to limit
 * the age of responses.
 */
static VALUE
ossl_ocspsres_check_validity(int argc, VALUE *argv, VALUE self)
{
    OCSP_SINGLERESP *sres;
    ASN1_GENERALIZEDTIME *this_update, *next_update;
    VALUE nsec_v, maxsec_v;
    int nsec, maxsec, status, ret;

    rb_scan_args(argc, argv, "02", &nsec_v, &maxsec_v);
    nsec = NIL_P(nsec_v) ? 0 : NUM2INT(nsec_v);
    maxsec = NIL_P(maxsec_v) ? -1 : NUM2INT(maxsec_v);

    GetOCSPSingleRes(self, sres);
    status = OCSP_single_get0_status(sres, NULL, NULL, &this_update, &next_update);
    if (status < 0)
	ossl_raise(eOCSPError, "OCSP_single_get0_status");

    ret = OCSP_check_validity(this_update, next_update, nsec, maxsec);

    if (ret)
	return Qtrue;
    else {
	ossl_clear_error();
	return Qfalse;
    }
}

/*
 * call-seq:
 *   single_response.certid -> CertificateId
 *
 * Returns the CertificateId for which this SingleResponse is.
 */
static VALUE
ossl_ocspsres_get_certid(VALUE self)
{
    OCSP_SINGLERESP *sres;
    OCSP_CERTID *id;

    GetOCSPSingleRes(self, sres);
    id = OCSP_CERTID_dup((OCSP_CERTID *)OCSP_SINGLERESP_get0_id(sres)); /* FIXME */

    return ossl_ocspcertid_new(id);
}

/*
 * call-seq:
 *   single_response.cert_status -> Integer
 *
 * Returns the status of the certificate identified by the certid.
 * The return value may be one of these constant:
 *
 * - V_CERTSTATUS_GOOD
 * - V_CERTSTATUS_REVOKED
 * - V_CERTSTATUS_UNKNOWN
 *
 * When the status is V_CERTSTATUS_REVOKED, the time at which the certificate
 * was revoked can be retrieved by #revocation_time.
 */
static VALUE
ossl_ocspsres_get_cert_status(VALUE self)
{
    OCSP_SINGLERESP *sres;
    int status;

    GetOCSPSingleRes(self, sres);
    status = OCSP_single_get0_status(sres, NULL, NULL, NULL, NULL);
    if (status < 0)
	ossl_raise(eOCSPError, "OCSP_single_get0_status");

    return INT2NUM(status);
}

/*
 * call-seq:
 *   single_response.this_update -> Time
 */
static VALUE
ossl_ocspsres_get_this_update(VALUE self)
{
    OCSP_SINGLERESP *sres;
    int status;
    ASN1_GENERALIZEDTIME *time;

    GetOCSPSingleRes(self, sres);
    status = OCSP_single_get0_status(sres, NULL, NULL, &time, NULL);
    if (status < 0)
	ossl_raise(eOCSPError, "OCSP_single_get0_status");
    if (!time)
	return Qnil;

    return asn1time_to_time(time);
}

/*
 * call-seq:
 *   single_response.next_update -> Time | nil
 */
static VALUE
ossl_ocspsres_get_next_update(VALUE self)
{
    OCSP_SINGLERESP *sres;
    int status;
    ASN1_GENERALIZEDTIME *time;

    GetOCSPSingleRes(self, sres);
    status = OCSP_single_get0_status(sres, NULL, NULL, NULL, &time);
    if (status < 0)
	ossl_raise(eOCSPError, "OCSP_single_get0_status");
    if (!time)
	return Qnil;

    return asn1time_to_time(time);
}

/*
 * call-seq:
 *   single_response.revocation_time -> Time | nil
 */
static VALUE
ossl_ocspsres_get_revocation_time(VALUE self)
{
    OCSP_SINGLERESP *sres;
    int status;
    ASN1_GENERALIZEDTIME *time;

    GetOCSPSingleRes(self, sres);
    status = OCSP_single_get0_status(sres, NULL, &time, NULL, NULL);
    if (status < 0)
	ossl_raise(eOCSPError, "OCSP_single_get0_status");
    if (status != V_OCSP_CERTSTATUS_REVOKED)
	ossl_raise(eOCSPError, "certificate is not revoked");
    if (!time)
	return Qnil;

    return asn1time_to_time(time);
}

/*
 * call-seq:
 *   single_response.revocation_reason -> Integer | nil
 */
static VALUE
ossl_ocspsres_get_revocation_reason(VALUE self)
{
    OCSP_SINGLERESP *sres;
    int status, reason;

    GetOCSPSingleRes(self, sres);
    status = OCSP_single_get0_status(sres, &reason, NULL, NULL, NULL);
    if (status < 0)
	ossl_raise(eOCSPError, "OCSP_single_get0_status");
    if (status != V_OCSP_CERTSTATUS_REVOKED)
	ossl_raise(eOCSPError, "certificate is not revoked");

    return INT2NUM(reason);
}

/*
 * call-seq:
 *   single_response.extensions -> Array of X509::Extension
 */
static VALUE
ossl_ocspsres_get_extensions(VALUE self)
{
    OCSP_SINGLERESP *sres;
    X509_EXTENSION *ext;
    int count, i;
    VALUE ary;

    GetOCSPSingleRes(self, sres);

    count = OCSP_SINGLERESP_get_ext_count(sres);
    ary = rb_ary_new2(count);
    for (i = 0; i < count; i++) {
	ext = OCSP_SINGLERESP_get_ext(sres, i);
	rb_ary_push(ary, ossl_x509ext_new(ext)); /* will dup */
    }

    return ary;
}

/*
 * call-seq:
 *   single_response.to_der -> String
 *
 * Encodes this SingleResponse into a DER-encoded string.
 */
static VALUE
ossl_ocspsres_to_der(VALUE self)
{
    OCSP_SINGLERESP *sres;
    VALUE str;
    long len;
    unsigned char *p;

    GetOCSPSingleRes(self, sres);
    if ((len = i2d_OCSP_SINGLERESP(sres, NULL)) <= 0)
	ossl_raise(eOCSPError, NULL);
    str = rb_str_new(0, len);
    p = (unsigned char *)RSTRING_PTR(str);
    if (i2d_OCSP_SINGLERESP(sres, &p) <= 0)
	ossl_raise(eOCSPError, NULL);
    ossl_str_adjust(str, p);

    return str;
}


/*
 * OCSP::CertificateId
 */
static VALUE
ossl_ocspcid_alloc(VALUE klass)
{
    OCSP_CERTID *id;
    VALUE obj;

    obj = NewOCSPCertId(klass);
    if(!(id = OCSP_CERTID_new()))
	ossl_raise(eOCSPError, NULL);
    SetOCSPCertId(obj, id);

    return obj;
}

static VALUE
ossl_ocspcid_initialize_copy(VALUE self, VALUE other)
{
    OCSP_CERTID *cid, *cid_old, *cid_new;

    rb_check_frozen(self);
    GetOCSPCertId(self, cid_old);
    GetOCSPCertId(other, cid);

    cid_new = OCSP_CERTID_dup(cid);
    if (!cid_new)
	ossl_raise(eOCSPError, "OCSP_CERTID_dup");

    SetOCSPCertId(self, cid_new);
    OCSP_CERTID_free(cid_old);

    return self;
}

/*
 * call-seq:
 *   OpenSSL::OCSP::CertificateId.new(subject, issuer, digest = nil) -> certificate_id
 *   OpenSSL::OCSP::CertificateId.new(der_string)                    -> certificate_id
 *   OpenSSL::OCSP::CertificateId.new(obj)                           -> certificate_id
 *
 * Creates a new OpenSSL::OCSP::CertificateId for the given _subject_ and
 * _issuer_ X509 certificates.  The _digest_ is a digest algorithm that is used
 * to compute the hash values. This defaults to SHA-1.
 *
 * If only one argument is given, decodes it as DER representation of a
 * certificate ID or generates certificate ID from the object that responds to
 * the to_der method.
 */
static VALUE
ossl_ocspcid_initialize(int argc, VALUE *argv, VALUE self)
{
    OCSP_CERTID *id, *newid;
    VALUE subject, issuer, digest;

    GetOCSPCertId(self, id);
    if (rb_scan_args(argc, argv, "12", &subject, &issuer, &digest) == 1) {
	VALUE arg;
	const unsigned char *p;

	arg = ossl_to_der_if_possible(subject);
	StringValue(arg);
	p = (unsigned char *)RSTRING_PTR(arg);
	newid = d2i_OCSP_CERTID(NULL, &p, RSTRING_LEN(arg));
	if (!newid)
	    ossl_raise(eOCSPError, "d2i_OCSP_CERTID");
    }
    else {
	X509 *x509s, *x509i;
	const EVP_MD *md;

	x509s = GetX509CertPtr(subject); /* NO NEED TO DUP */
	x509i = GetX509CertPtr(issuer); /* NO NEED TO DUP */
	md = !NIL_P(digest) ? ossl_evp_get_digestbyname(digest) : NULL;

	newid = OCSP_cert_to_id(md, x509s, x509i);
	if (!newid)
	    ossl_raise(eOCSPError, "OCSP_cert_to_id");
    }

    SetOCSPCertId(self, newid);
    OCSP_CERTID_free(id);

    return self;
}

/*
 * call-seq:
 *   certificate_id.cmp(other) -> true or false
 *
 * Compares this certificate id with _other_ and returns +true+ if they are the
 * same.
 */
static VALUE
ossl_ocspcid_cmp(VALUE self, VALUE other)
{
    OCSP_CERTID *id, *id2;
    int result;

    GetOCSPCertId(self, id);
    GetOCSPCertId(other, id2);
    result = OCSP_id_cmp(id, id2);

    return (result == 0) ? Qtrue : Qfalse;
}

/*
 * call-seq:
 *   certificate_id.cmp_issuer(other) -> true or false
 *
 * Compares this certificate id's issuer with _other_ and returns +true+ if
 * they are the same.
 */

static VALUE
ossl_ocspcid_cmp_issuer(VALUE self, VALUE other)
{
    OCSP_CERTID *id, *id2;
    int result;

    GetOCSPCertId(self, id);
    GetOCSPCertId(other, id2);
    result = OCSP_id_issuer_cmp(id, id2);

    return (result == 0) ? Qtrue : Qfalse;
}

/*
 * call-seq:
 *   certificate_id.serial -> Integer
 *
 * Returns the serial number of the certificate for which status is being
 * requested.
 */
static VALUE
ossl_ocspcid_get_serial(VALUE self)
{
    OCSP_CERTID *id;
    ASN1_INTEGER *serial;

    GetOCSPCertId(self, id);
    OCSP_id_get0_info(NULL, NULL, NULL, &serial, id);

    return asn1integer_to_num(serial);
}

/*
 * call-seq:
 *   certificate_id.issuer_name_hash -> String
 *
 * Returns the issuerNameHash of this certificate ID, the hash of the
 * issuer's distinguished name calculated with the hashAlgorithm.
 */
static VALUE
ossl_ocspcid_get_issuer_name_hash(VALUE self)
{
    OCSP_CERTID *id;
    ASN1_OCTET_STRING *name_hash;
    VALUE ret;

    GetOCSPCertId(self, id);
    OCSP_id_get0_info(&name_hash, NULL, NULL, NULL, id);

    ret = rb_str_new(NULL, name_hash->length * 2);
    ossl_bin2hex(name_hash->data, RSTRING_PTR(ret), name_hash->length);

    return ret;
}

/*
 * call-seq:
 *   certificate_id.issuer_key_hash -> String
 *
 * Returns the issuerKeyHash of this certificate ID, the hash of the issuer's
 * public key.
 */
static VALUE
ossl_ocspcid_get_issuer_key_hash(VALUE self)
{
    OCSP_CERTID *id;
    ASN1_OCTET_STRING *key_hash;
    VALUE ret;

    GetOCSPCertId(self, id);
    OCSP_id_get0_info(NULL, NULL, &key_hash, NULL, id);

    ret = rb_str_new(NULL, key_hash->length * 2);
    ossl_bin2hex(key_hash->data, RSTRING_PTR(ret), key_hash->length);

    return ret;
}

/*
 * call-seq:
 *   certificate_id.hash_algorithm -> String
 *
 * Returns the ln (long name) of the hash algorithm used to generate
 * the issuerNameHash and the issuerKeyHash values.
 */
static VALUE
ossl_ocspcid_get_hash_algorithm(VALUE self)
{
    OCSP_CERTID *id;
    ASN1_OBJECT *oid;
    BIO *out;

    GetOCSPCertId(self, id);
    OCSP_id_get0_info(NULL, &oid, NULL, NULL, id);

    if (!(out = BIO_new(BIO_s_mem())))
	ossl_raise(eOCSPError, "BIO_new");

    if (!i2a_ASN1_OBJECT(out, oid)) {
	BIO_free(out);
	ossl_raise(eOCSPError, "i2a_ASN1_OBJECT");
    }
    return ossl_membio2str(out);
}

/*
 * call-seq:
 *   certificate_id.to_der -> String
 *
 * Encodes this certificate identifier into a DER-encoded string.
 */
static VALUE
ossl_ocspcid_to_der(VALUE self)
{
    OCSP_CERTID *id;
    VALUE str;
    long len;
    unsigned char *p;

    GetOCSPCertId(self, id);
    if ((len = i2d_OCSP_CERTID(id, NULL)) <= 0)
	ossl_raise(eOCSPError, NULL);
    str = rb_str_new(0, len);
    p = (unsigned char *)RSTRING_PTR(str);
    if (i2d_OCSP_CERTID(id, &p) <= 0)
	ossl_raise(eOCSPError, NULL);
    ossl_str_adjust(str, p);

    return str;
}

void
Init_ossl_ocsp(void)
{
#if 0
    mOSSL = rb_define_module("OpenSSL");
    eOSSLError = rb_define_class_under(mOSSL, "OpenSSLError", rb_eStandardError);
#endif

    /*
     * OpenSSL::OCSP implements Online Certificate Status Protocol requests
     * and responses.
     *
     * Creating and sending an OCSP request requires a subject certificate
     * that contains an OCSP URL in an authorityInfoAccess extension and the
     * issuer certificate for the subject certificate.  First, load the issuer
     * and subject certificates:
     *
     *   subject = OpenSSL::X509::Certificate.new subject_pem
     *   issuer  = OpenSSL::X509::Certificate.new issuer_pem
     *
     * To create the request we need to create a certificate ID for the
     * subject certificate so the CA knows which certificate we are asking
     * about:
     *
     *   digest = OpenSSL::Digest.new('SHA1')
     *   certificate_id =
     *     OpenSSL::OCSP::CertificateId.new subject, issuer, digest
     *
     * Then create a request and add the certificate ID to it:
     *
     *   request = OpenSSL::OCSP::Request.new
     *   request.add_certid certificate_id
     *
     * Adding a nonce to the request protects against replay attacks but not
     * all CA process the nonce.
     *
     *   request.add_nonce
     *
     * To submit the request to the CA for verification we need to extract the
     * OCSP URI from the subject certificate:
     *
     *   ocsp_uris = subject.ocsp_uris
     *
     *   require 'uri'
     *
     *   ocsp_uri = URI ocsp_uris[0]
     *
     * To submit the request we'll POST the request to the OCSP URI (per RFC
     * 2560).  Note that we only handle HTTP requests and don't handle any
     * redirects in this example, so this is insufficient for serious use.
     *
     *   require 'net/http'
     *
     *   http_response =
     *     Net::HTTP.start ocsp_uri.hostname, ocsp_uri.port do |http|
     *       http.post ocsp_uri.path, request.to_der,
     *                 'content-type' => 'application/ocsp-request'
     *   end
     *
     *   response = OpenSSL::OCSP::Response.new http_response.body
     *   response_basic = response.basic
     *
     * First we check if the response has a valid signature.  Without a valid
     * signature we cannot trust it.  If you get a failure here you may be
     * missing a system certificate store or may be missing the intermediate
     * certificates.
     *
     *   store = OpenSSL::X509::Store.new
     *   store.set_default_paths
     *
     *   unless response_basic.verify [], store then
     *     raise 'response is not signed by a trusted certificate'
     *   end
     *
     * The response contains the status information (success/fail).  We can
     * display the status as a string:
     *
     *   puts response.status_string #=> successful
     *
     * Next we need to know the response details to determine if the response
     * matches our request.  First we check the nonce.  Again, not all CAs
     * support a nonce.  See Request#check_nonce for the meanings of the
     * return values.
     *
     *   p request.check_nonce basic_response #=> value from -1 to 3
     *
     * Then extract the status information for the certificate from the basic
     * response.
     *
     *   single_response = basic_response.find_response(certificate_id)
     *
     *   unless single_response
     *     raise 'basic_response does not have the status for the certificate'
     *   end
     *
     * Then check the validity. A status issued in the future must be rejected.
     *
     *   unless single_response.check_validity
     *     raise 'this_update is in the future or next_update time has passed'
     *   end
     *
     *   case single_response.cert_status
     *   when OpenSSL::OCSP::V_CERTSTATUS_GOOD
     *     puts 'certificate is still valid'
     *   when OpenSSL::OCSP::V_CERTSTATUS_REVOKED
     *     puts "certificate has been revoked at #{single_response.revocation_time}"
     *   when OpenSSL::OCSP::V_CERTSTATUS_UNKNOWN
     *     puts 'responder doesn't know about the certificate'
     *   end
     */

    mOCSP = rb_define_module_under(mOSSL, "OCSP");

    /*
     * OCSP error class.
     */

    eOCSPError = rb_define_class_under(mOCSP, "OCSPError", eOSSLError);

    /*
     * An OpenSSL::OCSP::Request contains the certificate information for
     * determining if a certificate has been revoked or not.  A Request can be
     * created for a certificate or from a DER-encoded request created
     * elsewhere.
     */

    cOCSPReq = rb_define_class_under(mOCSP, "Request", rb_cObject);
    rb_define_alloc_func(cOCSPReq, ossl_ocspreq_alloc);
    rb_define_method(cOCSPReq, "initialize_copy", ossl_ocspreq_initialize_copy, 1);
    rb_define_method(cOCSPReq, "initialize", ossl_ocspreq_initialize, -1);
    rb_define_method(cOCSPReq, "add_nonce", ossl_ocspreq_add_nonce, -1);
    rb_define_method(cOCSPReq, "check_nonce", ossl_ocspreq_check_nonce, 1);
    rb_define_method(cOCSPReq, "add_certid", ossl_ocspreq_add_certid, 1);
    rb_define_method(cOCSPReq, "certid", ossl_ocspreq_get_certid, 0);
    rb_define_method(cOCSPReq, "signed?", ossl_ocspreq_signed_p, 0);
    rb_define_method(cOCSPReq, "sign", ossl_ocspreq_sign, -1);
    rb_define_method(cOCSPReq, "verify", ossl_ocspreq_verify, -1);
    rb_define_method(cOCSPReq, "to_der", ossl_ocspreq_to_der, 0);

    /*
     * An OpenSSL::OCSP::Response contains the status of a certificate check
     * which is created from an OpenSSL::OCSP::Request.
     */

    cOCSPRes = rb_define_class_under(mOCSP, "Response", rb_cObject);
    rb_define_singleton_method(cOCSPRes, "create", ossl_ocspres_s_create, 2);
    rb_define_alloc_func(cOCSPRes, ossl_ocspres_alloc);
    rb_define_method(cOCSPRes, "initialize_copy", ossl_ocspres_initialize_copy, 1);
    rb_define_method(cOCSPRes, "initialize", ossl_ocspres_initialize, -1);
    rb_define_method(cOCSPRes, "status", ossl_ocspres_status, 0);
    rb_define_method(cOCSPRes, "status_string", ossl_ocspres_status_string, 0);
    rb_define_method(cOCSPRes, "basic", ossl_ocspres_get_basic, 0);
    rb_define_method(cOCSPRes, "to_der", ossl_ocspres_to_der, 0);

    /*
     * An OpenSSL::OCSP::BasicResponse contains the status of a certificate
     * check which is created from an OpenSSL::OCSP::Request.  A
     * BasicResponse is more detailed than a Response.
     */

    cOCSPBasicRes = rb_define_class_under(mOCSP, "BasicResponse", rb_cObject);
    rb_define_alloc_func(cOCSPBasicRes, ossl_ocspbres_alloc);
    rb_define_method(cOCSPBasicRes, "initialize_copy", ossl_ocspbres_initialize_copy, 1);
    rb_define_method(cOCSPBasicRes, "initialize", ossl_ocspbres_initialize, -1);
    rb_define_method(cOCSPBasicRes, "copy_nonce", ossl_ocspbres_copy_nonce, 1);
    rb_define_method(cOCSPBasicRes, "add_nonce", ossl_ocspbres_add_nonce, -1);
    rb_define_method(cOCSPBasicRes, "add_status", ossl_ocspbres_add_status, 7);
    rb_define_method(cOCSPBasicRes, "status", ossl_ocspbres_get_status, 0);
    rb_define_method(cOCSPBasicRes, "responses", ossl_ocspbres_get_responses, 0);
    rb_define_method(cOCSPBasicRes, "find_response", ossl_ocspbres_find_response, 1);
    rb_define_method(cOCSPBasicRes, "sign", ossl_ocspbres_sign, -1);
    rb_define_method(cOCSPBasicRes, "verify", ossl_ocspbres_verify, -1);
    rb_define_method(cOCSPBasicRes, "to_der", ossl_ocspbres_to_der, 0);

    /*
     * An OpenSSL::OCSP::SingleResponse represents an OCSP SingleResponse
     * structure, which contains the basic information of the status of the
     * certificate.
     */
    cOCSPSingleRes = rb_define_class_under(mOCSP, "SingleResponse", rb_cObject);
    rb_define_alloc_func(cOCSPSingleRes, ossl_ocspsres_alloc);
    rb_define_method(cOCSPSingleRes, "initialize_copy", ossl_ocspsres_initialize_copy, 1);
    rb_define_method(cOCSPSingleRes, "initialize", ossl_ocspsres_initialize, 1);
    rb_define_method(cOCSPSingleRes, "check_validity", ossl_ocspsres_check_validity, -1);
    rb_define_method(cOCSPSingleRes, "certid", ossl_ocspsres_get_certid, 0);
    rb_define_method(cOCSPSingleRes, "cert_status", ossl_ocspsres_get_cert_status, 0);
    rb_define_method(cOCSPSingleRes, "this_update", ossl_ocspsres_get_this_update, 0);
    rb_define_method(cOCSPSingleRes, "next_update", ossl_ocspsres_get_next_update, 0);
    rb_define_method(cOCSPSingleRes, "revocation_time", ossl_ocspsres_get_revocation_time, 0);
    rb_define_method(cOCSPSingleRes, "revocation_reason", ossl_ocspsres_get_revocation_reason, 0);
    rb_define_method(cOCSPSingleRes, "extensions", ossl_ocspsres_get_extensions, 0);
    rb_define_method(cOCSPSingleRes, "to_der", ossl_ocspsres_to_der, 0);

    /*
     * An OpenSSL::OCSP::CertificateId identifies a certificate to the CA so
     * that a status check can be performed.
     */

    cOCSPCertId = rb_define_class_under(mOCSP, "CertificateId", rb_cObject);
    rb_define_alloc_func(cOCSPCertId, ossl_ocspcid_alloc);
    rb_define_method(cOCSPCertId, "initialize_copy", ossl_ocspcid_initialize_copy, 1);
    rb_define_method(cOCSPCertId, "initialize", ossl_ocspcid_initialize, -1);
    rb_define_method(cOCSPCertId, "cmp", ossl_ocspcid_cmp, 1);
    rb_define_method(cOCSPCertId, "cmp_issuer", ossl_ocspcid_cmp_issuer, 1);
    rb_define_method(cOCSPCertId, "serial", ossl_ocspcid_get_serial, 0);
    rb_define_method(cOCSPCertId, "issuer_name_hash", ossl_ocspcid_get_issuer_name_hash, 0);
    rb_define_method(cOCSPCertId, "issuer_key_hash", ossl_ocspcid_get_issuer_key_hash, 0);
    rb_define_method(cOCSPCertId, "hash_algorithm", ossl_ocspcid_get_hash_algorithm, 0);
    rb_define_method(cOCSPCertId, "to_der", ossl_ocspcid_to_der, 0);

    /* Internal error in issuer */
    rb_define_const(mOCSP, "RESPONSE_STATUS_INTERNALERROR", INT2NUM(OCSP_RESPONSE_STATUS_INTERNALERROR));

    /* Illegal confirmation request */
    rb_define_const(mOCSP, "RESPONSE_STATUS_MALFORMEDREQUEST", INT2NUM(OCSP_RESPONSE_STATUS_MALFORMEDREQUEST));

    /* The certificate was revoked for an unknown reason */
    rb_define_const(mOCSP, "REVOKED_STATUS_NOSTATUS", INT2NUM(OCSP_REVOKED_STATUS_NOSTATUS));

    /* You must sign the request and resubmit */
    rb_define_const(mOCSP, "RESPONSE_STATUS_SIGREQUIRED", INT2NUM(OCSP_RESPONSE_STATUS_SIGREQUIRED));

    /* Response has valid confirmations */
    rb_define_const(mOCSP, "RESPONSE_STATUS_SUCCESSFUL", INT2NUM(OCSP_RESPONSE_STATUS_SUCCESSFUL));

    /* Try again later */
    rb_define_const(mOCSP, "RESPONSE_STATUS_TRYLATER", INT2NUM(OCSP_RESPONSE_STATUS_TRYLATER));

    /* The certificate subject's name or other information changed */
    rb_define_const(mOCSP, "REVOKED_STATUS_AFFILIATIONCHANGED", INT2NUM(OCSP_REVOKED_STATUS_AFFILIATIONCHANGED));

    /* This CA certificate was revoked due to a key compromise */
    rb_define_const(mOCSP, "REVOKED_STATUS_CACOMPROMISE", INT2NUM(OCSP_REVOKED_STATUS_CACOMPROMISE));

    /* The certificate is on hold */
    rb_define_const(mOCSP, "REVOKED_STATUS_CERTIFICATEHOLD", INT2NUM(OCSP_REVOKED_STATUS_CERTIFICATEHOLD));

    /* The certificate is no longer needed */
    rb_define_const(mOCSP, "REVOKED_STATUS_CESSATIONOFOPERATION", INT2NUM(OCSP_REVOKED_STATUS_CESSATIONOFOPERATION));

    /* The certificate was revoked due to a key compromise */
    rb_define_const(mOCSP, "REVOKED_STATUS_KEYCOMPROMISE", INT2NUM(OCSP_REVOKED_STATUS_KEYCOMPROMISE));

    /* The certificate was previously on hold and should now be removed from
     * the CRL */
    rb_define_const(mOCSP, "REVOKED_STATUS_REMOVEFROMCRL", INT2NUM(OCSP_REVOKED_STATUS_REMOVEFROMCRL));

    /* The certificate was superseded by a new certificate */
    rb_define_const(mOCSP, "REVOKED_STATUS_SUPERSEDED", INT2NUM(OCSP_REVOKED_STATUS_SUPERSEDED));

    /* Your request is unauthorized. */
    rb_define_const(mOCSP, "RESPONSE_STATUS_UNAUTHORIZED", INT2NUM(OCSP_RESPONSE_STATUS_UNAUTHORIZED));

    /* The certificate was revoked for an unspecified reason */
    rb_define_const(mOCSP, "REVOKED_STATUS_UNSPECIFIED", INT2NUM(OCSP_REVOKED_STATUS_UNSPECIFIED));

    /* Do not include certificates in the response */
    rb_define_const(mOCSP, "NOCERTS", INT2NUM(OCSP_NOCERTS));

    /* Do not search certificates contained in the response for a signer */
    rb_define_const(mOCSP, "NOINTERN", INT2NUM(OCSP_NOINTERN));

    /* Do not check the signature on the response */
    rb_define_const(mOCSP, "NOSIGS", INT2NUM(OCSP_NOSIGS));

    /* Do not verify the certificate chain on the response */
    rb_define_const(mOCSP, "NOCHAIN", INT2NUM(OCSP_NOCHAIN));

    /* Do not verify the response at all */
    rb_define_const(mOCSP, "NOVERIFY", INT2NUM(OCSP_NOVERIFY));

    /* Do not check trust */
    rb_define_const(mOCSP, "NOEXPLICIT", INT2NUM(OCSP_NOEXPLICIT));

    /* (This flag is not used by OpenSSL 1.0.1g) */
    rb_define_const(mOCSP, "NOCASIGN", INT2NUM(OCSP_NOCASIGN));

    /* (This flag is not used by OpenSSL 1.0.1g) */
    rb_define_const(mOCSP, "NODELEGATED", INT2NUM(OCSP_NODELEGATED));

    /* Do not make additional signing certificate checks */
    rb_define_const(mOCSP, "NOCHECKS", INT2NUM(OCSP_NOCHECKS));

    /* Do not verify additional certificates */
    rb_define_const(mOCSP, "TRUSTOTHER", INT2NUM(OCSP_TRUSTOTHER));

    /* Identify the response by signing the certificate key ID */
    rb_define_const(mOCSP, "RESPID_KEY", INT2NUM(OCSP_RESPID_KEY));

    /* Do not include producedAt time in response */
    rb_define_const(mOCSP, "NOTIME", INT2NUM(OCSP_NOTIME));

    /* Indicates the certificate is not revoked but does not necessarily mean
     * the certificate was issued or that this response is within the
     * certificate's validity interval */
    rb_define_const(mOCSP, "V_CERTSTATUS_GOOD", INT2NUM(V_OCSP_CERTSTATUS_GOOD));
    /* Indicates the certificate has been revoked either permanently or
     * temporarily (on hold). */
    rb_define_const(mOCSP, "V_CERTSTATUS_REVOKED", INT2NUM(V_OCSP_CERTSTATUS_REVOKED));

    /* Indicates the responder does not know about the certificate being
     * requested. */
    rb_define_const(mOCSP, "V_CERTSTATUS_UNKNOWN", INT2NUM(V_OCSP_CERTSTATUS_UNKNOWN));

    /* The responder ID is based on the key name. */
    rb_define_const(mOCSP, "V_RESPID_NAME", INT2NUM(V_OCSP_RESPID_NAME));

    /* The responder ID is based on the public key. */
    rb_define_const(mOCSP, "V_RESPID_KEY", INT2NUM(V_OCSP_RESPID_KEY));
}
#else
void
Init_ossl_ocsp(void)
{
}
#endif
