# config/initializers/taggable_cache_compat.rb

module ActsAsTaggableOn
  module Taggable
    # Stub out the old Cache module so migrations that refer to it
    # won't blow up. Its `included` hook is a no-op.
    unless const_defined?(:Cache)
      Cache = Module.new do
        def self.included(base)
          # no-op: conversation.cached_label_list still exists,
          # but we won't auto-update it
        end
      end
    end
  end
end