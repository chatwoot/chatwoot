#pragma once

#include <datadog/profiling.h>
#include "ruby_helpers.h"

static inline VALUE ruby_string_from_vec_u8(ddog_Vec_U8 string) {
  return rb_str_new((char *) string.ptr, string.len);
}

// Utility function to be able to extract an error cstring from a ddog_Error.
// Returns the amount of characters written to string (which are necessarily
// bounded by capacity - 1 since the string will be null-terminated).
size_t read_ddogerr_string_and_drop(ddog_Error *error, char *string, size_t capacity);

// Used for pretty printing this Ruby enum. Returns "T_UNKNOWN_OR_MISSING_RUBY_VALUE_TYPE_ENTRY" for unknown elements.
// In practice, there's a few types that the profiler will probably never encounter, but I've added all entries of
// ruby_value_type that Ruby uses so that we can also use this for debugging.
const char *ruby_value_type_to_string(enum ruby_value_type type);
ddog_CharSlice ruby_value_type_to_char_slice(enum ruby_value_type type);

ddog_prof_ManagedStringId intern_or_raise(ddog_prof_ManagedStringStorage string_storage, ddog_CharSlice string);

void intern_all_or_raise(
  ddog_prof_ManagedStringStorage string_storage,
  ddog_prof_Slice_CharSlice strings,
  ddog_prof_ManagedStringId *output_ids,
  uintptr_t output_ids_size
);
