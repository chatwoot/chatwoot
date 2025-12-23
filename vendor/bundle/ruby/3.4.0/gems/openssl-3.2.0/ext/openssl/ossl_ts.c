/*
 *
 * Copyright (C) 2010 Martin Bosslet <Martin.Bosslet@googlemail.com>
 * All rights reserved.
 */
/*
 * This program is licenced under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#include "ossl.h"

#ifndef OPENSSL_NO_TS

#define NewTSRequest(klass) \
    TypedData_Wrap_Struct((klass), &ossl_ts_req_type, 0)
#define SetTSRequest(obj, req) do { \
    if (!(req)) { \
        ossl_raise(rb_eRuntimeError, "TS_REQ wasn't initialized."); \
    } \
    RTYPEDDATA_DATA(obj) = (req); \
} while (0)
#define GetTSRequest(obj, req) do { \
    TypedData_Get_Struct((obj), TS_REQ, &ossl_ts_req_type, (req)); \
    if (!(req)) { \
        ossl_raise(rb_eRuntimeError, "TS_REQ wasn't initialized."); \
    } \
} while (0)

#define NewTSResponse(klass) \
    TypedData_Wrap_Struct((klass), &ossl_ts_resp_type, 0)
#define SetTSResponse(obj, resp) do { \
    if (!(resp)) { \
        ossl_raise(rb_eRuntimeError, "TS_RESP wasn't initialized."); \
    } \
    RTYPEDDATA_DATA(obj) = (resp); \
} while (0)
#define GetTSResponse(obj, resp) do { \
    TypedData_Get_Struct((obj), TS_RESP, &ossl_ts_resp_type, (resp)); \
    if (!(resp)) { \
        ossl_raise(rb_eRuntimeError, "TS_RESP wasn't initialized."); \
    } \
} while (0)

#define NewTSTokenInfo(klass) \
    TypedData_Wrap_Struct((klass), &ossl_ts_token_info_type, 0)
#define SetTSTokenInfo(obj, info) do { \
    if (!(info)) { \
        ossl_raise(rb_eRuntimeError, "TS_TST_INFO wasn't initialized."); \
    } \
    RTYPEDDATA_DATA(obj) = (info); \
} while (0)
#define GetTSTokenInfo(obj, info) do { \
    TypedData_Get_Struct((obj), TS_TST_INFO, &ossl_ts_token_info_type, (info)); \
    if (!(info)) { \
        ossl_raise(rb_eRuntimeError, "TS_TST_INFO wasn't initialized."); \
    } \
} while (0)

#define ossl_tsfac_get_default_policy_id(o)      rb_attr_get((o),rb_intern("@default_policy_id"))
#define ossl_tsfac_get_serial_number(o)          rb_attr_get((o),rb_intern("@serial_number"))
#define ossl_tsfac_get_gen_time(o)               rb_attr_get((o),rb_intern("@gen_time"))
#define ossl_tsfac_get_additional_certs(o)       rb_attr_get((o),rb_intern("@additional_certs"))
#define ossl_tsfac_get_allowed_digests(o)        rb_attr_get((o),rb_intern("@allowed_digests"))

static VALUE mTimestamp;
static VALUE eTimestampError;
static VALUE cTimestampRequest;
static VALUE cTimestampResponse;
static VALUE cTimestampTokenInfo;
static VALUE cTimestampFactory;
static VALUE sBAD_ALG, sBAD_REQUEST, sBAD_DATA_FORMAT, sTIME_NOT_AVAILABLE;
static VALUE sUNACCEPTED_POLICY, sUNACCEPTED_EXTENSION, sADD_INFO_NOT_AVAILABLE;
static VALUE sSYSTEM_FAILURE;

static void
ossl_ts_req_free(void *ptr)
{
    TS_REQ_free(ptr);
}

static const rb_data_type_t ossl_ts_req_type = {
    "OpenSSL/Timestamp/Request",
    {
        0, ossl_ts_req_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static void
ossl_ts_resp_free(void *ptr)
{
    TS_RESP_free(ptr);
}

static  const rb_data_type_t ossl_ts_resp_type = {
    "OpenSSL/Timestamp/Response",
    {
        0, ossl_ts_resp_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static void
ossl_ts_token_info_free(void *ptr)
{
        TS_TST_INFO_free(ptr);
}

static const rb_data_type_t ossl_ts_token_info_type = {
    "OpenSSL/Timestamp/TokenInfo",
    {
        0, ossl_ts_token_info_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static VALUE
asn1_to_der(void *template, int (*i2d)(void *template, unsigned char **pp))
{
    VALUE str;
    int len;
    unsigned char *p;

    if((len = i2d(template, NULL)) <= 0)
        ossl_raise(eTimestampError, "Error when encoding to DER");
    str = rb_str_new(0, len);
    p = (unsigned char *)RSTRING_PTR(str);
    if(i2d(template, &p) <= 0)
        ossl_raise(eTimestampError, "Error when encoding to DER");
    rb_str_set_len(str, p - (unsigned char*)RSTRING_PTR(str));

    return str;
}

static ASN1_OBJECT*
obj_to_asn1obj(VALUE obj)
{
    ASN1_OBJECT *a1obj;

    StringValue(obj);
    a1obj = OBJ_txt2obj(RSTRING_PTR(obj), 0);
    if(!a1obj) a1obj = OBJ_txt2obj(RSTRING_PTR(obj), 1);
    if(!a1obj) ossl_raise(eASN1Error, "invalid OBJECT ID");

    return a1obj;
}

static VALUE
obj_to_asn1obj_i(VALUE obj)
{
    return (VALUE)obj_to_asn1obj(obj);
}

static VALUE
get_asn1obj(ASN1_OBJECT *obj)
{
    BIO *out;
    VALUE ret;
    int nid;
    if ((nid = OBJ_obj2nid(obj)) != NID_undef)
        ret = rb_str_new2(OBJ_nid2sn(nid));
    else{
        if (!(out = BIO_new(BIO_s_mem())))
            ossl_raise(eX509AttrError, NULL);
        i2a_ASN1_OBJECT(out, obj);
        ret = ossl_membio2str(out);
    }

    return ret;
}

static VALUE
ossl_ts_req_alloc(VALUE klass)
{
    TS_REQ *req;
    VALUE obj;

    obj = NewTSRequest(klass);
    if (!(req = TS_REQ_new()))
        ossl_raise(eTimestampError, NULL);
    SetTSRequest(obj, req);

    /* Defaults */
    TS_REQ_set_version(req, 1);
    TS_REQ_set_cert_req(req, 1);

    return obj;
}

/*
 * When creating a Request with the +File+ or +string+ parameter, the
 * corresponding +File+ or +string+ must be DER-encoded.
 *
 * call-seq:
 *       OpenSSL::Timestamp::Request.new(file)    -> request
 *       OpenSSL::Timestamp::Request.new(string)  -> request
 *       OpenSSL::Timestamp::Request.new          -> empty request
 */
static VALUE
ossl_ts_req_initialize(int argc, VALUE *argv, VALUE self)
{
    TS_REQ *ts_req = DATA_PTR(self);
    BIO *in;
    VALUE arg;

    if(rb_scan_args(argc, argv, "01", &arg) == 0) {
        return self;
    }

    arg = ossl_to_der_if_possible(arg);
    in = ossl_obj2bio(&arg);
    ts_req = d2i_TS_REQ_bio(in, &ts_req);
    BIO_free(in);
    if (!ts_req) {
        DATA_PTR(self) = NULL;
        ossl_raise(eTimestampError, "Error when decoding the timestamp request");
    }
    DATA_PTR(self) = ts_req;

    return self;
}

/*
 * Returns the 'short name' of the object identifier that represents the
 * algorithm that was used to create the message imprint digest.
 *
 *  call-seq:
 *       request.algorithm    -> string
 */
static VALUE
ossl_ts_req_get_algorithm(VALUE self)
{
    TS_REQ *req;
    TS_MSG_IMPRINT *mi;
    X509_ALGOR *algor;

    GetTSRequest(self, req);
    mi = TS_REQ_get_msg_imprint(req);
    algor = TS_MSG_IMPRINT_get_algo(mi);
    return get_asn1obj(algor->algorithm);
}

/*
 * Allows to set the object identifier  or the 'short name' of the
 * algorithm that was used to create the message imprint digest.
 *
 * ===Example:
 *      request.algorithm = "SHA1"
 *
 *  call-seq:
 *       request.algorithm = "string"    -> string
 */
static VALUE
ossl_ts_req_set_algorithm(VALUE self, VALUE algo)
{
    TS_REQ *req;
    TS_MSG_IMPRINT *mi;
    ASN1_OBJECT *obj;
    X509_ALGOR *algor;

    GetTSRequest(self, req);
    obj = obj_to_asn1obj(algo);
    mi = TS_REQ_get_msg_imprint(req);
    algor = TS_MSG_IMPRINT_get_algo(mi);
    if (!X509_ALGOR_set0(algor, obj, V_ASN1_NULL, NULL)) {
        ASN1_OBJECT_free(obj);
        ossl_raise(eTimestampError, "X509_ALGOR_set0");
    }

    return algo;
}

/*
 * Returns the message imprint (digest) of the data to be timestamped.
 *
 * call-seq:
 *       request.message_imprint    -> string or nil
 */
static VALUE
ossl_ts_req_get_msg_imprint(VALUE self)
{
    TS_REQ *req;
    TS_MSG_IMPRINT *mi;
    ASN1_OCTET_STRING *hashed_msg;
    VALUE ret;

    GetTSRequest(self, req);
    mi = TS_REQ_get_msg_imprint(req);
    hashed_msg = TS_MSG_IMPRINT_get_msg(mi);

    ret = rb_str_new((const char *)hashed_msg->data, hashed_msg->length);

    return ret;
}

/*
 * Set the message imprint digest.
 *
 *  call-seq:
 *       request.message_imprint = "string"    -> string
 */
static VALUE
ossl_ts_req_set_msg_imprint(VALUE self, VALUE hash)
{
    TS_REQ *req;
    TS_MSG_IMPRINT *mi;
    StringValue(hash);

    GetTSRequest(self, req);
    mi = TS_REQ_get_msg_imprint(req);
    if (!TS_MSG_IMPRINT_set_msg(mi, (unsigned char *)RSTRING_PTR(hash), RSTRING_LENINT(hash)))
        ossl_raise(eTimestampError, "TS_MSG_IMPRINT_set_msg");

    return hash;
}

/*
 * Returns the version of this request. +1+ is the default value.
 *
 * call-seq:
 *       request.version -> Integer
 */
static VALUE
ossl_ts_req_get_version(VALUE self)
{
    TS_REQ *req;

    GetTSRequest(self, req);
    return LONG2NUM(TS_REQ_get_version(req));
}

/*
 * Sets the version number for this Request. This should be +1+ for compliant
 * servers.
 *
 * call-seq:
 *       request.version = number    -> Integer
 */
static VALUE
ossl_ts_req_set_version(VALUE self, VALUE version)
{
    TS_REQ *req;
    long ver;

    if ((ver = NUM2LONG(version)) < 0)
        ossl_raise(eTimestampError, "version must be >= 0!");
    GetTSRequest(self, req);
    if (!TS_REQ_set_version(req, ver))
        ossl_raise(eTimestampError, "TS_REQ_set_version");

    return version;
}

/*
 * Returns the 'short name' of the object identifier that represents the
 * timestamp policy under which the server shall create the timestamp.
 *
 * call-seq:
 *       request.policy_id    -> string or nil
 */
static VALUE
ossl_ts_req_get_policy_id(VALUE self)
{
    TS_REQ *req;

    GetTSRequest(self, req);
    if (!TS_REQ_get_policy_id(req))
        return Qnil;
    return get_asn1obj(TS_REQ_get_policy_id(req));
}

/*
 * Allows to set the object identifier that represents the
 * timestamp policy under which the server shall create the timestamp. This
 * may be left +nil+, implying that the timestamp server will issue the
 * timestamp using some default policy.
 *
 * ===Example:
 *      request.policy_id = "1.2.3.4.5"
 *
 * call-seq:
 *       request.policy_id = "string"   -> string
 */
static VALUE
ossl_ts_req_set_policy_id(VALUE self, VALUE oid)
{
    TS_REQ *req;
    ASN1_OBJECT *obj;
    int ok;

    GetTSRequest(self, req);
    obj = obj_to_asn1obj(oid);
    ok = TS_REQ_set_policy_id(req, obj);
    ASN1_OBJECT_free(obj);
    if (!ok)
        ossl_raise(eTimestampError, "TS_REQ_set_policy_id");

    return oid;
}

/*
 * Returns the nonce (number used once) that the server shall include in its
 * response.
 *
 * call-seq:
 *       request.nonce    -> BN or nil
 */
static VALUE
ossl_ts_req_get_nonce(VALUE self)
{
    TS_REQ *req;
    const ASN1_INTEGER * nonce;

    GetTSRequest(self, req);
    if (!(nonce = TS_REQ_get_nonce(req)))
        return Qnil;
    return asn1integer_to_num(nonce);
}

/*
 * Sets the nonce (number used once) that the server shall include in its
 * response. If the nonce is set, the server must return the same nonce value in
 * a valid Response.
 *
 * call-seq:
 *       request.nonce = number    -> BN
 */
static VALUE
ossl_ts_req_set_nonce(VALUE self, VALUE num)
{
    TS_REQ *req;
    ASN1_INTEGER *nonce;
    int ok;

    GetTSRequest(self, req);
    nonce = num_to_asn1integer(num, NULL);
    ok = TS_REQ_set_nonce(req, nonce);
    ASN1_INTEGER_free(nonce);
    if (!ok)
        ossl_raise(eTimestampError, NULL);
    return num;
}

/*
 * Indicates whether the response shall contain the timestamp authority's
 * certificate or not.
 *
 * call-seq:
 *       request.cert_requested?  -> true or false
 */
static VALUE
ossl_ts_req_get_cert_requested(VALUE self)
{
    TS_REQ *req;

    GetTSRequest(self, req);
    return TS_REQ_get_cert_req(req) ? Qtrue: Qfalse;
}

/*
 * Specify whether the response shall contain the timestamp authority's
 * certificate or not. The default value is +true+.
 *
 * call-seq:
 *       request.cert_requested = boolean -> true or false
 */
static VALUE
ossl_ts_req_set_cert_requested(VALUE self, VALUE requested)
{
    TS_REQ *req;

    GetTSRequest(self, req);
    TS_REQ_set_cert_req(req, RTEST(requested));

    return requested;
}

/*
 * DER-encodes this Request.
 *
 * call-seq:
 *       request.to_der    -> DER-encoded string
 */
static VALUE
ossl_ts_req_to_der(VALUE self)
{
    TS_REQ *req;
    TS_MSG_IMPRINT *mi;
    X509_ALGOR *algo;
    ASN1_OCTET_STRING *hashed_msg;

    GetTSRequest(self, req);
    mi = TS_REQ_get_msg_imprint(req);

    algo = TS_MSG_IMPRINT_get_algo(mi);
    if (OBJ_obj2nid(algo->algorithm) == NID_undef)
        ossl_raise(eTimestampError, "Message imprint missing algorithm");

    hashed_msg = TS_MSG_IMPRINT_get_msg(mi);
    if (!hashed_msg->length)
        ossl_raise(eTimestampError, "Message imprint missing hashed message");

    return asn1_to_der((void *)req, (int (*)(void *, unsigned char **))i2d_TS_REQ);
}

static VALUE
ossl_ts_resp_alloc(VALUE klass)
{
    TS_RESP *resp;
    VALUE obj;

    obj = NewTSResponse(klass);
    if (!(resp = TS_RESP_new()))
        ossl_raise(eTimestampError, NULL);
    SetTSResponse(obj, resp);

    return obj;
}

/*
 * Creates a Response from a +File+ or +string+ parameter, the
 * corresponding +File+ or +string+ must be DER-encoded. Please note
 * that Response is an immutable read-only class. If you'd like to create
 * timestamps please refer to Factory instead.
 *
 * call-seq:
 *       OpenSSL::Timestamp::Response.new(file)    -> response
 *       OpenSSL::Timestamp::Response.new(string)  -> response
 */
static VALUE
ossl_ts_resp_initialize(VALUE self, VALUE der)
{
    TS_RESP *ts_resp = DATA_PTR(self);
    BIO *in;

    der = ossl_to_der_if_possible(der);
    in  = ossl_obj2bio(&der);
    ts_resp = d2i_TS_RESP_bio(in, &ts_resp);
    BIO_free(in);
    if (!ts_resp) {
        DATA_PTR(self) = NULL;
        ossl_raise(eTimestampError, "Error when decoding the timestamp response");
    }
    DATA_PTR(self) = ts_resp;

    return self;
}

/*
 * Returns one of GRANTED, GRANTED_WITH_MODS, REJECTION, WAITING,
 * REVOCATION_WARNING or REVOCATION_NOTIFICATION. A timestamp token has
 * been created only in case +status+ is equal to GRANTED or GRANTED_WITH_MODS.
 *
 * call-seq:
 *       response.status -> BN (never nil)
 */
static VALUE
ossl_ts_resp_get_status(VALUE self)
{
    TS_RESP *resp;
    TS_STATUS_INFO *si;
    const ASN1_INTEGER *st;

    GetTSResponse(self, resp);
    si = TS_RESP_get_status_info(resp);
    st = TS_STATUS_INFO_get0_status(si);

    return asn1integer_to_num(st);
}

/*
 * In cases no timestamp token has been created, this field contains further
 * info about the reason why response creation failed. The method returns either
 * nil (the request was successful and a timestamp token was created) or one of
 * the following:
 * * :BAD_ALG - Indicates that the timestamp server rejects the message
 *   imprint algorithm used in the Request
 * * :BAD_REQUEST - Indicates that the timestamp server was not able to process
 *   the Request properly
 * * :BAD_DATA_FORMAT - Indicates that the timestamp server was not able to
 *   parse certain data in the Request
 * * :TIME_NOT_AVAILABLE - Indicates that the server could not access its time
 *   source
 * * :UNACCEPTED_POLICY - Indicates that the requested policy identifier is not
 *   recognized or supported by the timestamp server
 * * :UNACCEPTED_EXTENSIION - Indicates that an extension in the Request is
 *   not supported by the timestamp server
 * * :ADD_INFO_NOT_AVAILABLE -Indicates that additional information requested
 *   is either not understood or currently not available
 * * :SYSTEM_FAILURE - Timestamp creation failed due to an internal error that
 *   occurred on the timestamp server
 *
 * call-seq:
 *       response.failure_info -> nil or symbol
 */
static VALUE
ossl_ts_resp_get_failure_info(VALUE self)
{
    TS_RESP *resp;
    TS_STATUS_INFO *si;

    /* The ASN1_BIT_STRING_get_bit changed from 1.0.0. to 1.1.0, making this
     * const. */
    #if defined(HAVE_TS_STATUS_INFO_GET0_FAILURE_INFO)
    const ASN1_BIT_STRING *fi;
    #else
    ASN1_BIT_STRING *fi;
    #endif

    GetTSResponse(self, resp);
    si = TS_RESP_get_status_info(resp);
    fi = TS_STATUS_INFO_get0_failure_info(si);
    if (!fi)
        return Qnil;
    if (ASN1_BIT_STRING_get_bit(fi, TS_INFO_BAD_ALG))
        return sBAD_ALG;
    if (ASN1_BIT_STRING_get_bit(fi, TS_INFO_BAD_REQUEST))
        return sBAD_REQUEST;
    if (ASN1_BIT_STRING_get_bit(fi, TS_INFO_BAD_DATA_FORMAT))
        return sBAD_DATA_FORMAT;
    if (ASN1_BIT_STRING_get_bit(fi, TS_INFO_TIME_NOT_AVAILABLE))
        return sTIME_NOT_AVAILABLE;
    if (ASN1_BIT_STRING_get_bit(fi, TS_INFO_UNACCEPTED_POLICY))
        return sUNACCEPTED_POLICY;
    if (ASN1_BIT_STRING_get_bit(fi, TS_INFO_UNACCEPTED_EXTENSION))
        return sUNACCEPTED_EXTENSION;
    if (ASN1_BIT_STRING_get_bit(fi, TS_INFO_ADD_INFO_NOT_AVAILABLE))
        return sADD_INFO_NOT_AVAILABLE;
    if (ASN1_BIT_STRING_get_bit(fi, TS_INFO_SYSTEM_FAILURE))
        return sSYSTEM_FAILURE;

    ossl_raise(eTimestampError, "Unrecognized failure info.");
}

/*
 * In cases of failure this field may contain an array of strings further
 * describing the origin of the failure.
 *
 * call-seq:
 *       response.status_text -> Array of strings or nil
 */
static VALUE
ossl_ts_resp_get_status_text(VALUE self)
{
    TS_RESP *resp;
    TS_STATUS_INFO *si;
    const STACK_OF(ASN1_UTF8STRING) *text;
    ASN1_UTF8STRING *current;
    int i;
    VALUE ret = rb_ary_new();

    GetTSResponse(self, resp);
    si = TS_RESP_get_status_info(resp);
    if ((text = TS_STATUS_INFO_get0_text(si))) {
        for (i = 0; i < sk_ASN1_UTF8STRING_num(text); i++) {
            current = sk_ASN1_UTF8STRING_value(text, i);
            rb_ary_push(ret, asn1str_to_str(current));
        }
    }

    return ret;
}

/*
 * If a timestamp token is present, this returns it in the form of a
 * OpenSSL::PKCS7.
 *
 * call-seq:
 *       response.token -> nil or OpenSSL::PKCS7
 */
static VALUE
ossl_ts_resp_get_token(VALUE self)
{
    TS_RESP *resp;
    PKCS7 *p7, *copy;
    VALUE obj;

    GetTSResponse(self, resp);
    if (!(p7 = TS_RESP_get_token(resp)))
        return Qnil;

    obj = NewPKCS7(cPKCS7);

    if (!(copy = PKCS7_dup(p7)))
        ossl_raise(eTimestampError, NULL);

    SetPKCS7(obj, copy);

    return obj;
}

/*
 * Get the response's token info if present.
 *
 * call-seq:
 *       response.token_info -> nil or OpenSSL::Timestamp::TokenInfo
 */
static VALUE
ossl_ts_resp_get_token_info(VALUE self)
{
    TS_RESP *resp;
    TS_TST_INFO *info, *copy;
    VALUE obj;

    GetTSResponse(self, resp);
    if (!(info = TS_RESP_get_tst_info(resp)))
        return Qnil;

    obj = NewTSTokenInfo(cTimestampTokenInfo);

    if (!(copy = TS_TST_INFO_dup(info)))
        ossl_raise(eTimestampError, NULL);

    SetTSTokenInfo(obj, copy);

    return obj;
}

/*
 * If the Request specified to request the TSA certificate
 * (Request#cert_requested = true), then this field contains the
 * certificate of the timestamp authority.
 *
 * call-seq:
 *       response.tsa_certificate -> OpenSSL::X509::Certificate or nil
 */
static VALUE
ossl_ts_resp_get_tsa_certificate(VALUE self)
{
    TS_RESP *resp;
    PKCS7 *p7;
    PKCS7_SIGNER_INFO *ts_info;
    X509 *cert;

    GetTSResponse(self, resp);
    if (!(p7 = TS_RESP_get_token(resp)))
        return Qnil;
    ts_info = sk_PKCS7_SIGNER_INFO_value(p7->d.sign->signer_info, 0);
    cert = PKCS7_cert_from_signer_info(p7, ts_info);
    if (!cert)
        return Qnil;
    return ossl_x509_new(cert);
}

/*
 * Returns the Response in DER-encoded form.
 *
 * call-seq:
 *       response.to_der -> string
 */
static VALUE
ossl_ts_resp_to_der(VALUE self)
{
    TS_RESP *resp;

    GetTSResponse(self, resp);
    return asn1_to_der((void *)resp, (int (*)(void *, unsigned char **))i2d_TS_RESP);
}

/*
 * Verifies a timestamp token by checking the signature, validating the
 * certificate chain implied by tsa_certificate and by checking conformance to
 * a given Request. Mandatory parameters are the Request associated to this
 * Response, and an OpenSSL::X509::Store of trusted roots.
 *
 * Intermediate certificates can optionally be supplied for creating the
 * certificate chain. These intermediate certificates must all be
 * instances of OpenSSL::X509::Certificate.
 *
 * If validation fails, several kinds of exceptions can be raised:
 * * TypeError if types don't fit
 * * TimestampError if something is wrong with the timestamp token itself, if
 *   it is not conformant to the Request, or if validation of the timestamp
 *   certificate chain fails.
 *
 * call-seq:
 *       response.verify(Request, root_store) -> Response
 *       response.verify(Request, root_store, [intermediate_cert]) -> Response
 */
static VALUE
ossl_ts_resp_verify(int argc, VALUE *argv, VALUE self)
{
    VALUE ts_req, store, intermediates;
    TS_RESP *resp;
    TS_REQ *req;
    X509_STORE *x509st;
    TS_VERIFY_CTX *ctx;
    STACK_OF(X509) *x509inter = NULL;
    PKCS7* p7;
    X509 *cert;
    int status, i, ok;

    rb_scan_args(argc, argv, "21", &ts_req, &store, &intermediates);

    GetTSResponse(self, resp);
    GetTSRequest(ts_req, req);
    x509st = GetX509StorePtr(store);

    if (!(ctx = TS_REQ_to_TS_VERIFY_CTX(req, NULL))) {
        ossl_raise(eTimestampError, "Error when creating the verification context.");
    }

    if (!NIL_P(intermediates)) {
        x509inter = ossl_protect_x509_ary2sk(intermediates, &status);
        if (status) {
            TS_VERIFY_CTX_free(ctx);
            rb_jump_tag(status);
        }
    } else if (!(x509inter = sk_X509_new_null())) {
        TS_VERIFY_CTX_free(ctx);
        ossl_raise(eTimestampError, "sk_X509_new_null");
    }

    if (!(p7 = TS_RESP_get_token(resp))) {
        TS_VERIFY_CTX_free(ctx);
        sk_X509_pop_free(x509inter, X509_free);
        ossl_raise(eTimestampError, "TS_RESP_get_token");
    }
    for (i=0; i < sk_X509_num(p7->d.sign->cert); i++) {
        cert = sk_X509_value(p7->d.sign->cert, i);
        if (!sk_X509_push(x509inter, cert)) {
            sk_X509_pop_free(x509inter, X509_free);
            TS_VERIFY_CTX_free(ctx);
            ossl_raise(eTimestampError, "sk_X509_push");
        }
        X509_up_ref(cert);
    }

    TS_VERIFY_CTX_set_certs(ctx, x509inter);
    TS_VERIFY_CTX_add_flags(ctx, TS_VFY_SIGNATURE);
    TS_VERIFY_CTX_set_store(ctx, x509st);

    ok = TS_RESP_verify_response(ctx, resp);
    /*
     * TS_VERIFY_CTX_set_store() call above does not increment the reference
     * counter, so it must be unset before TS_VERIFY_CTX_free() is called.
     */
    TS_VERIFY_CTX_set_store(ctx, NULL);
    TS_VERIFY_CTX_free(ctx);

    if (!ok)
        ossl_raise(eTimestampError, "TS_RESP_verify_response");

    return self;
}

static VALUE
ossl_ts_token_info_alloc(VALUE klass)
{
    TS_TST_INFO *info;
    VALUE obj;

    obj = NewTSTokenInfo(klass);
    if (!(info = TS_TST_INFO_new()))
        ossl_raise(eTimestampError, NULL);
    SetTSTokenInfo(obj, info);

    return obj;
}

/*
 * Creates a TokenInfo from a +File+ or +string+ parameter, the
 * corresponding +File+ or +string+ must be DER-encoded. Please note
 * that TokenInfo is an immutable read-only class. If you'd like to create
 * timestamps please refer to Factory instead.
 *
 * call-seq:
 *       OpenSSL::Timestamp::TokenInfo.new(file)    -> token-info
 *       OpenSSL::Timestamp::TokenInfo.new(string)  -> token-info
 */
static VALUE
ossl_ts_token_info_initialize(VALUE self, VALUE der)
{
    TS_TST_INFO *info = DATA_PTR(self);
    BIO *in;

    der = ossl_to_der_if_possible(der);
    in  = ossl_obj2bio(&der);
    info = d2i_TS_TST_INFO_bio(in, &info);
    BIO_free(in);
    if (!info) {
        DATA_PTR(self) = NULL;
        ossl_raise(eTimestampError, "Error when decoding the timestamp token info");
    }
    DATA_PTR(self) = info;

    return self;
}

/*
 * Returns the version number of the token info. With compliant servers,
 * this value should be +1+ if present. If status is GRANTED or
 * GRANTED_WITH_MODS.
 *
 * call-seq:
 *       token_info.version -> Integer or nil
 */
static VALUE
ossl_ts_token_info_get_version(VALUE self)
{
    TS_TST_INFO *info;

    GetTSTokenInfo(self, info);
    return LONG2NUM(TS_TST_INFO_get_version(info));
}

/*
 * Returns the timestamp policy object identifier of the policy this timestamp
 * was created under. If status is GRANTED or GRANTED_WITH_MODS, this is never
 * +nil+.
 *
 * ===Example:
 *      id = token_info.policy_id
 *      puts id                 -> "1.2.3.4.5"
 *
 * call-seq:
 *       token_info.policy_id -> string or nil
 */
static VALUE
ossl_ts_token_info_get_policy_id(VALUE self)
{
    TS_TST_INFO *info;

    GetTSTokenInfo(self, info);
    return get_asn1obj(TS_TST_INFO_get_policy_id(info));
}

/*
 * Returns the 'short name' of the object identifier representing the algorithm
 * that was used to derive the message imprint digest. For valid timestamps,
 * this is the same value that was already given in the Request. If status is
 * GRANTED or GRANTED_WITH_MODS, this is never +nil+.
 *
 * ===Example:
 *      algo = token_info.algorithm
 *      puts algo                -> "SHA1"
 *
 * call-seq:
 *       token_info.algorithm -> string or nil
 */
static VALUE
ossl_ts_token_info_get_algorithm(VALUE self)
{
    TS_TST_INFO *info;
    TS_MSG_IMPRINT *mi;
    X509_ALGOR *algo;

    GetTSTokenInfo(self, info);
    mi = TS_TST_INFO_get_msg_imprint(info);
    algo = TS_MSG_IMPRINT_get_algo(mi);
    return get_asn1obj(algo->algorithm);
}

/*
 * Returns the message imprint digest. For valid timestamps,
 * this is the same value that was already given in the Request.
 * If status is GRANTED or GRANTED_WITH_MODS, this is never +nil+.
 *
 * ===Example:
 *      mi = token_info.msg_imprint
 *      puts mi                -> "DEADBEEF"
 *
 * call-seq:
 *       token_info.msg_imprint -> string.
 */
static VALUE
ossl_ts_token_info_get_msg_imprint(VALUE self)
{
    TS_TST_INFO *info;
    TS_MSG_IMPRINT *mi;
    ASN1_OCTET_STRING *hashed_msg;
    VALUE ret;

    GetTSTokenInfo(self, info);
    mi = TS_TST_INFO_get_msg_imprint(info);
    hashed_msg = TS_MSG_IMPRINT_get_msg(mi);
    ret = rb_str_new((const char *)hashed_msg->data, hashed_msg->length);

    return ret;
}

/*
 * Returns serial number of the timestamp token. This value shall never be the
 * same for two timestamp tokens issued by a dedicated timestamp authority.
 * If status is GRANTED or GRANTED_WITH_MODS, this is never +nil+.
 *
 * call-seq:
 *       token_info.serial_number -> BN or nil
 */
static VALUE
ossl_ts_token_info_get_serial_number(VALUE self)
{
    TS_TST_INFO *info;

    GetTSTokenInfo(self, info);
    return asn1integer_to_num(TS_TST_INFO_get_serial(info));
}

/*
 * Returns time when this timestamp token was created. If status is GRANTED or
 * GRANTED_WITH_MODS, this is never +nil+.
 *
 * call-seq:
 *       token_info.gen_time -> Time
 */
static VALUE
ossl_ts_token_info_get_gen_time(VALUE self)
{
    TS_TST_INFO *info;

    GetTSTokenInfo(self, info);
    return asn1time_to_time(TS_TST_INFO_get_time(info));
}

/*
 * If the ordering field is missing, or if the ordering field is present
 * and set to false, then the genTime field only indicates the time at
 * which the time-stamp token has been created by the TSA.  In such a
 * case, the ordering of time-stamp tokens issued by the same TSA or
 * different TSAs is only possible when the difference between the
 * genTime of the first time-stamp token and the genTime of the second
 * time-stamp token is greater than the sum of the accuracies of the
 * genTime for each time-stamp token.
 *
 * If the ordering field is present and set to true, every time-stamp
 * token from the same TSA can always be ordered based on the genTime
 * field, regardless of the genTime accuracy.
 *
 * call-seq:
 *       token_info.ordering -> true, falses or nil
 */
static VALUE
ossl_ts_token_info_get_ordering(VALUE self)
{
    TS_TST_INFO *info;

    GetTSTokenInfo(self, info);
    return TS_TST_INFO_get_ordering(info) ? Qtrue : Qfalse;
}

/*
 * If the timestamp token is valid then this field contains the same nonce that
 * was passed to the timestamp server in the initial Request.
 *
 * call-seq:
 *       token_info.nonce -> BN or nil
 */
static VALUE
ossl_ts_token_info_get_nonce(VALUE self)
{
    TS_TST_INFO *info;
    const ASN1_INTEGER *nonce;

    GetTSTokenInfo(self, info);
    if (!(nonce = TS_TST_INFO_get_nonce(info)))
        return Qnil;

    return asn1integer_to_num(nonce);
}

/*
 * Returns the TokenInfo in DER-encoded form.
 *
 * call-seq:
 *       token_info.to_der -> string
 */
static VALUE
ossl_ts_token_info_to_der(VALUE self)
{
    TS_TST_INFO *info;

    GetTSTokenInfo(self, info);
    return asn1_to_der((void *)info, (int (*)(void *, unsigned char **))i2d_TS_TST_INFO);
}

static ASN1_INTEGER *
ossl_tsfac_serial_cb(struct TS_resp_ctx *ctx, void *data)
{
    ASN1_INTEGER **snptr = (ASN1_INTEGER **)data;
    ASN1_INTEGER *sn = *snptr;
    *snptr = NULL;
    return sn;
}

static int
#if !defined(LIBRESSL_VERSION_NUMBER)
ossl_tsfac_time_cb(struct TS_resp_ctx *ctx, void *data, long *sec, long *usec)
#else
ossl_tsfac_time_cb(struct TS_resp_ctx *ctx, void *data, time_t *sec, long *usec)
#endif
{
    *sec = *((long *)data);
    *usec = 0;
    return 1;
}

static VALUE
ossl_evp_get_digestbyname_i(VALUE arg)
{
    return (VALUE)ossl_evp_get_digestbyname(arg);
}

static VALUE
ossl_obj2bio_i(VALUE arg)
{
    return (VALUE)ossl_obj2bio((VALUE *)arg);
}

/*
 * Creates a Response with the help of an OpenSSL::PKey, an
 * OpenSSL::X509::Certificate and a Request.
 *
 * Mandatory parameters for timestamp creation that need to be set in the
 * Request:
 *
 * * Request#algorithm
 * * Request#message_imprint
 *
 * Mandatory parameters that need to be set in the Factory:
 * * Factory#serial_number
 * * Factory#gen_time
 * * Factory#allowed_digests
 *
 * In addition one of either Request#policy_id or Factory#default_policy_id
 * must be set.
 *
 * Raises a TimestampError if creation fails, though successfully created error
 * responses may be returned.
 *
 * call-seq:
 *       factory.create_timestamp(key, certificate, request) -> Response
 */
static VALUE
ossl_tsfac_create_ts(VALUE self, VALUE key, VALUE certificate, VALUE request)
{
    VALUE serial_number, def_policy_id, gen_time, additional_certs, allowed_digests;
    VALUE str;
    STACK_OF(X509) *inter_certs;
    VALUE tsresp, ret = Qnil;
    EVP_PKEY *sign_key;
    X509 *tsa_cert;
    TS_REQ *req;
    TS_RESP *response = NULL;
    TS_RESP_CTX *ctx = NULL;
    BIO *req_bio;
    ASN1_INTEGER *asn1_serial = NULL;
    ASN1_OBJECT *def_policy_id_obj = NULL;
    long lgen_time;
    const char * err_msg = NULL;
    int status = 0;

    tsresp = NewTSResponse(cTimestampResponse);
    tsa_cert = GetX509CertPtr(certificate);
    sign_key = GetPrivPKeyPtr(key);
    GetTSRequest(request, req);

    gen_time = ossl_tsfac_get_gen_time(self);
    if (!rb_obj_is_instance_of(gen_time, rb_cTime)) {
        err_msg = "@gen_time must be a Time.";
        goto end;
    }
    lgen_time = NUM2LONG(rb_funcall(gen_time, rb_intern("to_i"), 0));

    serial_number = ossl_tsfac_get_serial_number(self);
    if (NIL_P(serial_number)) {
        err_msg = "@serial_number must be set.";
        goto end;
    }
    asn1_serial = num_to_asn1integer(serial_number, NULL);

    def_policy_id = ossl_tsfac_get_default_policy_id(self);
    if (NIL_P(def_policy_id) && !TS_REQ_get_policy_id(req)) {
        err_msg = "No policy id in the request and no default policy set";
        goto end;
    }
    if (!NIL_P(def_policy_id) && !TS_REQ_get_policy_id(req)) {
        def_policy_id_obj = (ASN1_OBJECT*)rb_protect(obj_to_asn1obj_i, (VALUE)def_policy_id, &status);
        if (status)
            goto end;
    }

    if (!(ctx = TS_RESP_CTX_new())) {
        err_msg = "Memory allocation failed.";
        goto end;
    }

    TS_RESP_CTX_set_serial_cb(ctx, ossl_tsfac_serial_cb, &asn1_serial);
    if (!TS_RESP_CTX_set_signer_cert(ctx, tsa_cert)) {
        err_msg = "Certificate does not contain the timestamping extension";
        goto end;
    }

    additional_certs = ossl_tsfac_get_additional_certs(self);
    if (rb_obj_is_kind_of(additional_certs, rb_cArray)) {
        inter_certs = ossl_protect_x509_ary2sk(additional_certs, &status);
        if (status)
                goto end;

        /* this dups the sk_X509 and ups each cert's ref count */
        TS_RESP_CTX_set_certs(ctx, inter_certs);
        sk_X509_pop_free(inter_certs, X509_free);
    }

    TS_RESP_CTX_set_signer_key(ctx, sign_key);
    if (!NIL_P(def_policy_id) && !TS_REQ_get_policy_id(req))
        TS_RESP_CTX_set_def_policy(ctx, def_policy_id_obj);
    if (TS_REQ_get_policy_id(req))
        TS_RESP_CTX_set_def_policy(ctx, TS_REQ_get_policy_id(req));
    TS_RESP_CTX_set_time_cb(ctx, ossl_tsfac_time_cb, &lgen_time);

    allowed_digests = ossl_tsfac_get_allowed_digests(self);
    if (rb_obj_is_kind_of(allowed_digests, rb_cArray)) {
        int i;
        VALUE rbmd;
        const EVP_MD *md;

        for (i = 0; i < RARRAY_LEN(allowed_digests); i++) {
            rbmd = rb_ary_entry(allowed_digests, i);
            md = (const EVP_MD *)rb_protect(ossl_evp_get_digestbyname_i, rbmd, &status);
            if (status)
                goto end;
            TS_RESP_CTX_add_md(ctx, md);
        }
    }

    str = rb_protect(ossl_to_der, request, &status);
    if (status)
        goto end;

    req_bio = (BIO*)rb_protect(ossl_obj2bio_i, (VALUE)&str, &status);
    if (status)
        goto end;

    response = TS_RESP_create_response(ctx, req_bio);
    BIO_free(req_bio);

    if (!response) {
        err_msg = "Error during response generation";
        goto end;
    }

    /* bad responses aren't exceptional, but openssl still sets error
     * information. */
    ossl_clear_error();

    SetTSResponse(tsresp, response);
    ret = tsresp;

end:
    ASN1_INTEGER_free(asn1_serial);
    ASN1_OBJECT_free(def_policy_id_obj);
    TS_RESP_CTX_free(ctx);
    if (err_msg)
        rb_exc_raise(ossl_make_error(eTimestampError, rb_str_new_cstr(err_msg)));
    if (status)
        rb_jump_tag(status);
    return ret;
}

/*
 * INIT
 */
void
Init_ossl_ts(void)
{
    #if 0
    mOSSL = rb_define_module("OpenSSL"); /* let rdoc know about mOSSL */
    #endif

    /*
     * Possible return value for +Response#failure_info+. Indicates that the
     * timestamp server rejects the message imprint algorithm used in the
     * +Request+
     */
    sBAD_ALG = ID2SYM(rb_intern_const("BAD_ALG"));

    /*
     * Possible return value for +Response#failure_info+. Indicates that the
     * timestamp server was not able to process the +Request+ properly.
     */
    sBAD_REQUEST = ID2SYM(rb_intern_const("BAD_REQUEST"));
    /*
     * Possible return value for +Response#failure_info+. Indicates that the
     * timestamp server was not able to parse certain data in the +Request+.
     */
    sBAD_DATA_FORMAT = ID2SYM(rb_intern_const("BAD_DATA_FORMAT"));

    sTIME_NOT_AVAILABLE = ID2SYM(rb_intern_const("TIME_NOT_AVAILABLE"));
    sUNACCEPTED_POLICY = ID2SYM(rb_intern_const("UNACCEPTED_POLICY"));
    sUNACCEPTED_EXTENSION = ID2SYM(rb_intern_const("UNACCEPTED_EXTENSION"));
    sADD_INFO_NOT_AVAILABLE = ID2SYM(rb_intern_const("ADD_INFO_NOT_AVAILABLE"));
    sSYSTEM_FAILURE = ID2SYM(rb_intern_const("SYSTEM_FAILURE"));

    /* Document-class: OpenSSL::Timestamp
     * Provides classes and methods to request, create and validate
     * {RFC3161-compliant}[http://www.ietf.org/rfc/rfc3161.txt] timestamps.
     * Request may be used to either create requests from scratch or to parse
     * existing requests that again can be used to request timestamps from a
     * timestamp server, e.g. via the net/http. The resulting timestamp
     * response may be parsed using Response.
     *
     * Please note that Response is read-only and immutable. To create a
     * Response, an instance of Factory as well as a valid Request are needed.
     *
     * ===Create a Response:
     *      #Assumes ts.p12 is a PKCS#12-compatible file with a private key
     *      #and a certificate that has an extended key usage of 'timeStamping'
     *      p12 = OpenSSL::PKCS12.new(File.binread('ts.p12'), 'pwd')
     *      md = OpenSSL::Digest.new('SHA1')
     *      hash = md.digest(data) #some binary data to be timestamped
     *      req = OpenSSL::Timestamp::Request.new
     *      req.algorithm = 'SHA1'
     *      req.message_imprint = hash
     *      req.policy_id = "1.2.3.4.5"
     *      req.nonce = 42
     *      fac = OpenSSL::Timestamp::Factory.new
     *      fac.gen_time = Time.now
     *      fac.serial_number = 1
     *      timestamp = fac.create_timestamp(p12.key, p12.certificate, req)
     *
     * ===Verify a timestamp response:
     *      #Assume we have a timestamp token in a file called ts.der
     *      ts = OpenSSL::Timestamp::Response.new(File.binread('ts.der'))
     *      #Assume we have the Request for this token in a file called req.der
     *      req = OpenSSL::Timestamp::Request.new(File.binread('req.der'))
     *      # Assume the associated root CA certificate is contained in a
     *      # DER-encoded file named root.cer
     *      root = OpenSSL::X509::Certificate.new(File.binread('root.cer'))
     *      # get the necessary intermediate certificates, available in
     *      # DER-encoded form in inter1.cer and inter2.cer
     *      inter1 = OpenSSL::X509::Certificate.new(File.binread('inter1.cer'))
     *      inter2 = OpenSSL::X509::Certificate.new(File.binread('inter2.cer'))
     *      ts.verify(req, root, inter1, inter2) -> ts or raises an exception if validation fails
     *
     */
    mTimestamp = rb_define_module_under(mOSSL, "Timestamp");

    /* Document-class: OpenSSL::Timestamp::TimestampError
     * Generic exception class of the Timestamp module.
     */
    eTimestampError = rb_define_class_under(mTimestamp, "TimestampError", eOSSLError);

    /* Document-class: OpenSSL::Timestamp::Response
     * Immutable and read-only representation of a timestamp response returned
     * from a timestamp server after receiving an associated Request. Allows
     * access to specific information about the response but also allows to
     * verify the Response.
     */
    cTimestampResponse = rb_define_class_under(mTimestamp, "Response", rb_cObject);
    rb_define_alloc_func(cTimestampResponse, ossl_ts_resp_alloc);
    rb_define_method(cTimestampResponse, "initialize", ossl_ts_resp_initialize, 1);
    rb_define_method(cTimestampResponse, "status", ossl_ts_resp_get_status, 0);
    rb_define_method(cTimestampResponse, "failure_info", ossl_ts_resp_get_failure_info, 0);
    rb_define_method(cTimestampResponse, "status_text", ossl_ts_resp_get_status_text, 0);
    rb_define_method(cTimestampResponse, "token", ossl_ts_resp_get_token, 0);
    rb_define_method(cTimestampResponse, "token_info", ossl_ts_resp_get_token_info, 0);
    rb_define_method(cTimestampResponse, "tsa_certificate", ossl_ts_resp_get_tsa_certificate, 0);
    rb_define_method(cTimestampResponse, "to_der", ossl_ts_resp_to_der, 0);
    rb_define_method(cTimestampResponse, "verify", ossl_ts_resp_verify, -1);

    /* Document-class: OpenSSL::Timestamp::TokenInfo
     * Immutable and read-only representation of a timestamp token info from a
     * Response.
     */
    cTimestampTokenInfo = rb_define_class_under(mTimestamp, "TokenInfo", rb_cObject);
    rb_define_alloc_func(cTimestampTokenInfo, ossl_ts_token_info_alloc);
    rb_define_method(cTimestampTokenInfo, "initialize", ossl_ts_token_info_initialize, 1);
    rb_define_method(cTimestampTokenInfo, "version", ossl_ts_token_info_get_version, 0);
    rb_define_method(cTimestampTokenInfo, "policy_id", ossl_ts_token_info_get_policy_id, 0);
    rb_define_method(cTimestampTokenInfo, "algorithm", ossl_ts_token_info_get_algorithm, 0);
    rb_define_method(cTimestampTokenInfo, "message_imprint", ossl_ts_token_info_get_msg_imprint, 0);
    rb_define_method(cTimestampTokenInfo, "serial_number", ossl_ts_token_info_get_serial_number, 0);
    rb_define_method(cTimestampTokenInfo, "gen_time", ossl_ts_token_info_get_gen_time, 0);
    rb_define_method(cTimestampTokenInfo, "ordering", ossl_ts_token_info_get_ordering, 0);
    rb_define_method(cTimestampTokenInfo, "nonce", ossl_ts_token_info_get_nonce, 0);
    rb_define_method(cTimestampTokenInfo, "to_der", ossl_ts_token_info_to_der, 0);

    /* Document-class: OpenSSL::Timestamp::Request
     * Allows to create timestamp requests or parse existing ones. A Request is
     * also needed for creating timestamps from scratch with Factory. When
     * created from scratch, some default values are set:
     * * version is set to +1+
     * * cert_requested is set to +true+
     * * algorithm, message_imprint, policy_id, and nonce are set to +false+
     */
    cTimestampRequest = rb_define_class_under(mTimestamp, "Request", rb_cObject);
    rb_define_alloc_func(cTimestampRequest, ossl_ts_req_alloc);
    rb_define_method(cTimestampRequest, "initialize", ossl_ts_req_initialize, -1);
    rb_define_method(cTimestampRequest, "version=", ossl_ts_req_set_version, 1);
    rb_define_method(cTimestampRequest, "version", ossl_ts_req_get_version, 0);
    rb_define_method(cTimestampRequest, "algorithm=", ossl_ts_req_set_algorithm, 1);
    rb_define_method(cTimestampRequest, "algorithm", ossl_ts_req_get_algorithm, 0);
    rb_define_method(cTimestampRequest, "message_imprint=", ossl_ts_req_set_msg_imprint, 1);
    rb_define_method(cTimestampRequest, "message_imprint", ossl_ts_req_get_msg_imprint, 0);
    rb_define_method(cTimestampRequest, "policy_id=", ossl_ts_req_set_policy_id, 1);
    rb_define_method(cTimestampRequest, "policy_id", ossl_ts_req_get_policy_id, 0);
    rb_define_method(cTimestampRequest, "nonce=", ossl_ts_req_set_nonce, 1);
    rb_define_method(cTimestampRequest, "nonce", ossl_ts_req_get_nonce, 0);
    rb_define_method(cTimestampRequest, "cert_requested=", ossl_ts_req_set_cert_requested, 1);
    rb_define_method(cTimestampRequest, "cert_requested?", ossl_ts_req_get_cert_requested, 0);
    rb_define_method(cTimestampRequest, "to_der", ossl_ts_req_to_der, 0);

    /*
     * Indicates a successful response. Equal to +0+.
     */
    rb_define_const(cTimestampResponse, "GRANTED", INT2NUM(TS_STATUS_GRANTED));
    /*
     * Indicates a successful response that probably contains modifications
     * from the initial request. Equal to +1+.
     */
    rb_define_const(cTimestampResponse, "GRANTED_WITH_MODS", INT2NUM(TS_STATUS_GRANTED_WITH_MODS));
    /*
     * Indicates a failure. No timestamp token was created. Equal to +2+.
     */
    rb_define_const(cTimestampResponse, "REJECTION", INT2NUM(TS_STATUS_REJECTION));
    /*
     * Indicates a failure. No timestamp token was created. Equal to +3+.
     */
    rb_define_const(cTimestampResponse, "WAITING", INT2NUM(TS_STATUS_WAITING));
    /*
     * Indicates a failure. No timestamp token was created. Revocation of a
     * certificate is imminent. Equal to +4+.
     */
    rb_define_const(cTimestampResponse, "REVOCATION_WARNING", INT2NUM(TS_STATUS_REVOCATION_WARNING));
    /*
     * Indicates a failure. No timestamp token was created. A certificate
     * has been revoked. Equal to +5+.
     */
    rb_define_const(cTimestampResponse, "REVOCATION_NOTIFICATION", INT2NUM(TS_STATUS_REVOCATION_NOTIFICATION));

    /* Document-class: OpenSSL::Timestamp::Factory
     *
     * Used to generate a Response from scratch.
     *
     * Please bear in mind that the implementation will always apply and prefer
     * the policy object identifier given in the request over the default policy
     * id specified in the Factory. As a consequence, +default_policy_id+ will
     * only be applied if no Request#policy_id was given. But this also means
     * that one needs to check the policy identifier in the request manually
     * before creating the Response, e.g. to check whether it complies to a
     * specific set of acceptable policies.
     *
     * There exists also the possibility to add certificates (instances of
     * OpenSSL::X509::Certificate) besides the timestamping certificate
     * that will be included in the resulting timestamp token if
     * Request#cert_requested? is +true+. Ideally, one would also include any
     * intermediate certificates (the root certificate can be left out - in
     * order to trust it any verifying party will have to be in its possession
     * anyway). This simplifies validation of the timestamp since these
     * intermediate certificates are "already there" and need not be passed as
     * external parameters to Response#verify anymore, thus minimizing external
     * resources needed for verification.
     *
     * ===Example: Inclusion of (untrusted) intermediate certificates
     *
     * Assume we received a timestamp request that has set Request#policy_id to
     * +nil+ and Request#cert_requested? to true. The raw request bytes are
     * stored in a variable called +req_raw+. We'd still like to integrate
     * the necessary intermediate certificates (in +inter1.cer+ and
     * +inter2.cer+) to simplify validation of the resulting Response. +ts.p12+
     * is a PKCS#12-compatible file including the private key and the
     * timestamping certificate.
     *
     *      req = OpenSSL::Timestamp::Request.new(raw_bytes)
     *      p12 = OpenSSL::PKCS12.new(File.binread('ts.p12'), 'pwd')
     *      inter1 = OpenSSL::X509::Certificate.new(File.binread('inter1.cer'))
     *      inter2 = OpenSSL::X509::Certificate.new(File.binread('inter2.cer'))
     *      fac = OpenSSL::Timestamp::Factory.new
     *      fac.gen_time = Time.now
     *      fac.serial_number = 1
     *      fac.allowed_digests = ["sha256", "sha384", "sha512"]
     *      #needed because the Request contained no policy identifier
     *      fac.default_policy_id = '1.2.3.4.5'
     *      fac.additional_certificates = [ inter1, inter2 ]
     *      timestamp = fac.create_timestamp(p12.key, p12.certificate, req)
     *
     * ==Attributes
     *
     * ===default_policy_id
     *
     * Request#policy_id will always be preferred over this if present in the
     * Request, only if Request#policy_id is nil default_policy will be used.
     * If none of both is present, a TimestampError will be raised when trying
     * to create a Response.
     *
     * call-seq:
     *       factory.default_policy_id = "string" -> string
     *       factory.default_policy_id            -> string or nil
     *
     * ===serial_number
     *
     * Sets or retrieves the serial number to be used for timestamp creation.
     * Must be present for timestamp creation.
     *
     * call-seq:
     *       factory.serial_number = number -> number
     *       factory.serial_number          -> number or nil
     *
     * ===gen_time
     *
     * Sets or retrieves the Time value to be used in the Response. Must be
     * present for timestamp creation.
     *
     * call-seq:
     *       factory.gen_time = Time -> Time
     *       factory.gen_time        -> Time or nil
     *
     * ===additional_certs
     *
     * Sets or retrieves additional certificates apart from the timestamp
     * certificate (e.g. intermediate certificates) to be added to the Response.
     * Must be an Array of OpenSSL::X509::Certificate.
     *
     * call-seq:
     *       factory.additional_certs = [cert1, cert2] -> [ cert1, cert2 ]
     *       factory.additional_certs                  -> array or nil
     *
     * ===allowed_digests
     *
     * Sets or retrieves the digest algorithms that the factory is allowed
     * create timestamps for. Known vulnerable or weak algorithms should not be
     * allowed where possible.
     * Must be an Array of String or OpenSSL::Digest subclass instances.
     *
     * call-seq:
     *       factory.allowed_digests = ["sha1", OpenSSL::Digest.new('SHA256').new] -> [ "sha1", OpenSSL::Digest) ]
     *       factory.allowed_digests                                               -> array or nil
     *
     */
    cTimestampFactory = rb_define_class_under(mTimestamp, "Factory", rb_cObject);
    rb_attr(cTimestampFactory, rb_intern_const("allowed_digests"), 1, 1, 0);
    rb_attr(cTimestampFactory, rb_intern_const("default_policy_id"), 1, 1, 0);
    rb_attr(cTimestampFactory, rb_intern_const("serial_number"), 1, 1, 0);
    rb_attr(cTimestampFactory, rb_intern_const("gen_time"), 1, 1, 0);
    rb_attr(cTimestampFactory, rb_intern_const("additional_certs"), 1, 1, 0);
    rb_define_method(cTimestampFactory, "create_timestamp", ossl_tsfac_create_ts, 3);
}

#endif
