# frozen_string_literal: true

module SassC
  module Native
    SassOutputStyle = enum(
      :sass_style_nested,
      :sass_style_expanded,
      :sass_style_compact,
      :sass_style_compressed
    )
  end
end
