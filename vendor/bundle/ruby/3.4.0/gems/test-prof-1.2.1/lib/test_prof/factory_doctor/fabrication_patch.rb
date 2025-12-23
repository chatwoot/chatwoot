# frozen_string_literal: true

module TestProf
  module FactoryDoctor
    # Wrap #run method with FactoryDoctor tracking
    module FabricationPatch
      def create(*)
        FactoryDoctor.within_factory(:create) { super }
      end
    end
  end
end
