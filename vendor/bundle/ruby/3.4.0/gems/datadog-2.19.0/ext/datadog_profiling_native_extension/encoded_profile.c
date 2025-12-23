#include "encoded_profile.h"
#include "datadog_ruby_common.h"
#include "libdatadog_helpers.h"

// This class exists to wrap a ddog_prof_EncodedProfile into a Ruby object
// This file implements the native bits of the Datadog::Profiling::EncodedProfile class

static void encoded_profile_typed_data_free(void *state_ptr);
static VALUE _native_bytes(VALUE self);

static VALUE encoded_profile_class = Qnil;

void encoded_profile_init(VALUE profiling_module) {
  encoded_profile_class = rb_define_class_under(profiling_module, "EncodedProfile", rb_cObject);

  rb_undef_alloc_func(encoded_profile_class); // Class cannot be created from Ruby code
  rb_global_variable(&encoded_profile_class);

  rb_define_method(encoded_profile_class, "_native_bytes", _native_bytes, 0);
}

// This structure is used to define a Ruby object that stores a `ddog_prof_EncodedProfile`
// See also https://github.com/ruby/ruby/blob/master/doc/extension.rdoc for how this works
static const rb_data_type_t encoded_profile_typed_data = {
  .wrap_struct_name = "Datadog::Profiling::EncodedProfile",
  .function = {
    .dmark = NULL, // We don't store references to Ruby objects so we don't need to mark any of them
    .dfree = encoded_profile_typed_data_free,
    .dsize = NULL, // We don't track memory usage (although it'd be cool if we did!)
    //.dcompact = NULL, // Not needed -- we don't store references to Ruby objects
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

VALUE from_ddog_prof_EncodedProfile(ddog_prof_EncodedProfile profile) {
  ddog_prof_EncodedProfile *state = ruby_xcalloc(1, sizeof(ddog_prof_EncodedProfile));
  *state = profile;
  return TypedData_Wrap_Struct(encoded_profile_class, &encoded_profile_typed_data, state);
}

static ddog_ByteSlice get_bytes(ddog_prof_EncodedProfile *state) {
  ddog_prof_Result_ByteSlice raw_bytes = ddog_prof_EncodedProfile_bytes(state);
  if (raw_bytes.tag == DDOG_PROF_RESULT_BYTE_SLICE_ERR_BYTE_SLICE) {
    rb_raise(rb_eRuntimeError, "Failed to get bytes from profile: %"PRIsVALUE, get_error_details_and_drop(&raw_bytes.err));
  }
  return raw_bytes.ok;
}

static ddog_prof_EncodedProfile *internal_to_ddog_prof_EncodedProfile(VALUE object) {
  ddog_prof_EncodedProfile *state;
  TypedData_Get_Struct(object, ddog_prof_EncodedProfile, &encoded_profile_typed_data, state);
  return state;
}

ddog_prof_EncodedProfile *to_ddog_prof_EncodedProfile(VALUE object) {
  ddog_prof_EncodedProfile *state = internal_to_ddog_prof_EncodedProfile(object);
  get_bytes(state); // Validate profile is still usable -- if it's not, this will raise an exception
  return state;
}

static void encoded_profile_typed_data_free(void *state_ptr) {
  ddog_prof_EncodedProfile *state = (ddog_prof_EncodedProfile *) state_ptr;

  // This drops the profile itself
  ddog_prof_EncodedProfile_drop(state);

  // This drops the tiny bit of memory we allocated to contain the ` ddog_prof_EncodedProfile` struct
  ruby_xfree(state);
}

static VALUE _native_bytes(VALUE self) {
  ddog_ByteSlice bytes = get_bytes(internal_to_ddog_prof_EncodedProfile(self));
  return rb_str_new((const char *) bytes.ptr, bytes.len);
}

VALUE enforce_encoded_profile_instance(VALUE object) {
  ENFORCE_TYPED_DATA(object, &encoded_profile_typed_data);
  return object;
}
