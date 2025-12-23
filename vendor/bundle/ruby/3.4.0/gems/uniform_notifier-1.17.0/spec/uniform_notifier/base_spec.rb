# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UniformNotifier::Base do
  context '#inline_channel_notify' do
    before { allow(UniformNotifier::Base).to receive(:active?).and_return(true) }
    it 'should keep the compatibility' do
      expect(UniformNotifier::Base).to receive(:_inline_notify).once.with({ title: 'something' })
      UniformNotifier::Base.inline_notify('something')
    end
  end
  context '#out_of_channel_notify' do
    before { allow(UniformNotifier::Base).to receive(:active?).and_return(true) }
    it 'should keep the compatibility' do
      expect(UniformNotifier::Base).to receive(:_out_of_channel_notify).once.with({ title: 'something' })
      UniformNotifier::Base.out_of_channel_notify('something')
    end
  end
end
