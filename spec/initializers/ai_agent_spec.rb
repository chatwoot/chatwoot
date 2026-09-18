# Tests that the Captain / AI Agents SDK initializer does not raise when the
# installation_configs table does not yet exist (fresh database scenario).

require 'rails_helper'

RSpec.describe 'Captain AI SDK initializer' do
  # Path to the initializer — adjust if the file has a different name
  let(:initializer_path) { Rails.root.join('config/initializers/captain.rb') }

  describe 'when installation_configs table does not exist (fresh install)' do
    before do
      # Simulate a pre-migration database by making table_exists? return false
      allow(ActiveRecord::Base.connection)
        .to receive(:table_exists?)
        .with(:installation_configs)
        .and_return(false)
    end

    it 'does not raise PG::UndefinedTable' do
      expect { load initializer_path }.not_to raise_error
    end

    it 'does not attempt to query InstallationConfig' do
      expect(InstallationConfig).not_to receive(:find_by)
      load initializer_path
    end
  end

  describe 'when installation_configs table exists (normal boot)' do
    before do
      allow(ActiveRecord::Base.connection)
        .to receive(:table_exists?)
        .with(:installation_configs)
        .and_return(true)
    end

    it 'does not raise' do
      expect { load initializer_path }.not_to raise_error
    end
  end

  describe 'when the database connection is not established' do
    before do
      allow(ActiveRecord::Base.connection)
        .to receive(:table_exists?)
        .and_raise(ActiveRecord::NoDatabaseError)
    end

    it 'does not raise (handles NoDatabaseError gracefully)' do
      expect { load initializer_path }.not_to raise_error
    end
  end
end
