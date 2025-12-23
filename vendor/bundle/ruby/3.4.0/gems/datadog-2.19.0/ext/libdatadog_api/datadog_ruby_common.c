#include "datadog_ruby_common.h"

// IMPORTANT: Currently this file is copy-pasted between extensions. Make sure to update all versions when doing any change!

void raise_unexpected_type(VALUE value, const char *value_name, const char *type_name, const char *file, int line, const char* function_name) {
  rb_exc_raise(
    rb_exc_new_str(
      rb_eTypeError,
      rb_sprintf("wrong argument %"PRIsVALUE" for '%s' (expected a %s) at %s:%d:in `%s'",
        rb_inspect(value),
        value_name,
        type_name,
        file,
        line,
        function_name
      )
    )
  );
}

VALUE datadog_gem_version(void) {
  VALUE ddtrace_module = rb_const_get(rb_cObject, rb_intern("Datadog"));
  ENFORCE_TYPE(ddtrace_module, T_MODULE);
  VALUE version_module = rb_const_get(ddtrace_module, rb_intern("VERSION"));
  ENFORCE_TYPE(version_module, T_MODULE);
  VALUE version_string = rb_const_get(version_module, rb_intern("STRING"));
  ENFORCE_TYPE(version_string, T_STRING);
  return version_string;
}

static VALUE log_failure_to_process_tag(VALUE err_details) {
  return log_warning(rb_sprintf("Failed to convert tag: %"PRIsVALUE, err_details));
}

__attribute__((warn_unused_result))
ddog_Vec_Tag convert_tags(VALUE tags_as_array) {
  ENFORCE_TYPE(tags_as_array, T_ARRAY);

  long tags_count = RARRAY_LEN(tags_as_array);
  ddog_Vec_Tag tags = ddog_Vec_Tag_new();

  for (long i = 0; i < tags_count; i++) {
    VALUE name_value_pair = rb_ary_entry(tags_as_array, i);

    if (!RB_TYPE_P(name_value_pair, T_ARRAY)) {
      ddog_Vec_Tag_drop(tags);
      ENFORCE_TYPE(name_value_pair, T_ARRAY);
    }

    // Note: We can index the array without checking its size first because rb_ary_entry returns Qnil if out of bounds
    VALUE tag_name = rb_ary_entry(name_value_pair, 0);
    VALUE tag_value = rb_ary_entry(name_value_pair, 1);

    if (!(RB_TYPE_P(tag_name, T_STRING) && RB_TYPE_P(tag_value, T_STRING))) {
      ddog_Vec_Tag_drop(tags);
      ENFORCE_TYPE(tag_name, T_STRING);
      ENFORCE_TYPE(tag_value, T_STRING);
    }

    ddog_Vec_Tag_PushResult push_result =
      ddog_Vec_Tag_push(&tags, char_slice_from_ruby_string(tag_name), char_slice_from_ruby_string(tag_value));

    if (push_result.tag == DDOG_VEC_TAG_PUSH_RESULT_ERR) {
      // libdatadog validates tags and may catch invalid tags that ddtrace didn't actually catch.
      // We warn users about such tags, and then just ignore them.

      int exception_state;
      rb_protect(log_failure_to_process_tag, get_error_details_and_drop(&push_result.err), &exception_state);

      // Since we are calling into Ruby code, it may raise an exception. Ensure that dynamically-allocated tags
      // get cleaned before propagating the exception.
      if (exception_state) {
        ddog_Vec_Tag_drop(tags);
        rb_jump_tag(exception_state);  // "Re-raise" exception
      }
    }
  }

  return tags;
}
