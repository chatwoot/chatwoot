# frozen_string_literal: true

module SassC
  module Native
    # Creators for sass function list and function descriptors
    # ADDAPI Sass_C_Function_List ADDCALL sass_make_function_list (size_t length);
    # ADDAPI Sass_C_Function_Callback ADDCALL sass_make_function (const char* signature, Sass_C_Function fn, void* cookie);
    attach_function :sass_make_function_list, [:size_t], :sass_c_function_list_ptr
    attach_function :sass_make_function, [:string, :sass_c_function, :pointer], :sass_c_function_callback_ptr

    # Setters and getters for callbacks on function lists
    # ADDAPI Sass_C_Function_Callback ADDCALL sass_function_get_list_entry(Sass_C_Function_List list, size_t pos);
    # ADDAPI void ADDCALL sass_function_set_list_entry(Sass_C_Function_List list, size_t pos, Sass_C_Function_Callback cb);
    attach_function :sass_function_get_list_entry, [:sass_c_function_list_ptr, :size_t], :sass_c_function_callback_ptr
    attach_function :sass_function_set_list_entry, [:sass_c_function_list_ptr, :size_t, :sass_c_function_callback_ptr], :void

    # ADDAPI union Sass_Value* ADDCALL sass_make_number  (double val, const char* unit);
    attach_function :sass_make_number, [:double, :string], :sass_value_ptr

    # ADDAPI union Sass_Value* ADDCALL sass_make_string  (const char* val);
    attach_function :sass_make_string, [:string], :sass_value_ptr

    # ADDAPI union Sass_Value* ADDCALL sass_make_qstring (const char* val);
    attach_function :sass_make_qstring, [:string], :sass_value_ptr

    # ADDAPI union Sass_Value* ADDCALL sass_make_color   (double r, double g, double b, double a);
    attach_function :sass_make_color, [:double, :double, :double, :double], :sass_value_ptr

    # ADDAPI union Sass_Value* ADDCALL sass_make_map     (size_t len);
    attach_function :sass_make_map, [:size_t], :sass_value_ptr

    # ADDAPI union Sass_Value* ADDCALL sass_make_list     (size_t len, enum Sass_Separator sep)
    attach_function :sass_make_list, [:size_t, SassSeparator], :sass_value_ptr

    # ADDAPI union Sass_Value* ADDCALL sass_make_boolean (boolean val);
    attach_function :sass_make_boolean, [:bool], :sass_value_ptr

    # ADDAPI void ADDCALL sass_map_set_key (union Sass_Value* v, size_t i, union Sass_Value*);
    attach_function :sass_map_set_key, [:sass_value_ptr, :size_t, :sass_value_ptr], :void

    # ADDAPI union Sass_Value* ADDCALL sass_map_get_key (const union Sass_Value* v, size_t i);
    attach_function :sass_map_get_key, [:sass_value_ptr, :size_t], :sass_value_ptr

    # ADDAPI void ADDCALL sass_map_set_value (union Sass_Value* v, size_t i, union Sass_Value*);
    attach_function :sass_map_set_value, [:sass_value_ptr, :size_t, :sass_value_ptr], :void

    # ADDAPI union Sass_Value* ADDCALL sass_map_get_value (const union Sass_Value* v, size_t i);
    attach_function :sass_map_get_value, [:sass_value_ptr, :size_t], :sass_value_ptr

    # ADDAPI size_t ADDCALL sass_map_get_length (const union Sass_Value* v);
    attach_function :sass_map_get_length, [:sass_value_ptr], :size_t

    # ADDAPI union Sass_Value* ADDCALL sass_list_get_value (const union Sass_Value* v, size_t i);
    attach_function :sass_list_get_value, [:sass_value_ptr, :size_t], :sass_value_ptr

    # ADDAPI void ADDCALL sass_list_set_value (union Sass_Value* v, size_t i, union Sass_Value* value);
    attach_function :sass_list_set_value, [:sass_value_ptr, :size_t, :sass_value_ptr], :void

    # ADDAPI size_t ADDCALL sass_list_get_length (const union Sass_Value* v);
    attach_function :sass_list_get_length, [:sass_value_ptr], :size_t

    # ADDAPI union Sass_Value* ADDCALL sass_make_error   (const char* msg);
    attach_function :sass_make_error, [:string], :sass_value_ptr

    # ADDAPI enum Sass_Tag ADDCALL sass_value_get_tag (const union Sass_Value* v);
    attach_function :sass_value_get_tag, [:sass_value_ptr], SassTag
    attach_function :sass_value_is_null, [:sass_value_ptr], :bool

    # ADDAPI const char* ADDCALL sass_string_get_value (const union Sass_Value* v);
    attach_function :sass_string_get_value, [:sass_value_ptr], :string

    # ADDAPI bool ADDCALL sass_string_is_quoted(const union Sass_Value* v);
    attach_function :sass_string_is_quoted, [:sass_value_ptr], :bool

    # ADDAPI const char* ADDCALL sass_number_get_value (const union Sass_Value* v);
    attach_function :sass_number_get_value, [:sass_value_ptr], :double

    # ADDAPI const char* ADDCALL sass_number_get_unit (const union Sass_Value* v);
    attach_function :sass_number_get_unit, [:sass_value_ptr], :string
    
    # ADDAPI const char* ADDCALL sass_boolean_get_value (const union Sass_Value* v);
    attach_function :sass_boolean_get_value, [:sass_value_ptr], :bool

    def self.string_get_type(native_value)
      string_is_quoted(native_value) ? :string : :identifier
    end

    # ADDAPI double ADDCALL sass_color_get_r (const union Sass_Value* v);
    # ADDAPI void ADDCALL sass_color_set_r (union Sass_Value* v, double r);
    # ADDAPI double ADDCALL sass_color_get_g (const union Sass_Value* v);
    # ADDAPI void ADDCALL sass_color_set_g (union Sass_Value* v, double g);
    # ADDAPI double ADDCALL sass_color_get_b (const union Sass_Value* v);
    # ADDAPI void ADDCALL sass_color_set_b (union Sass_Value* v, double b);
    # ADDAPI double ADDCALL sass_color_get_a (const union Sass_Value* v);
    # ADDAPI void ADDCALL sass_color_set_a (union Sass_Value* v, double a);
    ['r', 'g', 'b', 'a'].each do |color_channel|
      attach_function "sass_color_get_#{color_channel}".to_sym, [:sass_value_ptr], :double
      attach_function "sass_color_set_#{color_channel}".to_sym, [:sass_value_ptr, :double], :void
    end

    # ADDAPI char* ADDCALL sass_error_get_message (const union Sass_Value* v);
    # ADDAPI void ADDCALL sass_error_set_message (union Sass_Value* v, char* msg);
    attach_function :sass_error_get_message, [:sass_value_ptr], :string
    attach_function :sass_error_set_message, [:sass_value_ptr, :pointer], :void

    # Getters for custom function descriptors
    # ADDAPI const char* ADDCALL sass_function_get_signature (Sass_C_Function_Callback fn);
    # ADDAPI Sass_C_Function ADDCALL sass_function_get_function (Sass_C_Function_Callback fn);
    # ADDAPI void* ADDCALL sass_function_get_cookie (Sass_C_Function_Callback fn);
    attach_function :sass_function_get_signature, [:sass_c_function_callback_ptr], :string
    attach_function :sass_function_get_function, [:sass_c_function_callback_ptr], :sass_c_function
    attach_function :sass_function_get_cookie, [:sass_c_function_callback_ptr], :pointer

    # Creators for custom importer callback (with some additional pointer)
    # The pointer is mostly used to store the callback into the actual binding
    # ADDAPI Sass_C_Import_Callback ADDCALL sass_make_importer (Sass_C_Import_Fn, void* cookie);
    attach_function :sass_make_importer, [:sass_c_import_function, :pointer], :sass_importer

    # Getters for import function descriptors
    # ADDAPI Sass_C_Import_Fn ADDCALL sass_import_get_function (Sass_C_Import_Callback fn);
    # ADDAPI void* ADDCALL sass_import_get_cookie (Sass_C_Import_Callback fn);

    # Deallocator for associated memory
    # ADDAPI void ADDCALL sass_delete_importer (Sass_C_Import_Callback fn);

    # Creator for sass custom importer return argument list
    # ADDAPI struct Sass_Import** ADDCALL sass_make_import_list (size_t length);
    attach_function :sass_make_import_list, [:size_t], :sass_import_list_ptr

    # Creator for a single import entry returned by the custom importer inside the list
    # ADDAPI struct Sass_Import* ADDCALL sass_make_import_entry (const char* path, char* source, char* srcmap);
    # ADDAPI struct Sass_Import* ADDCALL sass_make_import (const char* path, const char* base, char* source, char* srcmap);
    attach_function :sass_make_import_entry, [:string, :pointer, :pointer], :sass_import_ptr

    # Setters to insert an entry into the import list (you may also use [] access directly)
    # Since we are dealing with pointers they should have a guaranteed and fixed size
    # ADDAPI void ADDCALL sass_import_set_list_entry (struct Sass_Import** list, size_t idx, struct Sass_Import* entry);
    attach_function :sass_import_set_list_entry, [:sass_import_list_ptr, :size_t, :sass_import_ptr], :void
    # ADDAPI struct Sass_Import* ADDCALL sass_import_get_list_entry (struct Sass_Import** list, size_t idx);

    # Getters for import entry
    # ADDAPI const char* ADDCALL sass_import_get_imp_path (struct Sass_Import*);
    attach_function :sass_import_get_imp_path, [:sass_import_ptr], :string
    # ADDAPI const char* ADDCALL sass_import_get_abs_path (struct Sass_Import*);
    attach_function :sass_import_get_abs_path, [:sass_import_ptr], :string
    # ADDAPI const char* ADDCALL sass_import_get_source (struct Sass_Import*);
    attach_function :sass_import_get_source, [:sass_import_ptr], :string
    # ADDAPI const char* ADDCALL sass_import_get_srcmap (struct Sass_Import*);
    # Explicit functions to take ownership of these items
    # The property on our struct will be reset to NULL
    # ADDAPI char* ADDCALL sass_import_take_source (struct Sass_Import*);
    # ADDAPI char* ADDCALL sass_import_take_srcmap (struct Sass_Import*);

    # Deallocator for associated memory (incl. entries)
    # ADDAPI void ADDCALL sass_delete_import_list (struct Sass_Import**);
    # Just in case we have some stray import structs
    # ADDAPI void ADDCALL sass_delete_import (struct Sass_Import*);
  end
end
