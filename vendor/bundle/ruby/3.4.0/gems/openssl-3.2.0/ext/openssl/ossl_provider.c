/*
 * This program is licensed under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#include "ossl.h"

#ifdef OSSL_USE_PROVIDER
# include <openssl/provider.h>

#define NewProvider(klass) \
    TypedData_Wrap_Struct((klass), &ossl_provider_type, 0)
#define SetProvider(obj, provider) do { \
    if (!(provider)) { \
        ossl_raise(rb_eRuntimeError, "Provider wasn't initialized."); \
    } \
    RTYPEDDATA_DATA(obj) = (provider); \
} while(0)
#define GetProvider(obj, provider) do { \
    TypedData_Get_Struct((obj), OSSL_PROVIDER, &ossl_provider_type, (provider)); \
    if (!(provider)) { \
        ossl_raise(rb_eRuntimeError, "PROVIDER wasn't initialized."); \
    } \
} while (0)

static const rb_data_type_t ossl_provider_type = {
    "OpenSSL/Provider",
    {
        0,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

/*
 * Classes
 */
/* Document-class: OpenSSL::Provider
 *
 * This class is the access to openssl's Provider
 * See also, https://www.openssl.org/docs/manmaster/man7/provider.html
 */
static VALUE cProvider;
/* Document-class: OpenSSL::Provider::ProviderError
 *
 * This is the generic exception for OpenSSL::Provider related errors
 */
static VALUE eProviderError;

/*
 * call-seq:
 *    OpenSSL::Provider.load(name) -> provider
 *
 * This method loads and initializes a provider
 */
static VALUE
ossl_provider_s_load(VALUE klass, VALUE name)
{
    OSSL_PROVIDER *provider = NULL;
    VALUE obj;

    const char *provider_name_ptr = StringValueCStr(name);

    provider = OSSL_PROVIDER_load(NULL, provider_name_ptr);
    if (provider == NULL) {
        ossl_raise(eProviderError, "Failed to load %s provider", provider_name_ptr);
    }
    obj = NewProvider(klass);
    SetProvider(obj, provider);

    return obj;
}

struct ary_with_state { VALUE ary; int state; };
struct rb_push_provider_name_args { OSSL_PROVIDER *prov; VALUE ary; };

static VALUE
rb_push_provider_name(VALUE rb_push_provider_name_args)
{
    struct rb_push_provider_name_args *args = (struct rb_push_provider_name_args *)rb_push_provider_name_args;

    VALUE name = rb_str_new2(OSSL_PROVIDER_get0_name(args->prov));
    return rb_ary_push(args->ary, name);
}

static int
push_provider(OSSL_PROVIDER *prov, void *cbdata)
{
    struct ary_with_state *ary_with_state = (struct ary_with_state *)cbdata;
    struct rb_push_provider_name_args args = { prov, ary_with_state->ary };

    rb_protect(rb_push_provider_name, (VALUE)&args, &ary_with_state->state);
    if (ary_with_state->state) {
        return 0;
    } else {
        return 1;
    }
}

/*
 * call-seq:
 *    OpenSSL::Provider.provider_names -> [provider_name, ...]
 *
 * Returns an array of currently loaded provider names.
 */
static VALUE
ossl_provider_s_provider_names(VALUE klass)
{
    VALUE ary = rb_ary_new();
    struct ary_with_state cbdata = { ary, 0 };

    int result = OSSL_PROVIDER_do_all(NULL, &push_provider, (void*)&cbdata);
    if (result != 1 ) {
        if (cbdata.state) {
            rb_jump_tag(cbdata.state);
        } else {
            ossl_raise(eProviderError, "Failed to load provider names");
        }
    }

    return ary;
}

/*
 * call-seq:
 *    provider.unload -> true
 *
 * This method unloads this provider.
 *
 * if provider unload fails or already unloaded, it raises OpenSSL::Provider::ProviderError
 */
static VALUE
ossl_provider_unload(VALUE self)
{
    OSSL_PROVIDER *prov;
    if (RTYPEDDATA_DATA(self) == NULL) {
        ossl_raise(eProviderError, "Provider already unloaded.");
    }
    GetProvider(self, prov);

    int result = OSSL_PROVIDER_unload(prov);

    if (result != 1) {
        ossl_raise(eProviderError, "Failed to unload provider");
    }
    RTYPEDDATA_DATA(self) = NULL;
    return Qtrue;
}

/*
 * call-seq:
 *    provider.name -> string
 *
 * Get the name of this provider.
 *
 * if this provider is already unloaded, it raises OpenSSL::Provider::ProviderError
 */
static VALUE
ossl_provider_get_name(VALUE self)
{
    OSSL_PROVIDER *prov;
    if (RTYPEDDATA_DATA(self) == NULL) {
        ossl_raise(eProviderError, "Provider already unloaded.");
    }
    GetProvider(self, prov);

    return rb_str_new2(OSSL_PROVIDER_get0_name(prov));
}

/*
 * call-seq:
 *    provider.inspect -> string
 *
 * Pretty prints this provider.
 */
static VALUE
ossl_provider_inspect(VALUE self)
{
    OSSL_PROVIDER *prov;
    if (RTYPEDDATA_DATA(self) == NULL ) {
        return rb_sprintf("#<%"PRIsVALUE" unloaded provider>", rb_obj_class(self));
    }
    GetProvider(self, prov);

    return rb_sprintf("#<%"PRIsVALUE" name=\"%s\">",
                      rb_obj_class(self), OSSL_PROVIDER_get0_name(prov));
}

void
Init_ossl_provider(void)
{
#if 0
    mOSSL = rb_define_module("OpenSSL");
    eOSSLError = rb_define_class_under(mOSSL, "OpenSSLError", rb_eStandardError);
#endif

    cProvider = rb_define_class_under(mOSSL, "Provider", rb_cObject);
    eProviderError = rb_define_class_under(cProvider, "ProviderError", eOSSLError);

    rb_undef_alloc_func(cProvider);
    rb_define_singleton_method(cProvider, "load", ossl_provider_s_load, 1);
    rb_define_singleton_method(cProvider, "provider_names", ossl_provider_s_provider_names, 0);

    rb_define_method(cProvider, "unload", ossl_provider_unload, 0);
    rb_define_method(cProvider, "name", ossl_provider_get_name, 0);
    rb_define_method(cProvider, "inspect", ossl_provider_inspect, 0);
}
#else
void
Init_ossl_provider(void)
{
}
#endif
