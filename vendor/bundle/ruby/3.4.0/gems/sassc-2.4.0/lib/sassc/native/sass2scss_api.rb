# frozen_string_literal: true

module SassC
  module Native
    # ADDAPI char* ADDCALL sass2scss (const char* sass, const int options);
    attach_function :sass2scss, [:string, :int], :string

    # ADDAPI const char* ADDCALL sass2scss_version(void);
  end
end
