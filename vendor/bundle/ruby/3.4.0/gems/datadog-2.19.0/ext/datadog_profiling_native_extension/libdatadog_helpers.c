#include "libdatadog_helpers.h"

#include <ruby.h>

const char *ruby_value_type_to_string(enum ruby_value_type type) {
  return ruby_value_type_to_char_slice(type).ptr;
}

ddog_CharSlice ruby_value_type_to_char_slice(enum ruby_value_type type) {
  switch (type) {
    case(RUBY_T_NONE    ): return DDOG_CHARSLICE_C("T_NONE");
    case(RUBY_T_OBJECT  ): return DDOG_CHARSLICE_C("T_OBJECT");
    case(RUBY_T_CLASS   ): return DDOG_CHARSLICE_C("T_CLASS");
    case(RUBY_T_MODULE  ): return DDOG_CHARSLICE_C("T_MODULE");
    case(RUBY_T_FLOAT   ): return DDOG_CHARSLICE_C("T_FLOAT");
    case(RUBY_T_STRING  ): return DDOG_CHARSLICE_C("T_STRING");
    case(RUBY_T_REGEXP  ): return DDOG_CHARSLICE_C("T_REGEXP");
    case(RUBY_T_ARRAY   ): return DDOG_CHARSLICE_C("T_ARRAY");
    case(RUBY_T_HASH    ): return DDOG_CHARSLICE_C("T_HASH");
    case(RUBY_T_STRUCT  ): return DDOG_CHARSLICE_C("T_STRUCT");
    case(RUBY_T_BIGNUM  ): return DDOG_CHARSLICE_C("T_BIGNUM");
    case(RUBY_T_FILE    ): return DDOG_CHARSLICE_C("T_FILE");
    case(RUBY_T_DATA    ): return DDOG_CHARSLICE_C("T_DATA");
    case(RUBY_T_MATCH   ): return DDOG_CHARSLICE_C("T_MATCH");
    case(RUBY_T_COMPLEX ): return DDOG_CHARSLICE_C("T_COMPLEX");
    case(RUBY_T_RATIONAL): return DDOG_CHARSLICE_C("T_RATIONAL");
    case(RUBY_T_NIL     ): return DDOG_CHARSLICE_C("T_NIL");
    case(RUBY_T_TRUE    ): return DDOG_CHARSLICE_C("T_TRUE");
    case(RUBY_T_FALSE   ): return DDOG_CHARSLICE_C("T_FALSE");
    case(RUBY_T_SYMBOL  ): return DDOG_CHARSLICE_C("T_SYMBOL");
    case(RUBY_T_FIXNUM  ): return DDOG_CHARSLICE_C("T_FIXNUM");
    case(RUBY_T_UNDEF   ): return DDOG_CHARSLICE_C("T_UNDEF");
    case(RUBY_T_IMEMO   ): return DDOG_CHARSLICE_C("T_IMEMO");
    case(RUBY_T_NODE    ): return DDOG_CHARSLICE_C("T_NODE");
    case(RUBY_T_ICLASS  ): return DDOG_CHARSLICE_C("T_ICLASS");
    case(RUBY_T_ZOMBIE  ): return DDOG_CHARSLICE_C("T_ZOMBIE");
    #ifndef NO_T_MOVED
    case(RUBY_T_MOVED   ): return DDOG_CHARSLICE_C("T_MOVED");
    #endif
                  default: return DDOG_CHARSLICE_C("BUG: Unknown value for ruby_value_type");
  }
}

size_t read_ddogerr_string_and_drop(ddog_Error *error, char *string, size_t capacity) {
  if (capacity == 0 || string == NULL) {
    // short-circuit, we can't write anything
    ddog_Error_drop(error);
    return 0;
  }

  ddog_CharSlice error_msg_slice = ddog_Error_message(error);
  size_t error_msg_size = error_msg_slice.len;
  // Account for extra null char for proper cstring
  if (error_msg_size >= capacity) {
    // Error message too big, lets truncate it to capacity - 1 to allow for extra null at end
    error_msg_size = capacity - 1;
  }
  strncpy(string, error_msg_slice.ptr, error_msg_size);
  string[error_msg_size] = '\0';
  ddog_Error_drop(error);
  return error_msg_size;
}

ddog_prof_ManagedStringId intern_or_raise(ddog_prof_ManagedStringStorage string_storage, ddog_CharSlice string) {
  if (string.len == 0) return (ddog_prof_ManagedStringId) { 0 }; // Id 0 is always an empty string, no need to ask

  ddog_prof_ManagedStringStorageInternResult intern_result = ddog_prof_ManagedStringStorage_intern(string_storage, string);
  if (intern_result.tag == DDOG_PROF_MANAGED_STRING_STORAGE_INTERN_RESULT_ERR) {
    rb_raise(rb_eRuntimeError, "Failed to intern string: %"PRIsVALUE, get_error_details_and_drop(&intern_result.err));
  }
  return intern_result.ok;
}

void intern_all_or_raise(
  ddog_prof_ManagedStringStorage string_storage,
  ddog_prof_Slice_CharSlice strings,
  ddog_prof_ManagedStringId *output_ids,
  uintptr_t output_ids_size
) {
  ddog_prof_MaybeError result = ddog_prof_ManagedStringStorage_intern_all(string_storage, strings, output_ids, output_ids_size);
  if (result.tag == DDOG_PROF_OPTION_ERROR_SOME_ERROR) {
    rb_raise(rb_eRuntimeError, "Failed to intern_all: %"PRIsVALUE, get_error_details_and_drop(&result.some));
  }
}
