#include <ruby.h>
#include <datadog/crashtracker.h>

#include "datadog_ruby_common.h"

static VALUE _native_start_or_update_on_fork(int argc, VALUE *argv, DDTRACE_UNUSED VALUE _self);
static VALUE _native_stop(DDTRACE_UNUSED VALUE _self);

static bool first_init = true;

// Used to report Ruby VM crashes.
// Once initialized, segfaults will be reported automatically using libdatadog.

void crashtracker_init(VALUE core_module) {
  VALUE crashtracking_module = rb_define_module_under(core_module, "Crashtracking");
  VALUE crashtracker_class = rb_define_class_under(crashtracking_module, "Component", rb_cObject);

  rb_define_singleton_method(crashtracker_class, "_native_start_or_update_on_fork", _native_start_or_update_on_fork, -1);
  rb_define_singleton_method(crashtracker_class, "_native_stop", _native_stop, 0);
}

static VALUE _native_start_or_update_on_fork(int argc, VALUE *argv, DDTRACE_UNUSED VALUE _self) {
  VALUE options;
  rb_scan_args(argc, argv, "0:", &options);
  if (options == Qnil) options = rb_hash_new();

  VALUE agent_base_url = rb_hash_fetch(options, ID2SYM(rb_intern("agent_base_url")));
  VALUE path_to_crashtracking_receiver_binary = rb_hash_fetch(options, ID2SYM(rb_intern("path_to_crashtracking_receiver_binary")));
  VALUE ld_library_path = rb_hash_fetch(options, ID2SYM(rb_intern("ld_library_path")));
  VALUE tags_as_array = rb_hash_fetch(options, ID2SYM(rb_intern("tags_as_array")));
  VALUE action = rb_hash_fetch(options, ID2SYM(rb_intern("action")));
  VALUE upload_timeout_seconds = rb_hash_fetch(options, ID2SYM(rb_intern("upload_timeout_seconds")));

  VALUE start_action = ID2SYM(rb_intern("start"));
  VALUE update_on_fork_action = ID2SYM(rb_intern("update_on_fork"));

  ENFORCE_TYPE(agent_base_url, T_STRING);
  ENFORCE_TYPE(tags_as_array, T_ARRAY);
  ENFORCE_TYPE(path_to_crashtracking_receiver_binary, T_STRING);
  ENFORCE_TYPE(ld_library_path, T_STRING);
  ENFORCE_TYPE(action, T_SYMBOL);
  ENFORCE_TYPE(upload_timeout_seconds, T_FIXNUM);

  if (action != start_action && action != update_on_fork_action) rb_raise(rb_eArgError, "Unexpected action: %+"PRIsVALUE, action);

  VALUE version = datadog_gem_version();

  // Tags and endpoint are heap-allocated, so after here we can't raise exceptions otherwise we'll leak this memory
  // Start of exception-free zone to prevent leaks {{
  ddog_Endpoint *endpoint = ddog_endpoint_from_url(char_slice_from_ruby_string(agent_base_url));
  if (endpoint == NULL) {
    rb_raise(rb_eRuntimeError, "Failed to create endpoint from agent_base_url: %"PRIsVALUE, agent_base_url);
  }
  ddog_Vec_Tag tags = convert_tags(tags_as_array);

  ddog_crasht_Config config = {
    .additional_files = {},
    // @ivoanjo: The Ruby VM already uses an alt stack to detect stack overflows.
    //
    // In libdatadog < 14 with `create_alt_stack = true` I saw a segfault, such as Ruby 2.6's bug with
    // "Process.detach(fork { exit! }).instance_variable_get(:@foo)" being turned into a
    // "-e:1:in `instance_variable_get': stack level too deep (SystemStackError)" by Ruby.
    // The Ruby crash handler also seems to get confused when this option is enabled and
    // "Process.kill('SEGV', Process.pid)" gets run.
    //
    // This actually changed in libdatadog 14, so I could see no issues with `create_alt_stack = true`, but not
    // overriding what Ruby set up seems a saner default to keep anyway.
    .create_alt_stack = false,
    .use_alt_stack = true,
    .endpoint = endpoint,
    .resolve_frames = DDOG_CRASHT_STACKTRACE_COLLECTION_ENABLED_WITH_SYMBOLS_IN_RECEIVER,
    .timeout_ms = FIX2INT(upload_timeout_seconds) * 1000,
  };

  ddog_crasht_Metadata metadata = {
    .library_name = DDOG_CHARSLICE_C("dd-trace-rb"),
    .library_version = char_slice_from_ruby_string(version),
    .family = DDOG_CHARSLICE_C("ruby"),
    .tags = &tags,
  };

  ddog_crasht_EnvVar ld_library_path_env = {
    .key = DDOG_CHARSLICE_C("LD_LIBRARY_PATH"),
    .val = char_slice_from_ruby_string(ld_library_path),
  };

  ddog_crasht_ReceiverConfig receiver_config = {
    .args = {},
    .env = {.ptr = &ld_library_path_env, .len = 1},
    .path_to_receiver_binary = char_slice_from_ruby_string(path_to_crashtracking_receiver_binary),
    .optional_stderr_filename = {},
    .optional_stdout_filename = {},
  };

  ddog_VoidResult result =
    action == start_action ?
      (first_init ?
        ddog_crasht_init(config, receiver_config, metadata) :
        ddog_crasht_reconfigure(config, receiver_config, metadata)
      ) :
      ddog_crasht_update_on_fork(config, receiver_config, metadata);

  first_init = false;

  // Clean up before potentially raising any exceptions
  ddog_Vec_Tag_drop(tags);
  ddog_endpoint_drop(endpoint);
  // }} End of exception-free zone to prevent leaks

  if (result.tag == DDOG_VOID_RESULT_ERR) {
    rb_raise(rb_eRuntimeError, "Failed to start/update the crash tracker: %"PRIsVALUE, get_error_details_and_drop(&result.err));
  }

  return Qtrue;
}

static VALUE _native_stop(DDTRACE_UNUSED VALUE _self) {
  ddog_VoidResult result = ddog_crasht_disable();

  if (result.tag == DDOG_VOID_RESULT_ERR) {
    rb_raise(rb_eRuntimeError, "Failed to stop the crash tracker: %"PRIsVALUE, get_error_details_and_drop(&result.err));
  }

  return Qtrue;
}
