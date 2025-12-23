# frozen_string_literal: true

require "active_support/lazy_load_hooks"

ActiveSupport.on_load(:active_record) do
  require "activerecord-import/base"
end
