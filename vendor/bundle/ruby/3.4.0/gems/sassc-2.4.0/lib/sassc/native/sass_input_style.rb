# frozen_string_literal: true

module SassC
  module Native
    SassInputStyle = enum(
      :sass_context_null,
      :sass_context_file,
      :sass_context_data,
      :sass_context_folder
    )
  end
end

