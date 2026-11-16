require 'rails_helper'

RSpec.describe ReadReplica::Configuration do
  describe '.validate!' do
    it 'does not require replica settings while routing is disabled' do
      with_modified_env POSTGRES_REPLICA_ENABLED: 'false', POSTGRES_REPLICA_HOST: nil do
        expect { described_class.validate! }.not_to raise_error
      end
    end

    it 'fails fast when an enabled replica is missing required settings' do
      with_modified_env POSTGRES_REPLICA_ENABLED: 'true', POSTGRES_REPLICA_HOST: nil,
                        POSTGRES_REPLICA_DATABASE: nil, POSTGRES_REPLICA_USERNAME: nil do
        expect { described_class.validate! }
          .to raise_error(KeyError, /POSTGRES_REPLICA_HOST, POSTGRES_REPLICA_DATABASE, POSTGRES_REPLICA_USERNAME/)
      end
    end

    it 'accepts complete enabled replica settings' do
      with_modified_env POSTGRES_REPLICA_ENABLED: 'true', POSTGRES_REPLICA_HOST: 'replica',
                        POSTGRES_REPLICA_DATABASE: 'chatwoot', POSTGRES_REPLICA_USERNAME: 'reader' do
        expect { described_class.validate! }.not_to raise_error
      end
    end
  end
end
