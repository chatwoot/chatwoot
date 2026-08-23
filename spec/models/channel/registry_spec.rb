require 'rails_helper'

RSpec.describe Channel::Registry do
  # A hypothetical new channel, added purely by subclassing Channel::Base and
  # implementing its capabilities. This proves the modularity goal: a new channel
  # type needs only the model (plus, if not auto-loaded, a registry reference) —
  # no service/controller/job edits.
  let(:stub_channel_class) do
    Class.new(Channel::Base) do
      self.abstract_class = true

      def param_type
        'stub'
      end

      def friendly_name
        'Stub'
      end

      def send_service
        'StubSendService'
      end

      def editable_attrs
        [:stub_attr]
      end

      def whatsapp?
        false
      end

      def sms?
        false
      end
    end
  end

  before do
    stub_const('Channel::Stub', stub_channel_class)
    # The registry memoizes its enumeration; reset so the new subclass is seen.
    described_class.instance_variable_set(:@all, nil)
  end

  after do
    described_class.instance_variable_set(:@all, nil)
  end

  it 'enumerates a new channel subclass automatically' do
    expect(described_class.channel_class_for('stub')).to eq(Channel::Stub)
  end

  it 'resolves editable attrs from the model' do
    expect(described_class.editable_attrs_for(Channel::Stub)).to eq([:stub_attr])
  end

  it 'exposes the create-slug for a class' do
    expect(described_class.param_type_for(Channel::Stub)).to eq('stub')
  end

  it 'lets the channel own its dispatch capabilities' do
    channel = Channel::Stub.allocate
    expect(channel.send_service).to eq('StubSendService')
    expect(channel.whatsapp?).to be(false)
    expect(channel.sms?).to be(false)
  end

  it 'asks the channel for inbox predicates and friendly name' do
    channel = Channel::Stub.allocate
    inbox = Inbox.allocate
    allow(inbox).to receive(:channel).and_return(channel)

    expect(inbox.inbox_type).to eq('Stub')
    expect(inbox.whatsapp?).to be(false)
  end
end
