#include <ruby.h>
#include <ow-crypt.h>

#ifdef HAVE_RUBY_THREAD_H
#include <ruby/thread.h>
#endif

static VALUE mBCrypt;
static VALUE cBCryptEngine;

struct bc_salt_args {
    const char * prefix;
    unsigned long count;
    const char * input;
    int size;
};

static void * bc_salt_nogvl(void * ptr) {
    struct bc_salt_args * args = ptr;

    return crypt_gensalt_ra(args->prefix, args->count, args->input, args->size);
}

/* Given a logarithmic cost parameter, generates a salt for use with +bc_crypt+.
*/
static VALUE bc_salt(VALUE self, VALUE prefix, VALUE count, VALUE input) {
    char * salt;
    VALUE str_salt;
    struct bc_salt_args args;

    /* duplicate the parameters for thread safety.  If another thread has a
     * reference to the parameters and mutates them while we are working,
     * that would be very bad.  Duping the strings means that the reference
     * isn't shared. */
    prefix = rb_str_new_frozen(prefix);
    input  = rb_str_new_frozen(input);

    args.prefix = StringValueCStr(prefix);
    args.count  = NUM2ULONG(count);
    args.input  = NIL_P(input) ? NULL : StringValuePtr(input);
    args.size   = NIL_P(input) ? 0 : RSTRING_LEN(input);

#ifdef HAVE_RUBY_THREAD_H
    salt = rb_thread_call_without_gvl(bc_salt_nogvl, &args, NULL, NULL);
#else
    salt = bc_salt_nogvl((void *)&args);
#endif

    if(!salt) return Qnil;

    str_salt = rb_str_new2(salt);

    RB_GC_GUARD(prefix);
    RB_GC_GUARD(input);
    free(salt);

    return str_salt;
}

struct bc_crypt_args {
    const char * key;
    const char * setting;
    void * data;
    int size;
};

static void * bc_crypt_nogvl(void * ptr) {
    struct bc_crypt_args * args = ptr;

    return crypt_ra(args->key, args->setting, &args->data, &args->size);
}

/* Given a secret and a salt, generates a salted hash (which you can then store safely).
*/
static VALUE bc_crypt(VALUE self, VALUE key, VALUE setting) {
    char * value;
    VALUE out;

    struct bc_crypt_args args;

    if(NIL_P(key) || NIL_P(setting)) return Qnil;

    /* duplicate the parameters for thread safety.  If another thread has a
     * reference to the parameters and mutates them while we are working,
     * that would be very bad.  Duping the strings means that the reference
     * isn't shared. */
    key     = rb_str_new_frozen(key);
    setting = rb_str_new_frozen(setting);

    args.data    = NULL;
    args.size    = 0xDEADBEEF;
    args.key     = NIL_P(key)     ? NULL : StringValueCStr(key);
    args.setting = NIL_P(setting) ? NULL : StringValueCStr(setting);

#ifdef HAVE_RUBY_THREAD_H
    value = rb_thread_call_without_gvl(bc_crypt_nogvl, &args, NULL, NULL);
#else
    value = bc_crypt_nogvl((void *)&args);
#endif

    if(!value || !args.data) return Qnil;

    out = rb_str_new2(value);

    RB_GC_GUARD(key);
    RB_GC_GUARD(setting);
    free(args.data);

    return out;
}

/* Create the BCrypt and BCrypt::Engine modules, and populate them with methods. */
void Init_bcrypt_ext(){
    mBCrypt = rb_define_module("BCrypt");
    cBCryptEngine = rb_define_class_under(mBCrypt, "Engine", rb_cObject);

    rb_define_singleton_method(cBCryptEngine, "__bc_salt", bc_salt, 3);
    rb_define_singleton_method(cBCryptEngine, "__bc_crypt", bc_crypt, 2);
}

/* vim: set noet sws=4 sw=4: */
