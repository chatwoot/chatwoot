#define RSTRING_NOT_MODIFIED 1

#include <ruby.h>
#include <ruby/version.h>
#include <ruby/io.h>

#ifdef HAVE_OPENSSL_BIO_H

#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/dh.h>
#include <openssl/err.h>
#include <openssl/x509.h>

#ifndef SSL_OP_NO_COMPRESSION
#define SSL_OP_NO_COMPRESSION 0
#endif

typedef struct {
  BIO* read;
  BIO* write;
  SSL* ssl;
  SSL_CTX* ctx;
} ms_conn;

typedef struct {
  unsigned char* buf;
  int bytes;
} ms_cert_buf;

VALUE eError;

NORETURN(void raise_file_error(const char* caller, const char *filename));

void raise_file_error(const char* caller, const char *filename) {
  rb_raise(eError, "%s: error in file '%s': %s", caller, filename, ERR_error_string(ERR_get_error(), NULL));
}

NORETURN(void raise_param_error(const char* caller, const char *param));

void raise_param_error(const char* caller, const char *param) {
  rb_raise(eError, "%s: error with parameter '%s': %s", caller, param, ERR_error_string(ERR_get_error(), NULL));
}

void engine_free(void *ptr) {
  ms_conn *conn = ptr;
  ms_cert_buf* cert_buf = (ms_cert_buf*)SSL_get_app_data(conn->ssl);
  if(cert_buf) {
    OPENSSL_free(cert_buf->buf);
    free(cert_buf);
  }
  SSL_free(conn->ssl);
  SSL_CTX_free(conn->ctx);

  free(conn);
}

const rb_data_type_t engine_data_type = {
    "MiniSSL/ENGINE",
    { 0, engine_free, 0 },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY,
};

#ifndef HAVE_SSL_CTX_SET_DH_AUTO
DH *get_dh2048(void) {
  /* `openssl dhparam -C 2048`
   * -----BEGIN DH PARAMETERS-----
   * MIIBCAKCAQEAjmh1uQHdTfxOyxEbKAV30fUfzqMDF/ChPzjfyzl2jcrqQMhrk76o
   * 2NPNXqxHwsddMZ1RzvU8/jl+uhRuPWjXCFZbhET4N1vrviZM3VJhV8PPHuiVOACO
   * y32jFd+Szx4bo2cXSK83hJ6jRd+0asP1awWjz9/06dFkrILCXMIfQLo0D8rqmppn
   * EfDDAwuudCpM9kcDmBRAm9JsKbQ6gzZWjkc5+QWSaQofojIHbjvj3xzguaCJn+oQ
   * vHWM+hsAnaOgEwCyeZ3xqs+/5lwSbkE/tqJW98cEZGygBUVo9jxZRZx6KOfjpdrb
   * yenO9LJr/qtyrZB31WJbqxI0m0AKTAO8UwIBAg==
   * -----END DH PARAMETERS-----
   */
  static unsigned char dh2048_p[] = {
    0x8E, 0x68, 0x75, 0xB9, 0x01, 0xDD, 0x4D, 0xFC, 0x4E, 0xCB,
    0x11, 0x1B, 0x28, 0x05, 0x77, 0xD1, 0xF5, 0x1F, 0xCE, 0xA3,
    0x03, 0x17, 0xF0, 0xA1, 0x3F, 0x38, 0xDF, 0xCB, 0x39, 0x76,
    0x8D, 0xCA, 0xEA, 0x40, 0xC8, 0x6B, 0x93, 0xBE, 0xA8, 0xD8,
    0xD3, 0xCD, 0x5E, 0xAC, 0x47, 0xC2, 0xC7, 0x5D, 0x31, 0x9D,
    0x51, 0xCE, 0xF5, 0x3C, 0xFE, 0x39, 0x7E, 0xBA, 0x14, 0x6E,
    0x3D, 0x68, 0xD7, 0x08, 0x56, 0x5B, 0x84, 0x44, 0xF8, 0x37,
    0x5B, 0xEB, 0xBE, 0x26, 0x4C, 0xDD, 0x52, 0x61, 0x57, 0xC3,
    0xCF, 0x1E, 0xE8, 0x95, 0x38, 0x00, 0x8E, 0xCB, 0x7D, 0xA3,
    0x15, 0xDF, 0x92, 0xCF, 0x1E, 0x1B, 0xA3, 0x67, 0x17, 0x48,
    0xAF, 0x37, 0x84, 0x9E, 0xA3, 0x45, 0xDF, 0xB4, 0x6A, 0xC3,
    0xF5, 0x6B, 0x05, 0xA3, 0xCF, 0xDF, 0xF4, 0xE9, 0xD1, 0x64,
    0xAC, 0x82, 0xC2, 0x5C, 0xC2, 0x1F, 0x40, 0xBA, 0x34, 0x0F,
    0xCA, 0xEA, 0x9A, 0x9A, 0x67, 0x11, 0xF0, 0xC3, 0x03, 0x0B,
    0xAE, 0x74, 0x2A, 0x4C, 0xF6, 0x47, 0x03, 0x98, 0x14, 0x40,
    0x9B, 0xD2, 0x6C, 0x29, 0xB4, 0x3A, 0x83, 0x36, 0x56, 0x8E,
    0x47, 0x39, 0xF9, 0x05, 0x92, 0x69, 0x0A, 0x1F, 0xA2, 0x32,
    0x07, 0x6E, 0x3B, 0xE3, 0xDF, 0x1C, 0xE0, 0xB9, 0xA0, 0x89,
    0x9F, 0xEA, 0x10, 0xBC, 0x75, 0x8C, 0xFA, 0x1B, 0x00, 0x9D,
    0xA3, 0xA0, 0x13, 0x00, 0xB2, 0x79, 0x9D, 0xF1, 0xAA, 0xCF,
    0xBF, 0xE6, 0x5C, 0x12, 0x6E, 0x41, 0x3F, 0xB6, 0xA2, 0x56,
    0xF7, 0xC7, 0x04, 0x64, 0x6C, 0xA0, 0x05, 0x45, 0x68, 0xF6,
    0x3C, 0x59, 0x45, 0x9C, 0x7A, 0x28, 0xE7, 0xE3, 0xA5, 0xDA,
    0xDB, 0xC9, 0xE9, 0xCE, 0xF4, 0xB2, 0x6B, 0xFE, 0xAB, 0x72,
    0xAD, 0x90, 0x77, 0xD5, 0x62, 0x5B, 0xAB, 0x12, 0x34, 0x9B,
    0x40, 0x0A, 0x4C, 0x03, 0xBC, 0x53
  };
  static unsigned char dh2048_g[] = { 0x02 };

  DH *dh;
#if !(OPENSSL_VERSION_NUMBER < 0x10100005L)
  BIGNUM *p, *g;
#endif

  dh = DH_new();

#if OPENSSL_VERSION_NUMBER < 0x10100005L
  dh->p = BN_bin2bn(dh2048_p, sizeof(dh2048_p), NULL);
  dh->g = BN_bin2bn(dh2048_g, sizeof(dh2048_g), NULL);

  if ((dh->p == NULL) || (dh->g == NULL)) {
    DH_free(dh);
    return NULL;
  }
#else
  p = BN_bin2bn(dh2048_p, sizeof(dh2048_p), NULL);
  g = BN_bin2bn(dh2048_g, sizeof(dh2048_g), NULL);

  if (p == NULL || g == NULL || !DH_set0_pqg(dh, p, NULL, g)) {
    DH_free(dh);
    BN_free(p);
    BN_free(g);
    return NULL;
  }
#endif

  return dh;
}
#endif

static void
sslctx_free(void *ptr) {
  SSL_CTX *ctx = ptr;
  SSL_CTX_free(ctx);
}

static const rb_data_type_t sslctx_type = {
  "MiniSSL/SSLContext",
  {
    0, sslctx_free,
  },
  0, 0, RUBY_TYPED_FREE_IMMEDIATELY,
};

ms_conn* engine_alloc(VALUE klass, VALUE* obj) {
  ms_conn* conn;

  *obj = TypedData_Make_Struct(klass, ms_conn, &engine_data_type, conn);

  conn->read = BIO_new(BIO_s_mem());
  BIO_set_nbio(conn->read, 1);

  conn->write = BIO_new(BIO_s_mem());
  BIO_set_nbio(conn->write, 1);

  conn->ssl = 0;
  conn->ctx = 0;

  return conn;
}

static int engine_verify_callback(int preverify_ok, X509_STORE_CTX* ctx) {
  X509* err_cert;
  SSL* ssl;
  int bytes;
  unsigned char* buf = NULL;

  if(!preverify_ok) {
    err_cert = X509_STORE_CTX_get_current_cert(ctx);
    if(err_cert) {
      /*
       * Save the failed certificate for inspection/logging.
       */
      bytes = i2d_X509(err_cert, &buf);
      if(bytes > 0) {
        ms_cert_buf* cert_buf = (ms_cert_buf*)malloc(sizeof(ms_cert_buf));
        cert_buf->buf = buf;
        cert_buf->bytes = bytes;
        ssl = X509_STORE_CTX_get_ex_data(ctx, SSL_get_ex_data_X509_STORE_CTX_idx());
        SSL_set_app_data(ssl, cert_buf);
      }
    }
  }

  return preverify_ok;
}

static int password_callback(char *buf, int size, int rwflag, void *userdata) {
    const char *password = (const char *) userdata;
    size_t len = strlen(password);

    if (len > (size_t) size) {
      return 0;
    }

    memcpy(buf, password, len);
    return (int) len;
}

static VALUE
sslctx_alloc(VALUE klass) {
  SSL_CTX *ctx;
  long mode = 0 |
    SSL_MODE_ENABLE_PARTIAL_WRITE |
    SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER |
    SSL_MODE_RELEASE_BUFFERS;

#ifdef HAVE_TLS_SERVER_METHOD
  ctx = SSL_CTX_new(TLS_method());
  // printf("\nctx using TLS_method security_level %d\n", SSL_CTX_get_security_level(ctx));
#else
  ctx = SSL_CTX_new(SSLv23_method());
#endif
  if (!ctx) {
    rb_raise(eError, "SSL_CTX_new");
  }
  SSL_CTX_set_mode(ctx, mode);

  return TypedData_Wrap_Struct(klass, &sslctx_type, ctx);
}

VALUE
sslctx_initialize(VALUE self, VALUE mini_ssl_ctx) {
  SSL_CTX* ctx;
  int ssl_options;
  VALUE key, cert, ca, verify_mode, ssl_cipher_filter, no_tlsv1, no_tlsv1_1,
    verification_flags, session_id_bytes, cert_pem, key_pem, key_password_command, key_password;
  BIO *bio;
  X509 *x509 = NULL;
  EVP_PKEY *pkey;
  pem_password_cb *password_cb = NULL;
  const char *password = NULL;
#ifdef HAVE_SSL_CTX_SET_MIN_PROTO_VERSION
  int min;
#endif
#ifndef HAVE_SSL_CTX_SET_DH_AUTO
  DH *dh;
#endif
#if OPENSSL_VERSION_NUMBER < 0x10002000L
  EC_KEY *ecdh;
#endif
#ifdef HAVE_SSL_CTX_SET_SESSION_CACHE_MODE
  VALUE reuse, reuse_cache_size, reuse_timeout;

  reuse = rb_funcall(mini_ssl_ctx, rb_intern_const("reuse"), 0);
  reuse_cache_size = rb_funcall(mini_ssl_ctx, rb_intern_const("reuse_cache_size"), 0);
  reuse_timeout = rb_funcall(mini_ssl_ctx, rb_intern_const("reuse_timeout"), 0);
#endif

  key = rb_funcall(mini_ssl_ctx, rb_intern_const("key"), 0);

  key_password_command = rb_funcall(mini_ssl_ctx, rb_intern_const("key_password_command"), 0);

  cert = rb_funcall(mini_ssl_ctx, rb_intern_const("cert"), 0);

  ca = rb_funcall(mini_ssl_ctx, rb_intern_const("ca"), 0);

  cert_pem = rb_funcall(mini_ssl_ctx, rb_intern_const("cert_pem"), 0);

  key_pem = rb_funcall(mini_ssl_ctx, rb_intern_const("key_pem"), 0);

  verify_mode = rb_funcall(mini_ssl_ctx, rb_intern_const("verify_mode"), 0);

  ssl_cipher_filter = rb_funcall(mini_ssl_ctx, rb_intern_const("ssl_cipher_filter"), 0);

  no_tlsv1 = rb_funcall(mini_ssl_ctx, rb_intern_const("no_tlsv1"), 0);

  no_tlsv1_1 = rb_funcall(mini_ssl_ctx, rb_intern_const("no_tlsv1_1"), 0);

  TypedData_Get_Struct(self, SSL_CTX, &sslctx_type, ctx);

  if (!NIL_P(cert)) {
    StringValue(cert);

    if (SSL_CTX_use_certificate_chain_file(ctx, RSTRING_PTR(cert)) != 1) {
      raise_file_error("SSL_CTX_use_certificate_chain_file", RSTRING_PTR(cert));
    }
  }

  if (!NIL_P(key_password_command)) {
      key_password = rb_funcall(mini_ssl_ctx, rb_intern_const("key_password"), 0);

      if (!NIL_P(key_password)) {
          StringValue(key_password);
          password_cb = password_callback;
          password = RSTRING_PTR(key_password);
          SSL_CTX_set_default_passwd_cb(ctx, password_cb);
          SSL_CTX_set_default_passwd_cb_userdata(ctx, (void *) password);
      }
  }

  if (!NIL_P(key)) {
    StringValue(key);

    if (SSL_CTX_use_PrivateKey_file(ctx, RSTRING_PTR(key), SSL_FILETYPE_PEM) != 1) {
      raise_file_error("SSL_CTX_use_PrivateKey_file", RSTRING_PTR(key));
    }
  }

  if (!NIL_P(cert_pem)) {
    X509 *ca = NULL;
    unsigned long err;

    bio = BIO_new(BIO_s_mem());
    BIO_puts(bio, RSTRING_PTR(cert_pem));

    /**
     * Much of this pulled as a simplified version of the `use_certificate_chain_file` method
     * from openssl's `ssl_rsa.c` file.
     */

    /* first read the cert as the first item in the pem file */
    x509 = PEM_read_bio_X509(bio, NULL, NULL, NULL);
    if (NULL == x509) {
      BIO_free_all(bio);
      raise_param_error("PEM_read_bio_X509", "cert_pem");
    }

    /* Add the cert to the context */
    /* 1 is success - otherwise check the error codes */
    if (1 != SSL_CTX_use_certificate(ctx, x509)) {
      BIO_free_all(bio);
      raise_param_error("SSL_CTX_use_certificate", "cert_pem");
    }

    X509_free(x509); /* no longer need our reference */

    /* Now lets load up the rest of the certificate chain */
    /* 1 is success 0 is error */
    if (0 == SSL_CTX_clear_chain_certs(ctx)) {
      BIO_free_all(bio);
      raise_param_error("SSL_CTX_clear_chain_certs","cert_pem");
    }

    while (1) {
      ca = PEM_read_bio_X509(bio, NULL, NULL, NULL);

      if (NULL == ca) {
        break;
      }

      if (0 == SSL_CTX_add0_chain_cert(ctx, ca)) {
        BIO_free_all(bio);
        raise_param_error("SSL_CTX_add0_chain_cert","cert_pem");
      }
      /* don't free ca - its now owned by the context */
    }

    /* ca is NULL - so its either the end of the file or an error */
    err = ERR_peek_last_error();

    /* If its the end of the file - then we are done, in any case free the bio */
    BIO_free_all(bio);

    if ((ERR_GET_LIB(err) == ERR_LIB_PEM) && (ERR_GET_REASON(err) == PEM_R_NO_START_LINE)) {
      ERR_clear_error();
    } else {
      raise_param_error("PEM_read_bio_X509","cert_pem");
    }
  }

  if (!NIL_P(key_pem)) {
    bio = BIO_new(BIO_s_mem());
    BIO_puts(bio, RSTRING_PTR(key_pem));
    pkey = PEM_read_bio_PrivateKey(bio, NULL, password_cb, (void *) password);

    if (SSL_CTX_use_PrivateKey(ctx, pkey) != 1) {
      BIO_free(bio);
      raise_file_error("SSL_CTX_use_PrivateKey", RSTRING_PTR(key_pem));
    }
    EVP_PKEY_free(pkey);
    BIO_free(bio);
  }

  verification_flags = rb_funcall(mini_ssl_ctx, rb_intern_const("verification_flags"), 0);

  if (!NIL_P(verification_flags)) {
    X509_VERIFY_PARAM *param = SSL_CTX_get0_param(ctx);
    X509_VERIFY_PARAM_set_flags(param, NUM2INT(verification_flags));
    SSL_CTX_set1_param(ctx, param);
  }

  if (!NIL_P(ca)) {
    StringValue(ca);
    if (SSL_CTX_load_verify_locations(ctx, RSTRING_PTR(ca), NULL) != 1) {
      raise_file_error("SSL_CTX_load_verify_locations", RSTRING_PTR(ca));
    }
  }

  ssl_options = SSL_OP_CIPHER_SERVER_PREFERENCE | SSL_OP_SINGLE_ECDH_USE | SSL_OP_NO_COMPRESSION;

#ifdef HAVE_SSL_CTX_SET_MIN_PROTO_VERSION
  if (RTEST(no_tlsv1_1)) {
    min = TLS1_2_VERSION;
  }
  else if (RTEST(no_tlsv1)) {
    min = TLS1_1_VERSION;
  }
  else {
    min = TLS1_VERSION;
  }

  SSL_CTX_set_min_proto_version(ctx, min);

#else
  /* As of 1.0.2f, SSL_OP_SINGLE_DH_USE key use is always on */
  ssl_options |= SSL_OP_NO_SSLv2 | SSL_OP_NO_SSLv3 | SSL_OP_SINGLE_DH_USE;

  if (RTEST(no_tlsv1)) {
    ssl_options |= SSL_OP_NO_TLSv1;
  }
  if(RTEST(no_tlsv1_1)) {
    ssl_options |= SSL_OP_NO_TLSv1 | SSL_OP_NO_TLSv1_1;
  }
#endif

#ifdef HAVE_SSL_CTX_SET_SESSION_CACHE_MODE
  if (!NIL_P(reuse)) {
    SSL_CTX_set_session_cache_mode(ctx, SSL_SESS_CACHE_SERVER);
    if (!NIL_P(reuse_cache_size)) {
      SSL_CTX_sess_set_cache_size(ctx, NUM2INT(reuse_cache_size));
    }
    if (!NIL_P(reuse_timeout)) {
      SSL_CTX_set_timeout(ctx, NUM2INT(reuse_timeout));
    }
  } else {
    SSL_CTX_set_session_cache_mode(ctx, SSL_SESS_CACHE_OFF);
  }
#endif

  SSL_CTX_set_options(ctx, ssl_options);

  if (!NIL_P(ssl_cipher_filter)) {
    StringValue(ssl_cipher_filter);
    SSL_CTX_set_cipher_list(ctx, RSTRING_PTR(ssl_cipher_filter));
  }
  else {
    SSL_CTX_set_cipher_list(ctx, "HIGH:!aNULL@STRENGTH");
  }

#if OPENSSL_VERSION_NUMBER < 0x10002000L
  // Remove this case if OpenSSL 1.0.1 (now EOL) support is no longer needed.
  ecdh = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
  if (ecdh) {
    SSL_CTX_set_tmp_ecdh(ctx, ecdh);
    EC_KEY_free(ecdh);
  }
#elif OPENSSL_VERSION_NUMBER < 0x10100000L || defined(LIBRESSL_VERSION_NUMBER)
  SSL_CTX_set_ecdh_auto(ctx, 1);
#endif

  if (NIL_P(verify_mode)) {
    /* SSL_CTX_set_verify(ctx, SSL_VERIFY_NONE, NULL); */
  } else {
    SSL_CTX_set_verify(ctx, NUM2INT(verify_mode), engine_verify_callback);
  }

  // Random.bytes available in Ruby 2.5 and later, Random::DEFAULT deprecated in 3.0
  session_id_bytes = rb_funcall(
#ifdef HAVE_RANDOM_BYTES
    rb_cRandom,
#else
    rb_const_get(rb_cRandom, rb_intern_const("DEFAULT")),
#endif
    rb_intern_const("bytes"),
    1, ULL2NUM(SSL_MAX_SSL_SESSION_ID_LENGTH));

  SSL_CTX_set_session_id_context(ctx,
                                 (unsigned char *) RSTRING_PTR(session_id_bytes),
                                 SSL_MAX_SSL_SESSION_ID_LENGTH);

  // printf("\ninitialize end security_level %d\n", SSL_CTX_get_security_level(ctx));

#ifdef HAVE_SSL_CTX_SET_DH_AUTO
  // https://www.openssl.org/docs/man3.0/man3/SSL_CTX_set_dh_auto.html
  SSL_CTX_set_dh_auto(ctx, 1);
#else
  dh = get_dh2048();
  SSL_CTX_set_tmp_dh(ctx, dh);
#endif

  rb_obj_freeze(self);
  return self;
}

VALUE engine_init_server(VALUE self, VALUE sslctx) {
  ms_conn* conn;
  VALUE obj;
  SSL_CTX* ctx;
  SSL* ssl;

  conn = engine_alloc(self, &obj);

  TypedData_Get_Struct(sslctx, SSL_CTX, &sslctx_type, ctx);

  ssl = SSL_new(ctx);
  conn->ssl = ssl;
  SSL_set_app_data(ssl, NULL);
  SSL_set_bio(ssl, conn->read, conn->write);
  SSL_set_accept_state(ssl);
  return obj;
}

VALUE engine_init_client(VALUE klass) {
  VALUE obj;
  ms_conn* conn = engine_alloc(klass, &obj);
#ifdef HAVE_DTLS_METHOD
  conn->ctx = SSL_CTX_new(DTLS_method());
#else
  conn->ctx = SSL_CTX_new(DTLSv1_method());
#endif
  conn->ssl = SSL_new(conn->ctx);
  SSL_set_app_data(conn->ssl, NULL);
  SSL_set_verify(conn->ssl, SSL_VERIFY_NONE, NULL);

  SSL_set_bio(conn->ssl, conn->read, conn->write);

  SSL_set_connect_state(conn->ssl);
  return obj;
}

VALUE engine_inject(VALUE self, VALUE str) {
  ms_conn* conn;
  long used;

  TypedData_Get_Struct(self, ms_conn, &engine_data_type, conn);

  StringValue(str);

  used = BIO_write(conn->read, RSTRING_PTR(str), (int)RSTRING_LEN(str));

  if(used == 0 || used == -1) {
    return Qfalse;
  }

  return INT2FIX(used);
}

NORETURN(void raise_error(SSL* ssl, int result));

void raise_error(SSL* ssl, int result) {
  char buf[512];
  char msg[768];
  const char* err_str;
  int err = errno;
  int mask = 4095;
  int ssl_err = SSL_get_error(ssl, result);
  int verify_err = (int) SSL_get_verify_result(ssl);

  if(SSL_ERROR_SYSCALL == ssl_err) {
    snprintf(msg, sizeof(msg), "System error: %s - %d", strerror(err), err);

  } else if(SSL_ERROR_SSL == ssl_err) {
    if(X509_V_OK != verify_err) {
      err_str = X509_verify_cert_error_string(verify_err);
      snprintf(msg, sizeof(msg),
               "OpenSSL certificate verification error: %s - %d",
               err_str, verify_err);

    } else {
      err = (int) ERR_get_error();
      ERR_error_string_n(err, buf, sizeof(buf));
      snprintf(msg, sizeof(msg), "OpenSSL error: %s - %d", buf, err & mask);
    }
  } else {
    snprintf(msg, sizeof(msg), "Unknown OpenSSL error: %d", ssl_err);
  }

  ERR_clear_error();
  rb_raise(eError, "%s", msg);
}

VALUE engine_read(VALUE self) {
  ms_conn* conn;
  char buf[512];
  int bytes, error;

  TypedData_Get_Struct(self, ms_conn, &engine_data_type, conn);

  ERR_clear_error();

  bytes = SSL_read(conn->ssl, (void*)buf, sizeof(buf));

  if(bytes > 0) {
    return rb_str_new(buf, bytes);
  }

  if(SSL_want_read(conn->ssl)) return Qnil;

  error = SSL_get_error(conn->ssl, bytes);

  if(error == SSL_ERROR_ZERO_RETURN) {
    rb_eof_error();
  } else {
    raise_error(conn->ssl, bytes);
  }

  return Qnil;
}

VALUE engine_write(VALUE self, VALUE str) {
  ms_conn* conn;
  int bytes;

  TypedData_Get_Struct(self, ms_conn, &engine_data_type, conn);

  StringValue(str);

  ERR_clear_error();

  bytes = SSL_write(conn->ssl, (void*)RSTRING_PTR(str), (int)RSTRING_LEN(str));
  if(bytes > 0) {
    return INT2FIX(bytes);
  }

  if(SSL_want_write(conn->ssl)) return Qnil;

  raise_error(conn->ssl, bytes);

  return Qnil;
}

VALUE engine_extract(VALUE self) {
  ms_conn* conn;
  int bytes;
  size_t pending;
  // https://www.openssl.org/docs/manmaster/man3/BIO_f_buffer.html
  // crypto/bio/bf_buff.c DEFAULT_BUFFER_SIZE
  char buf[4096];

  TypedData_Get_Struct(self, ms_conn, &engine_data_type, conn);

  pending = BIO_pending(conn->write);
  if(pending > 0) {
    bytes = BIO_read(conn->write, buf, sizeof(buf));
    if(bytes > 0) {
      return rb_str_new(buf, bytes);
    } else if(!BIO_should_retry(conn->write)) {
      raise_error(conn->ssl, bytes);
    }
  }

  return Qnil;
}

VALUE engine_shutdown(VALUE self) {
  ms_conn* conn;
  int ok;

  TypedData_Get_Struct(self, ms_conn, &engine_data_type, conn);

  ERR_clear_error();

  ok = SSL_shutdown(conn->ssl);
  if (ok == 0) {
    return Qfalse;
  }

  return Qtrue;
}

VALUE engine_init(VALUE self) {
  ms_conn* conn;

  TypedData_Get_Struct(self, ms_conn, &engine_data_type, conn);

  return SSL_in_init(conn->ssl) ? Qtrue : Qfalse;
}

VALUE engine_peercert(VALUE self) {
  ms_conn* conn;
  X509* cert;
  int bytes;
  unsigned char* buf = NULL;
  ms_cert_buf* cert_buf = NULL;
  VALUE rb_cert_buf;

  TypedData_Get_Struct(self, ms_conn, &engine_data_type, conn);

#ifdef HAVE_SSL_GET1_PEER_CERTIFICATE
  cert = SSL_get1_peer_certificate(conn->ssl);
#else
  cert = SSL_get_peer_certificate(conn->ssl);
#endif
  if(!cert) {
    /*
     * See if there was a failed certificate associated with this client.
     */
    cert_buf = (ms_cert_buf*)SSL_get_app_data(conn->ssl);
    if(!cert_buf) {
      return Qnil;
    }
    buf = cert_buf->buf;
    bytes = cert_buf->bytes;

  } else {
    bytes = i2d_X509(cert, &buf);
    X509_free(cert);

    if(bytes < 0) {
      return Qnil;
    }
  }

  rb_cert_buf = rb_str_new((const char*)(buf), bytes);
  if(!cert_buf) {
    OPENSSL_free(buf);
  }

  return rb_cert_buf;
}

/* @see Puma::MiniSSL::Socket#ssl_version_state
 * @version 5.0.0
 */
static VALUE
engine_ssl_vers_st(VALUE self) {
  ms_conn* conn;
  TypedData_Get_Struct(self, ms_conn, &engine_data_type, conn);
  return rb_ary_new3(2, rb_str_new2(SSL_get_version(conn->ssl)), rb_str_new2(SSL_state_string(conn->ssl)));
}

VALUE noop(VALUE self) {
  return Qnil;
}

void Init_mini_ssl(VALUE puma) {
  VALUE mod, eng, sslctx;

/* Fake operation for documentation (RDoc, YARD) */
#if 0 == 1
  puma = rb_define_module("Puma");
#endif

  SSL_library_init();
  OpenSSL_add_ssl_algorithms();
  SSL_load_error_strings();
  ERR_load_crypto_strings();

  mod = rb_define_module_under(puma, "MiniSSL");

  eng = rb_define_class_under(mod, "Engine", rb_cObject);
  rb_undef_alloc_func(eng);

  sslctx = rb_define_class_under(mod, "SSLContext", rb_cObject);
  rb_define_alloc_func(sslctx, sslctx_alloc);
  rb_define_method(sslctx, "initialize", sslctx_initialize, 1);
  rb_undef_method(sslctx, "initialize_copy");


  // OpenSSL Build / Runtime/Load versions

  /* Version of OpenSSL that Puma was compiled with */
  rb_define_const(mod, "OPENSSL_VERSION", rb_str_new2(OPENSSL_VERSION_TEXT));

#if !defined(LIBRESSL_VERSION_NUMBER) && OPENSSL_VERSION_NUMBER >= 0x10100000
  /* Version of OpenSSL that Puma loaded with */
  rb_define_const(mod, "OPENSSL_LIBRARY_VERSION", rb_str_new2(OpenSSL_version(OPENSSL_VERSION)));
#else
  rb_define_const(mod, "OPENSSL_LIBRARY_VERSION", rb_str_new2(SSLeay_version(SSLEAY_VERSION)));
#endif

#if defined(OPENSSL_NO_SSL3) || defined(OPENSSL_NO_SSL3_METHOD)
  /* True if SSL3 is not available */
  rb_define_const(mod, "OPENSSL_NO_SSL3", Qtrue);
#else
  rb_define_const(mod, "OPENSSL_NO_SSL3", Qfalse);
#endif

#if defined(OPENSSL_NO_TLS1) || defined(OPENSSL_NO_TLS1_METHOD)
  /* True if TLS1 is not available */
  rb_define_const(mod, "OPENSSL_NO_TLS1", Qtrue);
#else
  rb_define_const(mod, "OPENSSL_NO_TLS1", Qfalse);
#endif

#if defined(OPENSSL_NO_TLS1_1) || defined(OPENSSL_NO_TLS1_1_METHOD)
  /* True if TLS1_1 is not available */
  rb_define_const(mod, "OPENSSL_NO_TLS1_1", Qtrue);
#else
  rb_define_const(mod, "OPENSSL_NO_TLS1_1", Qfalse);
#endif

  rb_define_singleton_method(mod, "check", noop, 0);

  eError = rb_define_class_under(mod, "SSLError", rb_eStandardError);

  rb_define_singleton_method(eng, "server", engine_init_server, 1);
  rb_define_singleton_method(eng, "client", engine_init_client, 0);

  rb_define_method(eng, "inject", engine_inject, 1);
  rb_define_method(eng, "read",  engine_read, 0);

  rb_define_method(eng, "write",  engine_write, 1);
  rb_define_method(eng, "extract", engine_extract, 0);

  rb_define_method(eng, "shutdown", engine_shutdown, 0);

  rb_define_method(eng, "init?", engine_init, 0);

  /* @!attribute [r] peercert
   * Returns `nil` when `MiniSSL::Context#verify_mode` is set to `VERIFY_NONE`.
   * @return [String, nil] DER encoded cert
   */
  rb_define_method(eng, "peercert", engine_peercert, 0);

  rb_define_method(eng, "ssl_vers_st", engine_ssl_vers_st, 0);
}

#else

NORETURN(VALUE raise_error(VALUE self));

VALUE raise_error(VALUE self) {
  rb_raise(rb_eStandardError, "SSL not available in this build");
}

void Init_mini_ssl(VALUE puma) {
  VALUE mod;

  mod = rb_define_module_under(puma, "MiniSSL");
  rb_define_class_under(mod, "SSLError", rb_eStandardError);

  rb_define_singleton_method(mod, "check", raise_error, 0);
}
#endif
