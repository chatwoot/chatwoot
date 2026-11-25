require 'rails_helper'

RSpec.describe DataImports::Freshdesk::SourceBucket do
  describe '.source_type' do
    it 'maps documented and observed Freshdesk source identifiers', :aggregate_failures do
      expect(described_class.source_type(1)).to eq('email')
      expect(described_class.source_type(7)).to eq('chat')
      expect(described_class.source_type(8)).to eq('mobihelp')
      expect(described_class.source_type(11)).to eq('ecommerce')
      expect(described_class.source_type(12)).to eq('bot')
      expect(described_class.source_type(13)).to eq('whatsapp')
      expect(described_class.source_type(14)).to eq('chat_internal_task')
      expect(described_class.source_type(15)).to eq('web_chat')
      expect(described_class.source_type(16)).to eq('web_form')
      expect(described_class.source_type(17)).to eq('instagram_message')
      expect(described_class.source_type(18)).to eq('instagram_comment')
      expect(described_class.source_type(19)).to eq('facebook_message')
      expect(described_class.source_type(20)).to eq('facebook_comment')
      expect(described_class.source_type(21)).to eq('mobile_chat_sdk')
      expect(described_class.source_type(22)).to eq('sms')
    end

    it 'uses unknown for an unsupported source identifier' do
      expect(described_class.source_type(999)).to eq('unknown')
    end
  end

  describe '.for' do
    it 'groups equivalent sources and preserves distinct modern channels', :aggregate_failures do
      expect(described_class.for('email')).to eq({ key: 'email', name: 'Email' })
      expect(described_class.for('outbound_email')).to eq({ key: 'email', name: 'Email' })
      expect(described_class.for('feedback_widget')).to eq({ key: 'portal', name: 'Portal' })
      expect(described_class.for('whatsapp')).to eq({ key: 'whatsapp', name: 'WhatsApp' })
      expect(described_class.for('chat_internal_task')).to eq({ key: 'internal_task', name: 'Internal task' })
      expect(described_class.for('web_chat')).to eq({ key: 'chat', name: 'Chat' })
      expect(described_class.for('web_form')).to eq({ key: 'portal', name: 'Portal' })
      expect(described_class.for('instagram_message')).to eq({ key: 'instagram', name: 'Instagram' })
      expect(described_class.for('instagram_comment')).to eq({ key: 'instagram', name: 'Instagram' })
      expect(described_class.for('facebook_message')).to eq({ key: 'facebook', name: 'Facebook' })
      expect(described_class.for('facebook_comment')).to eq({ key: 'facebook', name: 'Facebook' })
      expect(described_class.for('mobile_chat_sdk')).to eq({ key: 'mobile', name: 'Mobile' })
      expect(described_class.for('sms')).to eq({ key: 'sms', name: 'SMS' })
    end
  end
end
