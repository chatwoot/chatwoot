# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LeadFollowUpSequence do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to have_many(:conversation_follow_ups).dependent(:destroy) }
  end

  describe 'validations' do
    let(:account) { create(:account) }
    let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
    let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:inbox) }

    context 'when inbox is not WhatsApp' do
      let(:website_channel) { create(:channel_widget, account: account) }
      let(:website_inbox) { create(:inbox, channel: website_channel, account: account) }
      let(:sequence) { build(:lead_follow_up_sequence, account: account, inbox: website_inbox) }

      it 'adds error for non-WhatsApp inbox' do
        expect(sequence.valid?).to be false
        expect(sequence.errors[:inbox]).to include('must be a WhatsApp inbox')
      end
    end

    context 'when steps is not an array' do
      let(:sequence) do
        build(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox,
                                        steps: 'not an array')
      end

      it 'adds error' do
        expect(sequence.valid?).to be false
        expect(sequence.errors[:steps]).to include('must be an array')
      end
    end

    context 'when step has invalid type' do
      let(:sequence) do
        build(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox,
                                        steps: [{ 'id' => '1', 'type' => 'invalid_type', 'enabled' => true }])
      end

      it 'adds error' do
        expect(sequence.valid?).to be false
        expect(sequence.errors[:steps]).to include('step at index 0 has invalid type: invalid_type')
      end
    end

    context 'when wait step has invalid config' do
      let(:sequence) do
        build(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox,
                                        steps: [{
                                          'id' => '1',
                                          'type' => 'wait',
                                          'enabled' => true,
                                          'config' => { 'delay_value' => 0, 'delay_type' => 'invalid' }
                                        }])
      end

      it 'adds errors for invalid delay config' do
        expect(sequence.valid?).to be false
        expect(sequence.errors[:steps]).to include('wait step at index 0 must have delay_value > 0')
        expect(sequence.errors[:steps]).to include('wait step at index 0 must have delay_type: minutes, hours, or days')
      end
    end

    context 'when template step has missing config' do
      let(:sequence) do
        build(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox,
                                        steps: [{
                                          'id' => '1',
                                          'type' => 'send_template',
                                          'enabled' => true,
                                          'config' => {}
                                        }])
      end

      it 'adds errors for missing template config' do
        expect(sequence.valid?).to be false
        expect(sequence.errors[:steps]).to include('template step at index 0 must have template_name')
        expect(sequence.errors[:steps]).to include('template step at index 0 must have language')
      end
    end
  end

  describe 'scopes' do
    let(:account) { create(:account) }
    let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
    let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
    let!(:active_sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox, active: true) }
    let!(:inactive_sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox, active: false) }

    describe '.active' do
      it 'returns only active sequences' do
        expect(described_class.active).to include(active_sequence)
        expect(described_class.active).not_to include(inactive_sequence)
      end
    end
  end

  describe '#activate!' do
    let(:account) { create(:account) }
    let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
    let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
    let(:sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox, active: false) }

    it 'sets active to true' do
      sequence.activate!
      expect(sequence.reload.active).to be true
    end
  end

  describe '#deactivate!' do
    let(:account) { create(:account) }
    let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
    let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
    let(:sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox, active: true) }
    let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox) }
    let!(:active_follow_up) do
      create(:conversation_follow_up, conversation: conversation,
                                      lead_follow_up_sequence: sequence, status: 'active')
    end
    let!(:completed_follow_up) do
      create(:conversation_follow_up, conversation: create(:conversation, account: account, inbox: whatsapp_inbox),
                                      lead_follow_up_sequence: sequence, status: 'completed')
    end

    it 'sets active to false' do
      sequence.deactivate!
      expect(sequence.reload.active).to be false
    end

    it 'cancels all active follow-ups' do
      sequence.deactivate!
      expect(active_follow_up.reload.status).to eq('cancelled')
    end

    it 'does not affect completed follow-ups' do
      sequence.deactivate!
      expect(completed_follow_up.reload.status).to eq('completed')
    end
  end

  describe '#step_by_id' do
    let(:account) { create(:account) }
    let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
    let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
    let(:sequence) do
      create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox,
                                       steps: [
                                         { 'id' => 'step_1', 'type' => 'wait', 'enabled' => true },
                                         { 'id' => 'step_2', 'type' => 'send_template', 'enabled' => true }
                                       ])
    end

    it 'returns step by id' do
      step = sequence.step_by_id('step_1')
      expect(step).to eq({ 'id' => 'step_1', 'type' => 'wait', 'enabled' => true })
    end

    it 'returns nil for non-existent step' do
      step = sequence.step_by_id('non_existent')
      expect(step).to be_nil
    end
  end

  describe '#enabled_steps' do
    let(:account) { create(:account) }
    let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
    let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
    let(:sequence) do
      create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox,
                                       steps: [
                                         { 'id' => 'step_1', 'type' => 'wait', 'enabled' => true },
                                         { 'id' => 'step_2', 'type' => 'send_template', 'enabled' => false },
                                         { 'id' => 'step_3', 'type' => 'add_label', 'enabled' => true }
                                       ])
    end

    it 'returns only enabled steps' do
      enabled = sequence.enabled_steps
      expect(enabled.length).to eq(2)
      expect(enabled.map { |s| s['id'] }).to eq(%w[step_1 step_3])
    end
  end

  describe '#render_param_value' do
    let(:account) { create(:account) }
    let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
    let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
    let(:sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox) }
    let(:contact) { create(:contact, account: account, name: 'John Doe', phone_number: '+1234567890') }
    let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox, contact: contact) }
    let(:context) do
      {
        contact: contact,
        conversation: conversation,
        account: account,
        inbox: whatsapp_inbox
      }
    end

    it 'renders contact variables' do
      result = sequence.render_param_value('Hello {{contact.name}}', context)
      expect(result).to eq('Hello John Doe')
    end

    it 'renders conversation variables' do
      result = sequence.render_param_value('Conversation #{{conversation.display_id}}', context)
      expect(result).to eq("Conversation ##{conversation.display_id}")
    end

    it 'renders account variables' do
      result = sequence.render_param_value('Account: {{account.name}}', context)
      expect(result).to eq("Account: #{account.name}")
    end

    it 'renders multiple variables' do
      result = sequence.render_param_value('Hi {{contact.name}}, your phone is {{contact.phone_number}}', context)
      expect(result).to eq('Hi John Doe, your phone is +1234567890')
    end

    it 'handles unknown variables gracefully' do
      result = sequence.render_param_value('Value: {{unknown.variable}}', context)
      expect(result).to eq('Value: [Unknown variable: unknown.variable]')
    end

    it 'renders custom attributes' do
      contact.update!(custom_attributes: { 'city' => 'New York' })
      result = sequence.render_param_value('City: {{custom_attr.city}}', context)
      expect(result).to eq('City: New York')
    end
  end
end
