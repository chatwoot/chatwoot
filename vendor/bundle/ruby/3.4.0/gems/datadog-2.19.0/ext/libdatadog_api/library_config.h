#pragma once

#include "datadog_ruby_common.h"

void library_config_init(VALUE core_module);

static inline bool is_config_loaded(void) {
  VALUE datadog_module = rb_const_get(rb_cObject, rb_intern("Datadog"));
  VALUE is_config_loaded = rb_funcall(datadog_module, rb_intern("configuration?"), 0);

  return is_config_loaded == Qtrue;
}

static inline VALUE log_warning_without_config(VALUE warning) {
  VALUE datadog_module = rb_const_get(rb_cObject, rb_intern("Datadog"));
  VALUE logger = rb_funcall(datadog_module, rb_intern("logger_without_configuration"), 0);

  return rb_funcall(logger, rb_intern("warn"), 1, warning);
}

static inline ddog_CStr cstr_from_ruby_string(VALUE string) {
  ENFORCE_TYPE(string, T_STRING);
  ddog_CStr cstr = {.ptr = RSTRING_PTR(string), .length = RSTRING_LEN(string)};
  return cstr;
}
