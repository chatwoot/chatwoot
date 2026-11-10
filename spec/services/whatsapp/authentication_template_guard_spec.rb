require 'rails_helper'

RSpec.describe Whatsapp::AuthenticationTemplateGuard do
  let(:account) { create(:account) }
  let(:authentication_template) do
    {
      'name' => 'login_code',
      'language' => 'en_US',
      'category' => 'AUTHENTICATION'
    }
  end
  let(:template_params) { { 'name' => 'login_code', 'language' => 'en_US' } }

  it 'rejects a Meta authentication template for a BSUID recipient' do
    channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account,
                                        validate_provider_config: false, sync_templates: false)
    channel.update!(message_templates: [authentication_template])

    error = described_class.new(channel: channel, recipient: 'IN.2081978709342942', template_params: template_params).error

    expect(error).to eq(I18n.t('errors.whatsapp.authentication_template_requires_phone'))
  end

  it 'rejects a BSUID recipient when only the saved template params carry a category' do
    channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account,
                                        validate_provider_config: false, sync_templates: false)
    template_params = { 'name' => 'login_code', 'language' => 'en_US', 'category' => 'AUTHENTICATION' }

    error = described_class.new(channel: channel, recipient: 'IN.2081978709342942', template_params: template_params).error

    expect(error).to eq(I18n.t('errors.whatsapp.template_category_required_for_bsuid'))
  end

  it 'allows an authentication template for a phone recipient' do
    channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account,
                                        validate_provider_config: false, sync_templates: false)
    channel.update!(message_templates: [authentication_template])

    expect(described_class.new(channel: channel, recipient: '919745786257', template_params: template_params).error).to be_nil
  end

  it 'allows a non-authentication template for a BSUID recipient' do
    channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account,
                                        validate_provider_config: false, sync_templates: false)
    channel.update!(message_templates: [authentication_template.merge('category' => 'UTILITY')])

    expect(described_class.new(channel: channel, recipient: 'IN.2081978709342942', template_params: template_params).error).to be_nil
  end

  it 'rejects a BSUID recipient when template category cannot be verified' do
    channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account,
                                        validate_provider_config: false, sync_templates: false)

    error = described_class.new(channel: channel, recipient: 'IN.2081978709342942', template_params: template_params).error

    expect(error).to eq(I18n.t('errors.whatsapp.template_category_required_for_bsuid'))
  end
end
