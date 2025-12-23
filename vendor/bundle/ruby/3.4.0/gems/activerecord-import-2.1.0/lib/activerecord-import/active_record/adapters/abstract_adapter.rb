# frozen_string_literal: true

require "activerecord-import/adapters/abstract_adapter"

module ActiveRecord # :nodoc:
  module ConnectionAdapters # :nodoc:
    class AbstractAdapter # :nodoc:
      include ActiveRecord::Import::AbstractAdapter::InstanceMethods
    end
  end
end
