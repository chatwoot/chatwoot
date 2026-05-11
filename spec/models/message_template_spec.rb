# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MessageTemplate do
  after do
    Current.user = nil
    Current.account = nil
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to belong_to(:created_by).class_name('User').optional }
    it { is_expected.to belong_to(:updated_by).class_name('User').optional }
  end

  describe '.validate name attributes' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:message_template) do
      build(:message_template, account: account, inbox: inbox)
    end

    it 'validates minimum length of name' do
      message_template.name = 'a'
      message_template.valid?
      expect(message_template.errors[:name]).to include('is too short (minimum is 2 characters)')
    end

    it 'validates maximum length of name' do
      message_template.name = 'a' * 513
      message_template.valid?
      expect(message_template.errors[:name]).to include('is too long (maximum is 512 characters)')
    end

    it 'validates format of name' do
      invalid_names = ['template name', 'template-name', 'template.name', 'template@name']
      invalid_names.each do |invalid_name|
        message_template.name = invalid_name
        message_template.valid?
        expect(message_template.errors[:name]).to include('is invalid')
      end
    end

    it 'accepts valid name formats' do
      valid_names = %w[template_name Template123 TEMPLATE_NAME_123 template123]
      valid_names.each do |valid_name|
        message_template.name = valid_name
        message_template.valid?
        expect(message_template.errors[:name]).to be_empty
      end
    end
  end

  describe '.validate custom validations' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }

    context 'when inbox does not belong to account' do
      let(:other_account) { create(:account) }
      let(:other_inbox) { create(:inbox, account: other_account) }
      let(:message_template) do
        build(:message_template, account: account, inbox: other_inbox)
      end

      it 'adds error when inbox belongs to different account' do
        message_template.valid?
        expect(message_template.errors[:inbox_id]).to include('does not belong to this account')
      end
    end

    context 'when template name already exists' do
      let!(:existing_template) do
        create(:message_template,
               account: account,
               inbox: inbox,
               name: 'existing_template',
               language: 'en')
      end

      it 'adds error for duplicate name in same language and inbox' do
        new_template = build(:message_template,
                             account: account,
                             inbox: inbox,
                             name: 'existing_template',
                             language: 'en')
        new_template.valid?
        expect(new_template.errors[:name]).to include('already exists for this language and inbox')
      end

      it 'allows same name with different language' do
        new_template = build(:message_template,
                             account: account,
                             inbox: inbox,
                             name: 'existing_template',
                             language: 'es')
        new_template.valid?
        expect(new_template.errors[:name]).to be_empty
      end

      it 'allows same name with different inbox' do
        other_inbox = create(:inbox, account: account)
        new_template = build(:message_template,
                             account: account,
                             inbox: other_inbox,
                             name: 'existing_template',
                             language: 'en')
        new_template.valid?
        expect(new_template.errors[:name]).to be_empty
      end

      it 'allows updating existing template with same name' do
        existing_template.name = 'existing_template'
        expect(existing_template.valid?).to be(true)
      end
    end
  end

  describe '.before_save' do
    let(:account) { create(:account) }
    let(:user) { create(:user, account: account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:message_template) do
      create(:message_template, account: account, inbox: inbox)
    end

    before do
      Current.user = user
    end

    it 'runs before_save callbacks' do
      message_template.update(name: 'updated_template')
      expect(message_template.reload.updated_by).to eq(user)
    end
  end

  describe '.before_create' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:template_service) { instance_double(Whatsapp::TemplateCreationService) }

    before do
      allow(Whatsapp::TemplateCreationService).to receive(:new).and_return(template_service)
    end

    context 'when channel_type is Channel::Whatsapp' do
      let(:message_template) do
        build(:message_template,
              account: account,
              inbox: inbox,
              channel_type: 'Channel::Whatsapp',
              platform_template_id: nil)
      end

      it 'calls WhatsApp template creation service' do
        allow(template_service).to receive(:call).and_return(true)

        message_template.save!

        expect(Whatsapp::TemplateCreationService).to have_received(:new)
          .with(message_template: message_template)
        expect(template_service).to have_received(:call)
      end

      it 'aborts creation if service returns false' do
        allow(template_service).to receive(:call).and_return(false)

        expect { message_template.save! }.to raise_error(ActiveRecord::RecordNotSaved)
      end
    end

    context 'when platform_template_id is present' do
      let(:message_template) do
        build(:message_template,
              account: account,
              inbox: inbox,
              channel_type: 'Channel::Whatsapp',
              platform_template_id: 'template_123')
      end

      it 'does not call template creation service' do
        message_template.save!

        expect(Whatsapp::TemplateCreationService).not_to have_received(:new)
      end
    end
  end

  describe '#whatsapp_template?' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }

    context 'when channel_type is Channel::Whatsapp' do
      let(:message_template) do
        build(:message_template,
              account: account,
              inbox: inbox,
              channel_type: 'Channel::Whatsapp')
      end

      it 'returns true' do
        expect(message_template.whatsapp_template?).to be(true)
      end
    end

    context 'when channel_type is not Channel::Whatsapp' do
      let(:message_template) do
        build(:message_template,
              account: account,
              inbox: inbox,
              channel_type: 'Channel::Sms')
      end

      it 'returns false' do
        expect(message_template.whatsapp_template?).to be(false)
      end
    end
  end
end
