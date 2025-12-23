require 'spec_helper'

describe '#evalsha(*)' do
  let(:script) { 'return nil' }
  let(:script_digest) { Digest::SHA1.hexdigest(script) }

  it 'returns nothing' do
    @redises.evalsha(script_digest).should be_nil
  end
end
