# frozen_string_literal: true

class GlobalID
  module FixtureSet
    def global_id(fixture_set_name, label, column_type: :integer, **options)
      create_global_id(fixture_set_name, label, column_type: column_type, klass: GlobalID, **options)
    end

    def signed_global_id(fixture_set_name, label, column_type: :integer, **options)
      create_global_id(fixture_set_name, label, column_type: column_type, klass: SignedGlobalID, **options)
    end

    private
      def create_global_id(fixture_set_name, label, klass:, column_type: :integer, **options)
        identifier = identify(label, column_type)
        model_name = default_fixture_model_name(fixture_set_name)
        uri = URI::GID.build([GlobalID.app, model_name, identifier, {}])
        klass.new(uri, **options)
      end
  end
end
