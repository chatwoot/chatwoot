# frozen_string_literal: true

require "test_prof/factory_prof/fabrication_patch"

module TestProf
  module FactoryProf
    module FactoryBuilders
      # implementation of #patch and #track methods
      # to provide unified interface for all factory-building gems
      class Fabrication
        # Monkey-patch Fabrication
        def self.patch
          TestProf.require "fabrication" do
            ::Fabricate.singleton_class.prepend(FabricationPatch)
          end
        end

        def self.track(factory, &block)
          FactoryProf.track(factory, &block)
        end
      end
    end
  end
end
