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

static VALUE cConfig, eConfigError;

static void
nconf_free(void *conf)
{
    NCONF_free(conf);
}

static const rb_data_type_t ossl_config_type = {
    "OpenSSL/CONF",
    {
        0, nconf_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

CONF *
GetConfig(VALUE obj)
{
    CONF *conf;

    TypedData_Get_Struct(obj, CONF, &ossl_config_type, conf);
    if (!conf)
        rb_raise(rb_eRuntimeError, "CONF is not initialized");
    return conf;
}

static VALUE
config_s_alloc(VALUE klass)
{
    VALUE obj;
    CONF *conf;

    obj = TypedData_Wrap_Struct(klass, &ossl_config_type, 0);
    conf = NCONF_new(NULL);
    if (!conf)
        ossl_raise(eConfigError, "NCONF_new");
    RTYPEDDATA_DATA(obj) = conf;
    return obj;
}

static void
config_load_bio(CONF *conf, BIO *bio)
{
    long eline = -1;

    if (!NCONF_load_bio(conf, bio, &eline)) {
        BIO_free(bio);
        if (eline <= 0)
            ossl_raise(eConfigError, "wrong config format");
        else
            ossl_raise(eConfigError, "error in line %ld", eline);
    }
    BIO_free(bio);

    /*
     * Clear the error queue even if it is parsed successfully.
     * Particularly, when the .include directive refers to a non-existent file,
     * it is only reported in the error queue.
     */
    ossl_clear_error();
}

/*
 * call-seq:
 *    Config.parse(string) -> OpenSSL::Config
 *
 * Parses a given _string_ as a blob that contains configuration for OpenSSL.
 */
static VALUE
config_s_parse(VALUE klass, VALUE str)
{
    VALUE obj = config_s_alloc(klass);
    CONF *conf = GetConfig(obj);
    BIO *bio;

    bio = ossl_obj2bio(&str);
    config_load_bio(conf, bio); /* Consumes BIO */
    return obj;
}

static VALUE config_get_sections(VALUE self);
static VALUE config_get_section(VALUE self, VALUE section);

/*
 * call-seq:
 *    Config.parse_config(io) -> hash
 *
 * Parses the configuration data read from _io_ and returns the whole content
 * as a Hash.
 */
static VALUE
config_s_parse_config(VALUE klass, VALUE io)
{
    VALUE obj, sections, ret;
    long i;

    obj = config_s_parse(klass, io);
    sections = config_get_sections(obj);
    ret = rb_hash_new();
    for (i = 0; i < RARRAY_LEN(sections); i++) {
        VALUE section = rb_ary_entry(sections, i);
        rb_hash_aset(ret, section, config_get_section(obj, section));
    }
    return ret;
}

/*
 * call-seq:
 *    Config.new(filename) -> OpenSSL::Config
 *
 * Creates an instance of OpenSSL::Config from the content of the file
 * specified by _filename_.
 *
 * This can be used in contexts like OpenSSL::X509::ExtensionFactory.config=
 *
 * This can raise IO exceptions based on the access, or availability of the
 * file. A ConfigError exception may be raised depending on the validity of
 * the data being configured.
 */
static VALUE
config_initialize(int argc, VALUE *argv, VALUE self)
{
    CONF *conf = GetConfig(self);
    VALUE filename;

    /* 0-arguments call has no use-case, but is kept for compatibility */
    rb_scan_args(argc, argv, "01", &filename);
    rb_check_frozen(self);
    if (!NIL_P(filename)) {
        BIO *bio = BIO_new_file(StringValueCStr(filename), "rb");
        if (!bio)
            ossl_raise(eConfigError, "BIO_new_file");
        config_load_bio(conf, bio); /* Consumes BIO */
    }
    return self;
}

static VALUE
config_initialize_copy(VALUE self, VALUE other)
{
    CONF *conf = GetConfig(self);
    VALUE str;
    BIO *bio;

    str = rb_funcall(other, rb_intern("to_s"), 0);
    rb_check_frozen(self);
    bio = ossl_obj2bio(&str);
    config_load_bio(conf, bio); /* Consumes BIO */
    return self;
}

/*
 * call-seq:
 *    config.get_value(section, key) -> string
 *
 * Gets the value of _key_ from the given _section_.
 *
 * Given the following configurating file being loaded:
 *
 *   config = OpenSSL::Config.load('foo.cnf')
 *     #=> #<OpenSSL::Config sections=["default"]>
 *   puts config.to_s
 *     #=> [ default ]
 *     #   foo=bar
 *
 * You can get a specific value from the config if you know the _section_
 * and _key_ like so:
 *
 *   config.get_value('default','foo')
 *     #=> "bar"
 */
static VALUE
config_get_value(VALUE self, VALUE section, VALUE key)
{
    CONF *conf = GetConfig(self);
    const char *str, *sectionp;

    StringValueCStr(section);
    StringValueCStr(key);
    /* For compatibility; NULL means "default". */
    sectionp = RSTRING_LEN(section) ? RSTRING_PTR(section) : NULL;
    str = NCONF_get_string(conf, sectionp, RSTRING_PTR(key));
    if (!str) {
        ossl_clear_error();
        return Qnil;
    }
    return rb_str_new_cstr(str);
}

/*
 * call-seq:
 *    config[section] -> hash
 *
 * Gets all key-value pairs in a specific _section_ from the current
 * configuration.
 *
 * Given the following configurating file being loaded:
 *
 *   config = OpenSSL::Config.load('foo.cnf')
 *     #=> #<OpenSSL::Config sections=["default"]>
 *   puts config.to_s
 *     #=> [ default ]
 *     #   foo=bar
 *
 * You can get a hash of the specific section like so:
 *
 *   config['default']
 *     #=> {"foo"=>"bar"}
 *
 */
static VALUE
config_get_section(VALUE self, VALUE section)
{
    CONF *conf = GetConfig(self);
    STACK_OF(CONF_VALUE) *sk;
    int i, entries;
    VALUE hash;

    hash = rb_hash_new();
    StringValueCStr(section);
    if (!(sk = NCONF_get_section(conf, RSTRING_PTR(section)))) {
        ossl_clear_error();
        return hash;
    }
    entries = sk_CONF_VALUE_num(sk);
    for (i = 0; i < entries; i++) {
        CONF_VALUE *entry = sk_CONF_VALUE_value(sk, i);
        rb_hash_aset(hash, rb_str_new_cstr(entry->name),
                     rb_str_new_cstr(entry->value));
    }
    return hash;
}

static void
get_conf_section_doall_arg(CONF_VALUE *cv, VALUE *aryp)
{
    if (cv->name)
        return;
    rb_ary_push(*aryp, rb_str_new_cstr(cv->section));
}

/* IMPLEMENT_LHASH_DOALL_ARG_CONST() requires >= OpenSSL 1.1.0 */
static IMPLEMENT_LHASH_DOALL_ARG_FN(get_conf_section, CONF_VALUE, VALUE)

/*
 * call-seq:
 *    config.sections -> array of string
 *
 * Get the names of all sections in the current configuration.
 */
static VALUE
config_get_sections(VALUE self)
{
    CONF *conf = GetConfig(self);
    VALUE ary;

    ary = rb_ary_new();
    lh_doall_arg((_LHASH *)conf->data, LHASH_DOALL_ARG_FN(get_conf_section),
                 &ary);
    return ary;
}

static void
dump_conf_value_doall_arg(CONF_VALUE *cv, VALUE *strp)
{
    VALUE str = *strp;
    STACK_OF(CONF_VALUE) *sk;
    int i, num;

    if (cv->name)
        return;
    sk = (STACK_OF(CONF_VALUE) *)cv->value;
    num = sk_CONF_VALUE_num(sk);
    rb_str_cat_cstr(str, "[ ");
    rb_str_cat_cstr(str, cv->section);
    rb_str_cat_cstr(str, " ]\n");
    for (i = 0; i < num; i++){
        CONF_VALUE *v = sk_CONF_VALUE_value(sk, i);
        rb_str_cat_cstr(str, v->name ? v->name : "None");
        rb_str_cat_cstr(str, "=");
        rb_str_cat_cstr(str, v->value ? v->value : "None");
        rb_str_cat_cstr(str, "\n");
    }
    rb_str_cat_cstr(str, "\n");
}

static IMPLEMENT_LHASH_DOALL_ARG_FN(dump_conf_value, CONF_VALUE, VALUE)

/*
 * call-seq:
 *    config.to_s -> string
 *
 *
 * Gets the parsable form of the current configuration.
 *
 * Given the following configuration being created:
 *
 *   config = OpenSSL::Config.new
 *     #=> #<OpenSSL::Config sections=[]>
 *   config['default'] = {"foo"=>"bar","baz"=>"buz"}
 *     #=> {"foo"=>"bar", "baz"=>"buz"}
 *   puts config.to_s
 *     #=> [ default ]
 *     #   foo=bar
 *     #   baz=buz
 *
 * You can parse get the serialized configuration using #to_s and then parse
 * it later:
 *
 *   serialized_config = config.to_s
 *   # much later...
 *   new_config = OpenSSL::Config.parse(serialized_config)
 *     #=> #<OpenSSL::Config sections=["default"]>
 *   puts new_config
 *     #=> [ default ]
 *         foo=bar
 *         baz=buz
 */
static VALUE
config_to_s(VALUE self)
{
    CONF *conf = GetConfig(self);
    VALUE str;

    str = rb_str_new(NULL, 0);
    lh_doall_arg((_LHASH *)conf->data, LHASH_DOALL_ARG_FN(dump_conf_value),
                 &str);
    return str;
}

static void
each_conf_value_doall_arg(CONF_VALUE *cv, void *unused)
{
    STACK_OF(CONF_VALUE) *sk;
    VALUE section;
    int i, num;

    if (cv->name)
        return;
    sk = (STACK_OF(CONF_VALUE) *)cv->value;
    num = sk_CONF_VALUE_num(sk);
    section = rb_str_new_cstr(cv->section);
    for (i = 0; i < num; i++){
        CONF_VALUE *v = sk_CONF_VALUE_value(sk, i);
        VALUE name = v->name ? rb_str_new_cstr(v->name) : Qnil;
        VALUE value = v->value ? rb_str_new_cstr(v->value) : Qnil;
        rb_yield(rb_ary_new3(3, section, name, value));
    }
}

static IMPLEMENT_LHASH_DOALL_ARG_FN(each_conf_value, CONF_VALUE, void)

/*
 * call-seq:
 *    config.each { |section, key, value| }
 *
 * Retrieves the section and its pairs for the current configuration.
 *
 *    config.each do |section, key, value|
 *      # ...
 *    end
 */
static VALUE
config_each(VALUE self)
{
    CONF *conf = GetConfig(self);

    RETURN_ENUMERATOR(self, 0, 0);

    lh_doall_arg((_LHASH *)conf->data, LHASH_DOALL_ARG_FN(each_conf_value),
                 NULL);
    return self;
}

/*
 * call-seq:
 *    config.inspect -> string
 *
 * String representation of this configuration object, including the class
 * name and its sections.
 */
static VALUE
config_inspect(VALUE self)
{
    VALUE str, ary = config_get_sections(self);
    const char *cname = rb_class2name(rb_obj_class(self));

    str = rb_str_new_cstr("#<");
    rb_str_cat_cstr(str, cname);
    rb_str_cat_cstr(str, " sections=");
    rb_str_append(str, rb_inspect(ary));
    rb_str_cat_cstr(str, ">");

    return str;
}

void
Init_ossl_config(void)
{
    char *path;
    VALUE path_str;

#if 0
    mOSSL = rb_define_module("OpenSSL");
    eOSSLError = rb_define_class_under(mOSSL, "OpenSSLError", rb_eStandardError);
#endif

    /* Document-class: OpenSSL::Config
     *
     * Configuration for the openssl library.
     *
     * Many system's installation of openssl library will depend on your system
     * configuration. See the value of OpenSSL::Config::DEFAULT_CONFIG_FILE for
     * the location of the file for your host.
     *
     * See also http://www.openssl.org/docs/apps/config.html
     */
    cConfig = rb_define_class_under(mOSSL, "Config", rb_cObject);

    /* Document-class: OpenSSL::ConfigError
     *
     * General error for openssl library configuration files. Including formatting,
     * parsing errors, etc.
     */
    eConfigError = rb_define_class_under(mOSSL, "ConfigError", eOSSLError);

    rb_include_module(cConfig, rb_mEnumerable);
    rb_define_singleton_method(cConfig, "parse", config_s_parse, 1);
    rb_define_singleton_method(cConfig, "parse_config", config_s_parse_config, 1);
    rb_define_alias(CLASS_OF(cConfig), "load", "new");
    rb_define_alloc_func(cConfig, config_s_alloc);
    rb_define_method(cConfig, "initialize", config_initialize, -1);
    rb_define_method(cConfig, "initialize_copy", config_initialize_copy, 1);
    rb_define_method(cConfig, "get_value", config_get_value, 2);
    rb_define_method(cConfig, "[]", config_get_section, 1);
    rb_define_method(cConfig, "sections", config_get_sections, 0);
    rb_define_method(cConfig, "to_s", config_to_s, 0);
    rb_define_method(cConfig, "each", config_each, 0);
    rb_define_method(cConfig, "inspect", config_inspect, 0);

    /* Document-const: DEFAULT_CONFIG_FILE
     *
     * The default system configuration file for OpenSSL.
     */
    path = CONF_get1_default_config_file();
    path_str = ossl_buf2str(path, rb_long2int(strlen(path)));
    rb_define_const(cConfig, "DEFAULT_CONFIG_FILE", path_str);
}
