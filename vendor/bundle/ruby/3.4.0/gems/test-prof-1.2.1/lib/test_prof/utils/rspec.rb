# frozen_string_literal: true

unless "".respond_to?(:parameterize)
  require "test_prof/ext/string_parameterize"
  using TestProf::StringParameterize
end

module TestProf
  module Utils
    module RSpec
      class << self
        def example_to_filename(example)
          ::RSpec::Core::Metadata.id_from(example.metadata).parameterize
        end
      end
    end
  end
end
