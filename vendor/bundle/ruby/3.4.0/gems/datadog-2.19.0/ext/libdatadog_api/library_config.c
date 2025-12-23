#include <ruby.h>
#include <datadog/library-config.h>

#include "library_config.h"
#include "datadog_ruby_common.h"

static VALUE _native_configurator_new(VALUE klass);
static VALUE _native_configurator_get(VALUE self);

// Used for testing in RSpec
static VALUE _native_configurator_with_local_path(DDTRACE_UNUSED VALUE _self, VALUE rb_configurator, VALUE path);
static VALUE _native_configurator_with_fleet_path(DDTRACE_UNUSED VALUE _self, VALUE rb_configurator, VALUE path);

static VALUE config_vec_class = Qnil;

// ddog_Configurator memory management
static void configurator_free(void *configurator_ptr) {
  ddog_Configurator *configurator = (ddog_Configurator *)configurator_ptr;

  ddog_library_configurator_drop(configurator);
}

static const rb_data_type_t configurator_typed_data = {
  .wrap_struct_name = "Datadog::Core::Configuration::StableConfig::Configurator",
  .function = {
    .dfree = configurator_free,
    .dsize = NULL,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

// ddog_Vec_LibraryConfig memory management
static void config_vec_free(void *config_vec_ptr) {
  ddog_Vec_LibraryConfig *config_vec = (ddog_Vec_LibraryConfig *)config_vec_ptr;

  ddog_library_config_drop(*config_vec);
  ruby_xfree(config_vec_ptr);
}

static const rb_data_type_t config_vec_typed_data = {
  .wrap_struct_name = "Datadog::Core::Configuration::StableConfigVec",
  .function = {
    .dfree = config_vec_free,
    .dsize = NULL,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

void library_config_init(VALUE core_module) {
  rb_global_variable(&config_vec_class);
  VALUE configuration_module = rb_define_module_under(core_module, "Configuration");
  VALUE stable_config_module = rb_define_module_under(configuration_module, "StableConfig");
  VALUE configurator_class = rb_define_class_under(stable_config_module, "Configurator", rb_cObject);
  config_vec_class = rb_define_class_under(configuration_module, "StableConfigVec", rb_cObject);

  rb_define_alloc_func(configurator_class, _native_configurator_new);
  rb_define_method(configurator_class, "get", _native_configurator_get, 0);

  // Used for testing in RSpec
  VALUE testing_module = rb_define_module_under(stable_config_module, "Testing");
  rb_define_singleton_method(testing_module, "with_local_path", _native_configurator_with_local_path, 2);
  rb_define_singleton_method(testing_module, "with_fleet_path", _native_configurator_with_fleet_path, 2);

  rb_undef_alloc_func(config_vec_class); // It cannot be created from Ruby code and only serves as an intermediate object for the Ruby GC
}

static VALUE _native_configurator_new(VALUE klass) {
  ddog_Configurator *configurator = ddog_library_configurator_new(false, DDOG_CHARSLICE_C("ruby"));

  ddog_library_configurator_with_detect_process_info(configurator);

  return TypedData_Wrap_Struct(klass, &configurator_typed_data, configurator);
}

static VALUE _native_configurator_with_local_path(DDTRACE_UNUSED VALUE _self, VALUE rb_configurator, VALUE path) {
  ddog_Configurator *configurator;
  TypedData_Get_Struct(rb_configurator, ddog_Configurator, &configurator_typed_data, configurator);

  ENFORCE_TYPE(path, T_STRING);

  ddog_library_configurator_with_local_path(configurator, cstr_from_ruby_string(path));

  return Qnil;
}

static VALUE _native_configurator_with_fleet_path(DDTRACE_UNUSED VALUE _self, VALUE rb_configurator, VALUE path) {
  ddog_Configurator *configurator;
  TypedData_Get_Struct(rb_configurator, ddog_Configurator, &configurator_typed_data, configurator);

  ENFORCE_TYPE(path, T_STRING);

  ddog_library_configurator_with_fleet_path(configurator, cstr_from_ruby_string(path));

  return Qnil;
}

static VALUE _native_configurator_get(VALUE self) {
  ddog_Configurator *configurator;
  TypedData_Get_Struct(self, ddog_Configurator, &configurator_typed_data, configurator);

  ddog_Result_VecLibraryConfig configurator_result = ddog_library_configurator_get(configurator);

  if (configurator_result.tag == DDOG_RESULT_VEC_LIBRARY_CONFIG_ERR_VEC_LIBRARY_CONFIG) {
    ddog_Error err = configurator_result.err;
    VALUE message = get_error_details_and_drop(&err);
    if (is_config_loaded()) {
      log_warning(message);
    } else {
      log_warning_without_config(message);
    }
    return rb_hash_new();
  }

  // Wrapping config_vec into a Ruby object enables the Ruby GC to manage its memory
  // We need to allocate memory for config_vec because once it is out of scope, it will be freed (at the end of this function)
  // So we cannot reference it with &config_vec
  // We are doing this in case one of the ruby API raises an exception before the end of this function,
  // so the allocated memory will still be freed
  ddog_Vec_LibraryConfig *config_vec = ruby_xmalloc(sizeof(ddog_Vec_LibraryConfig));
  *config_vec = configurator_result.ok;
  VALUE config_vec_rb = TypedData_Wrap_Struct(config_vec_class, &config_vec_typed_data, config_vec);

  VALUE local_config_hash = rb_hash_new();
  VALUE fleet_config_hash = rb_hash_new();

  bool local_config_id_set = false;
  bool fleet_config_id_set = false;
  VALUE local_hash = rb_hash_new();
  VALUE fleet_hash = rb_hash_new();
  for (uintptr_t i = 0; i < config_vec->len; i++) {
    ddog_LibraryConfig config = config_vec->ptr[i];
    VALUE selected_hash;
    if (config.source == DDOG_LIBRARY_CONFIG_SOURCE_LOCAL_STABLE_CONFIG) {
      selected_hash = local_config_hash;
      if (!local_config_id_set) {
        local_config_id_set = true;
        if (config.config_id.length > 0) {
          rb_hash_aset(local_hash, ID2SYM(rb_intern("id")), rb_utf8_str_new_cstr(config.config_id.ptr));
        }
      }
    }
    else {
      selected_hash = fleet_config_hash;
      if (!fleet_config_id_set) {
        fleet_config_id_set = true;
        if (config.config_id.length > 0) {
          rb_hash_aset(fleet_hash, ID2SYM(rb_intern("id")), rb_utf8_str_new_cstr(config.config_id.ptr));
        }
      }
    }

    rb_hash_aset(selected_hash, rb_utf8_str_new_cstr(config.name.ptr), rb_utf8_str_new_cstr(config.value.ptr));
  }

  rb_hash_aset(local_hash, ID2SYM(rb_intern("config")), local_config_hash);
  rb_hash_aset(fleet_hash, ID2SYM(rb_intern("config")), fleet_config_hash);

  VALUE result = rb_hash_new();
  rb_hash_aset(result, ID2SYM(rb_intern("local")), local_hash);
  rb_hash_aset(result, ID2SYM(rb_intern("fleet")), fleet_hash);

  RB_GC_GUARD(config_vec_rb);
  return result;
}
