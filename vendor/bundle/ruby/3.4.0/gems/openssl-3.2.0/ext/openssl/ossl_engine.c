/*
 * 'OpenSSL for Ruby' project
 * Copyright (C) 2003  GOTOU Yuuzou <gotoyuzo@notwork.org>
 * All rights reserved.
 */
/*
 * This program is licensed under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#include "ossl.h"

#ifdef OSSL_USE_ENGINE
# include <openssl/engine.h>

#define NewEngine(klass) \
    TypedData_Wrap_Struct((klass), &ossl_engine_type, 0)
#define SetEngine(obj, engine) do { \
    if (!(engine)) { \
	ossl_raise(rb_eRuntimeError, "ENGINE wasn't initialized."); \
    } \
    RTYPEDDATA_DATA(obj) = (engine); \
} while(0)
#define GetEngine(obj, engine) do { \
    TypedData_Get_Struct((obj), ENGINE, &ossl_engine_type, (engine)); \
    if (!(engine)) { \
        ossl_raise(rb_eRuntimeError, "ENGINE wasn't initialized."); \
    } \
} while (0)

/*
 * Classes
 */
/* Document-class: OpenSSL::Engine
 *
 * This class is the access to openssl's ENGINE cryptographic module
 * implementation.
 *
 * See also, https://www.openssl.org/docs/crypto/engine.html
 */
VALUE cEngine;
/* Document-class: OpenSSL::Engine::EngineError
 *
 * This is the generic exception for OpenSSL::Engine related errors
 */
VALUE eEngineError;

/*
 * Private
 */
#if !defined(LIBRESSL_VERSION_NUMBER) && OPENSSL_VERSION_NUMBER >= 0x10100000
#define OSSL_ENGINE_LOAD_IF_MATCH(engine_name, x) \
do{\
  if(!strcmp(#engine_name, RSTRING_PTR(name))){\
    if (OPENSSL_init_crypto(OPENSSL_INIT_ENGINE_##x, NULL))\
      return Qtrue;\
    else\
      ossl_raise(eEngineError, "OPENSSL_init_crypto"); \
  }\
}while(0)
#else
#define OSSL_ENGINE_LOAD_IF_MATCH(engine_name, x)  \
do{\
  if(!strcmp(#engine_name, RSTRING_PTR(name))){\
    ENGINE_load_##engine_name();\
    return Qtrue;\
  }\
}while(0)
#endif

static void
ossl_engine_free(void *engine)
{
    ENGINE_free(engine);
}

static const rb_data_type_t ossl_engine_type = {
    "OpenSSL/Engine",
    {
	0, ossl_engine_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

/*
 * call-seq:
 *    OpenSSL::Engine.load(name = nil)
 *
 * This method loads engines. If _name_ is nil, then all builtin engines are
 * loaded. Otherwise, the given _name_, as a String,  is loaded if available to
 * your runtime, and returns true. If _name_ is not found, then nil is
 * returned.
 *
 */
static VALUE
ossl_engine_s_load(int argc, VALUE *argv, VALUE klass)
{
    VALUE name;

    rb_scan_args(argc, argv, "01", &name);
    if(NIL_P(name)){
        ENGINE_load_builtin_engines();
        return Qtrue;
    }
    StringValueCStr(name);
#ifdef HAVE_ENGINE_LOAD_DYNAMIC
    OSSL_ENGINE_LOAD_IF_MATCH(dynamic, DYNAMIC);
#endif
#ifndef OPENSSL_NO_STATIC_ENGINE
#ifdef HAVE_ENGINE_LOAD_4758CCA
    OSSL_ENGINE_LOAD_IF_MATCH(4758cca, 4758CCA);
#endif
#ifdef HAVE_ENGINE_LOAD_AEP
    OSSL_ENGINE_LOAD_IF_MATCH(aep, AEP);
#endif
#ifdef HAVE_ENGINE_LOAD_ATALLA
    OSSL_ENGINE_LOAD_IF_MATCH(atalla, ATALLA);
#endif
#ifdef HAVE_ENGINE_LOAD_CHIL
    OSSL_ENGINE_LOAD_IF_MATCH(chil, CHIL);
#endif
#ifdef HAVE_ENGINE_LOAD_CSWIFT
    OSSL_ENGINE_LOAD_IF_MATCH(cswift, CSWIFT);
#endif
#ifdef HAVE_ENGINE_LOAD_NURON
    OSSL_ENGINE_LOAD_IF_MATCH(nuron, NURON);
#endif
#ifdef HAVE_ENGINE_LOAD_SUREWARE
    OSSL_ENGINE_LOAD_IF_MATCH(sureware, SUREWARE);
#endif
#ifdef HAVE_ENGINE_LOAD_UBSEC
    OSSL_ENGINE_LOAD_IF_MATCH(ubsec, UBSEC);
#endif
#ifdef HAVE_ENGINE_LOAD_PADLOCK
    OSSL_ENGINE_LOAD_IF_MATCH(padlock, PADLOCK);
#endif
#ifdef HAVE_ENGINE_LOAD_CAPI
    OSSL_ENGINE_LOAD_IF_MATCH(capi, CAPI);
#endif
#ifdef HAVE_ENGINE_LOAD_GMP
    OSSL_ENGINE_LOAD_IF_MATCH(gmp, GMP);
#endif
#ifdef HAVE_ENGINE_LOAD_GOST
    OSSL_ENGINE_LOAD_IF_MATCH(gost, GOST);
#endif
#endif
#ifdef HAVE_ENGINE_LOAD_CRYPTODEV
    OSSL_ENGINE_LOAD_IF_MATCH(cryptodev, CRYPTODEV);
#endif
    OSSL_ENGINE_LOAD_IF_MATCH(openssl, OPENSSL);
    rb_warning("no such builtin loader for `%"PRIsVALUE"'", name);
    return Qnil;
}

/*
 * call-seq:
 *    OpenSSL::Engine.cleanup
 *
 * It is only necessary to run cleanup when engines are loaded via
 * OpenSSL::Engine.load. However, running cleanup before exit is recommended.
 *
 * Note that this is needed and works only in OpenSSL < 1.1.0.
 */
static VALUE
ossl_engine_s_cleanup(VALUE self)
{
#if defined(LIBRESSL_VERSION_NUMBER) || OPENSSL_VERSION_NUMBER < 0x10100000
    ENGINE_cleanup();
#endif
    return Qnil;
}

/*
 * call-seq:
 *    OpenSSL::Engine.engines -> [engine, ...]
 *
 * Returns an array of currently loaded engines.
 */
static VALUE
ossl_engine_s_engines(VALUE klass)
{
    ENGINE *e;
    VALUE ary, obj;

    ary = rb_ary_new();
    for(e = ENGINE_get_first(); e; e = ENGINE_get_next(e)){
	obj = NewEngine(klass);
	/* Need a ref count of two here because of ENGINE_free being
	 * called internally by OpenSSL when moving to the next ENGINE
	 * and by us when releasing the ENGINE reference */
	ENGINE_up_ref(e);
	SetEngine(obj, e);
        rb_ary_push(ary, obj);
    }

    return ary;
}

/*
 * call-seq:
 *    OpenSSL::Engine.by_id(name) -> engine
 *
 * Fetches the engine as specified by the _id_ String.
 *
 *   OpenSSL::Engine.by_id("openssl")
 *    => #<OpenSSL::Engine id="openssl" name="Software engine support">
 *
 * See OpenSSL::Engine.engines for the currently loaded engines.
 */
static VALUE
ossl_engine_s_by_id(VALUE klass, VALUE id)
{
    ENGINE *e;
    VALUE obj;

    StringValueCStr(id);
    ossl_engine_s_load(1, &id, klass);
    obj = NewEngine(klass);
    if(!(e = ENGINE_by_id(RSTRING_PTR(id))))
	ossl_raise(eEngineError, NULL);
    SetEngine(obj, e);
    if(rb_block_given_p()) rb_yield(obj);
    if(!ENGINE_init(e))
	ossl_raise(eEngineError, NULL);
    ENGINE_ctrl(e, ENGINE_CTRL_SET_PASSWORD_CALLBACK,
		0, NULL, (void(*)(void))ossl_pem_passwd_cb);
    ossl_clear_error();

    return obj;
}

/*
 * call-seq:
 *    engine.id -> string
 *
 * Gets the id for this engine.
 *
 *    OpenSSL::Engine.load
 *    OpenSSL::Engine.engines #=> [#<OpenSSL::Engine#>, ...]
 *    OpenSSL::Engine.engines.first.id
 *	#=> "rsax"
 */
static VALUE
ossl_engine_get_id(VALUE self)
{
    ENGINE *e;
    GetEngine(self, e);
    return rb_str_new2(ENGINE_get_id(e));
}

/*
 * call-seq:
 *    engine.name -> string
 *
 * Get the descriptive name for this engine.
 *
 *    OpenSSL::Engine.load
 *    OpenSSL::Engine.engines #=> [#<OpenSSL::Engine#>, ...]
 *    OpenSSL::Engine.engines.first.name
 *	#=> "RSAX engine support"
 *
 */
static VALUE
ossl_engine_get_name(VALUE self)
{
    ENGINE *e;
    GetEngine(self, e);
    return rb_str_new2(ENGINE_get_name(e));
}

/*
 * call-seq:
 *    engine.finish -> nil
 *
 * Releases all internal structural references for this engine.
 *
 * May raise an EngineError if the engine is unavailable
 */
static VALUE
ossl_engine_finish(VALUE self)
{
    ENGINE *e;

    GetEngine(self, e);
    if(!ENGINE_finish(e)) ossl_raise(eEngineError, NULL);

    return Qnil;
}

/*
 * call-seq:
 *   engine.cipher(name) -> OpenSSL::Cipher
 *
 * Returns a new instance of OpenSSL::Cipher by _name_, if it is available in
 * this engine.
 *
 * An EngineError will be raised if the cipher is unavailable.
 *
 *    e = OpenSSL::Engine.by_id("openssl")
 *     => #<OpenSSL::Engine id="openssl" name="Software engine support">
 *    e.cipher("RC4")
 *     => #<OpenSSL::Cipher:0x007fc5cacc3048>
 *
 */
static VALUE
ossl_engine_get_cipher(VALUE self, VALUE name)
{
    ENGINE *e;
    const EVP_CIPHER *ciph, *tmp;
    int nid;

    tmp = EVP_get_cipherbyname(StringValueCStr(name));
    if(!tmp) ossl_raise(eEngineError, "no such cipher `%"PRIsVALUE"'", name);
    nid = EVP_CIPHER_nid(tmp);
    GetEngine(self, e);
    ciph = ENGINE_get_cipher(e, nid);
    if(!ciph) ossl_raise(eEngineError, NULL);

    return ossl_cipher_new(ciph);
}

/*
 * call-seq:
 *   engine.digest(name) -> OpenSSL::Digest
 *
 * Returns a new instance of OpenSSL::Digest by _name_.
 *
 * Will raise an EngineError if the digest is unavailable.
 *
 *    e = OpenSSL::Engine.by_id("openssl")
 *	#=> #<OpenSSL::Engine id="openssl" name="Software engine support">
 *    e.digest("SHA1")
 *	#=> #<OpenSSL::Digest: da39a3ee5e6b4b0d3255bfef95601890afd80709>
 *    e.digest("zomg")
 *	#=> OpenSSL::Engine::EngineError: no such digest `zomg'
 */
static VALUE
ossl_engine_get_digest(VALUE self, VALUE name)
{
    ENGINE *e;
    const EVP_MD *md, *tmp;
    int nid;

    tmp = EVP_get_digestbyname(StringValueCStr(name));
    if(!tmp) ossl_raise(eEngineError, "no such digest `%"PRIsVALUE"'", name);
    nid = EVP_MD_nid(tmp);
    GetEngine(self, e);
    md = ENGINE_get_digest(e, nid);
    if(!md) ossl_raise(eEngineError, NULL);

    return ossl_digest_new(md);
}

/*
 * call-seq:
 *    engine.load_private_key(id = nil, data = nil) -> OpenSSL::PKey
 *
 * Loads the given private key identified by _id_ and _data_.
 *
 * An EngineError is raised of the OpenSSL::PKey is unavailable.
 *
 */
static VALUE
ossl_engine_load_privkey(int argc, VALUE *argv, VALUE self)
{
    ENGINE *e;
    EVP_PKEY *pkey;
    VALUE id, data, obj;
    char *sid, *sdata;

    rb_scan_args(argc, argv, "02", &id, &data);
    sid = NIL_P(id) ? NULL : StringValueCStr(id);
    sdata = NIL_P(data) ? NULL : StringValueCStr(data);
    GetEngine(self, e);
    pkey = ENGINE_load_private_key(e, sid, NULL, sdata);
    if (!pkey) ossl_raise(eEngineError, NULL);
    obj = ossl_pkey_new(pkey);
    OSSL_PKEY_SET_PRIVATE(obj);

    return obj;
}

/*
 * call-seq:
 *    engine.load_public_key(id = nil, data = nil) -> OpenSSL::PKey
 *
 * Loads the given public key identified by _id_ and _data_.
 *
 * An EngineError is raised of the OpenSSL::PKey is unavailable.
 *
 */
static VALUE
ossl_engine_load_pubkey(int argc, VALUE *argv, VALUE self)
{
    ENGINE *e;
    EVP_PKEY *pkey;
    VALUE id, data;
    char *sid, *sdata;

    rb_scan_args(argc, argv, "02", &id, &data);
    sid = NIL_P(id) ? NULL : StringValueCStr(id);
    sdata = NIL_P(data) ? NULL : StringValueCStr(data);
    GetEngine(self, e);
    pkey = ENGINE_load_public_key(e, sid, NULL, sdata);
    if (!pkey) ossl_raise(eEngineError, NULL);

    return ossl_pkey_new(pkey);
}

/*
 * call-seq:
 *    engine.set_default(flag)
 *
 * Set the defaults for this engine with the given _flag_.
 *
 * These flags are used to control combinations of algorithm methods.
 *
 * _flag_ can be one of the following, other flags are available depending on
 * your OS.
 *
 * [All flags]  0xFFFF
 * [No flags]	0x0000
 *
 * See also <openssl/engine.h>
 */
static VALUE
ossl_engine_set_default(VALUE self, VALUE flag)
{
    ENGINE *e;
    int f = NUM2INT(flag);

    GetEngine(self, e);
    ENGINE_set_default(e, f);

    return Qtrue;
}

/*
 * call-seq:
 *    engine.ctrl_cmd(command, value = nil) -> engine
 *
 * Sends the given _command_ to this engine.
 *
 * Raises an EngineError if the command fails.
 */
static VALUE
ossl_engine_ctrl_cmd(int argc, VALUE *argv, VALUE self)
{
    ENGINE *e;
    VALUE cmd, val;
    int ret;

    GetEngine(self, e);
    rb_scan_args(argc, argv, "11", &cmd, &val);
    ret = ENGINE_ctrl_cmd_string(e, StringValueCStr(cmd),
				 NIL_P(val) ? NULL : StringValueCStr(val), 0);
    if (!ret) ossl_raise(eEngineError, NULL);

    return self;
}

static VALUE
ossl_engine_cmd_flag_to_name(int flag)
{
    switch(flag){
    case ENGINE_CMD_FLAG_NUMERIC:  return rb_str_new2("NUMERIC");
    case ENGINE_CMD_FLAG_STRING:   return rb_str_new2("STRING");
    case ENGINE_CMD_FLAG_NO_INPUT: return rb_str_new2("NO_INPUT");
    case ENGINE_CMD_FLAG_INTERNAL: return rb_str_new2("INTERNAL");
    default: return rb_str_new2("UNKNOWN");
    }
}

/*
 * call-seq:
 *    engine.cmds -> [["name", "description", "flags"], ...]
 *
 * Returns an array of command definitions for the current engine
 */
static VALUE
ossl_engine_get_cmds(VALUE self)
{
    ENGINE *e;
    const ENGINE_CMD_DEFN *defn, *p;
    VALUE ary, tmp;

    GetEngine(self, e);
    ary = rb_ary_new();
    if ((defn = ENGINE_get_cmd_defns(e)) != NULL){
	for (p = defn; p->cmd_num > 0; p++){
	    tmp = rb_ary_new();
	    rb_ary_push(tmp, rb_str_new2(p->cmd_name));
	    rb_ary_push(tmp, rb_str_new2(p->cmd_desc));
	    rb_ary_push(tmp, ossl_engine_cmd_flag_to_name(p->cmd_flags));
	    rb_ary_push(ary, tmp);
	}
    }

    return ary;
}

/*
 * call-seq:
 *    engine.inspect -> string
 *
 * Pretty prints this engine.
 */
static VALUE
ossl_engine_inspect(VALUE self)
{
    ENGINE *e;

    GetEngine(self, e);
    return rb_sprintf("#<%"PRIsVALUE" id=\"%s\" name=\"%s\">",
		      rb_obj_class(self), ENGINE_get_id(e), ENGINE_get_name(e));
}

#define DefEngineConst(x) rb_define_const(cEngine, #x, INT2NUM(ENGINE_##x))

void
Init_ossl_engine(void)
{
#if 0
    mOSSL = rb_define_module("OpenSSL");
    eOSSLError = rb_define_class_under(mOSSL, "OpenSSLError", rb_eStandardError);
#endif

    cEngine = rb_define_class_under(mOSSL, "Engine", rb_cObject);
    eEngineError = rb_define_class_under(cEngine, "EngineError", eOSSLError);

    rb_undef_alloc_func(cEngine);
    rb_define_singleton_method(cEngine, "load", ossl_engine_s_load, -1);
    rb_define_singleton_method(cEngine, "cleanup", ossl_engine_s_cleanup, 0);
    rb_define_singleton_method(cEngine, "engines", ossl_engine_s_engines, 0);
    rb_define_singleton_method(cEngine, "by_id", ossl_engine_s_by_id, 1);

    rb_define_method(cEngine, "id", ossl_engine_get_id, 0);
    rb_define_method(cEngine, "name", ossl_engine_get_name, 0);
    rb_define_method(cEngine, "finish", ossl_engine_finish, 0);
    rb_define_method(cEngine, "cipher", ossl_engine_get_cipher, 1);
    rb_define_method(cEngine, "digest",  ossl_engine_get_digest, 1);
    rb_define_method(cEngine, "load_private_key", ossl_engine_load_privkey, -1);
    rb_define_method(cEngine, "load_public_key", ossl_engine_load_pubkey, -1);
    rb_define_method(cEngine, "set_default", ossl_engine_set_default, 1);
    rb_define_method(cEngine, "ctrl_cmd", ossl_engine_ctrl_cmd, -1);
    rb_define_method(cEngine, "cmds", ossl_engine_get_cmds, 0);
    rb_define_method(cEngine, "inspect", ossl_engine_inspect, 0);

    DefEngineConst(METHOD_RSA);
    DefEngineConst(METHOD_DSA);
    DefEngineConst(METHOD_DH);
    DefEngineConst(METHOD_RAND);
#ifdef ENGINE_METHOD_BN_MOD_EXP
    DefEngineConst(METHOD_BN_MOD_EXP);
#endif
#ifdef ENGINE_METHOD_BN_MOD_EXP_CRT
    DefEngineConst(METHOD_BN_MOD_EXP_CRT);
#endif
    DefEngineConst(METHOD_CIPHERS);
    DefEngineConst(METHOD_DIGESTS);
    DefEngineConst(METHOD_ALL);
    DefEngineConst(METHOD_NONE);
}
#else
void
Init_ossl_engine(void)
{
}
#endif
