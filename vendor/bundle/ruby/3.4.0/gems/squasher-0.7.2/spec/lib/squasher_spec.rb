require 'spec_helper'

describe Squasher do
  context '.squash' do
    specify { expected_covert("2013/12/23", Time.new(2013, 12, 23)) }
    specify { expected_covert("2013", Time.new(2013, 1, 1)) }

    def expected_covert(input, expected)
      expect(Squasher::Worker).to receive(:process).with(expected)
      Squasher.squash(input)
    end
  end

  context '.rake' do
    before do
      allow_any_instance_of(Object).to receive(:system)
    end

    context 'when given a description' do
      it 'outputs it' do
        expect(Squasher).to receive(:tell).with('description')
        Squasher.rake('db:migrate', 'description')
      end
    end

    it 'switches to the app root before running a given command' do
      allow(Dir).to receive(:pwd) { fake_root }
      expect(Dir).to receive(:chdir).with(fake_root)
      Squasher.rake('db:migrate')
    end

    it 'runs a given command' do
      expect_any_instance_of(Object).to receive(:system).with(anything, /db:migrate/)
      Squasher.rake('db:migrate')
    end

    it 'sets the Rails environment to development' do
      expect_any_instance_of(Object).to receive(:system)
        .with(hash_including('RAILS_ENV' => 'development'), /db:migrate/)
      Squasher.rake('db:migrate')
    end

    it 'disables database environment check' do
      expect_any_instance_of(Object).to receive(:system)
        .with(hash_including('DISABLE_DATABASE_ENVIRONMENT_CHECK' => '1'), /db:migrate/)
      Squasher.rake('db:migrate')
    end
  end

  context '.print' do
    context 'when options are empty' do
      it 'prints the message without error' do
        Squasher.print('asdf % asdf', {})
      end
    end
  end
end
