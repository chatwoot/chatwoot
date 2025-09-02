FactoryBot.define do
  factory :channel_whatsapp, class: 'Channel::Whatsapp' do
    sequence(:phone_number) { |n| "+123456789#{n}1" }
    account
    provider_config { { 'api_key' => 'test_key', 'phone_number_id' => 'random_id' } }
    message_templates do
      [{ 'name' => 'sample_shipping_confirmation',
         'status' => 'approved',
         'category' => 'SHIPPING_UPDATE',
         'language' => 'id',
         'namespace' => '2342384942_32423423_23423fdsdaf',
         'components' =>
                            [{ 'text' => 'Paket Anda sudah dikirim. Paket akan sampai dalam {{1}} hari kerja.', 'type' => 'BODY' },
                             { 'text' => 'Pesan ini berasal dari bisnis yang tidak terverifikasi.', 'type' => 'FOOTER' }],
         'rejected_reason' => 'NONE' },
       { 'name' => 'customer_yes_no',
         'status' => 'approved',
         'category' => 'SHIPPING_UPDATE',
         'language' => 'ar',
         'namespace' => '2342384942_32423423_23423fdsdaf23',
         'components' =>
                            [{ 'text' => 'عميلنا العزيز الرجاء الرد على هذه الرسالة بكلمة *نعم* للرد على إستفساركم من قبل خدمة العملاء.',
                               'type' => 'BODY' }],
         'rejected_reason' => 'NONE' },
       { 'name' => 'sample_shipping_confirmation',
         'status' => 'approved',
         'category' => 'SHIPPING_UPDATE',
         'language' => 'en_US',
         'namespace' => '23423423_2342423_324234234_2343224',
         'components' =>
         [{ 'text' => 'Your package has been shipped. It will be delivered in {{1}} business days.', 'type' => 'BODY' },
          { 'text' => 'This message is from an unverified business.', 'type' => 'FOOTER' }],
         'rejected_reason' => 'NONE' },
       {
         'name' => 'ticket_status_updated',
         'status' => 'APPROVED',
         'category' => 'UTILITY',
         'language' => 'en',
         'components' => [
           { 'text' => "Hello {{name}},  Your support ticket with ID: \#{{ticket_id}} has been updated by the support agent.",
             'type' => 'BODY',
             'example' => { 'body_text_named_params' => [
               { 'example' => 'John', 'param_name' => 'name' },
               { 'example' => '2332', 'param_name' => 'ticket_id' }
             ] } }
         ],
         'sub_category' => 'CUSTOM',
         'parameter_format' => 'NAMED'
       },
       {
         'name' => 'ticket_status_updated',
         'status' => 'APPROVED',
         'category' => 'UTILITY',
         'language' => 'en_US',
         'components' => [
           { 'text' => "Hello {{last_name}},  Your support ticket with ID: \#{{ticket_id}} has been updated by the support agent.",
             'type' => 'BODY',
             'example' => { 'body_text_named_params' => [
               { 'example' => 'Dale', 'param_name' => 'last_name' },
               { 'example' => '2332', 'param_name' => 'ticket_id' }
             ] } }
         ],
         'sub_category' => 'CUSTOM',
         'parameter_format' => 'NAMED'
       }]
    end
    message_templates_last_updated { Time.now.utc }

    transient do
      sync_templates { true }
      validate_provider_config { true }
    end

    before(:build) do |channel_whatsapp, options|
      # since factory already has the required message templates, we just need to bypass it getting updated
      channel_whatsapp.define_singleton_method(:sync_templates) { nil } unless options.sync_templates
      
      # For validation bypassing, we need to completely override the validation method
      unless options.validate_provider_config
        # Override the validation method directly to bypass all provider config validation
        channel_whatsapp.define_singleton_method(:validate_provider_config) { true }
        
        # Also mock the provider_config_object for any other calls
        mock_config = double('MockProviderConfig')
        allow(mock_config).to receive(:validate_config?).and_return(true)
        allow(mock_config).to receive(:cleanup_on_destroy)
        allow(mock_config).to receive(:webhook_verify_token).and_return(nil)
        allow(mock_config).to receive(:whapi_channel_id).and_return(channel_whatsapp.provider_config&.[]('whapi_channel_id'))
        allow(channel_whatsapp).to receive(:provider_config_object).and_return(mock_config)
      end
      
      if channel_whatsapp.provider == 'whatsapp_cloud'
        config = { 'api_key' => 'test_key', 'phone_number_id' => '123456789', 'business_account_id' => '123456789' }
        # Add webhook_verify_token if not already present
        config['webhook_verify_token'] = SecureRandom.hex(16) unless channel_whatsapp.provider_config&.[]('webhook_verify_token')
        channel_whatsapp.provider_config = (channel_whatsapp.provider_config || {}).merge(config)
      elsif channel_whatsapp.provider == 'whapi'
        config = { 'api_key' => 'test_key', 'phone_number_id' => 'whapi_phone_id' }
        config['whapi_channel_id'] = channel_whatsapp.provider_config&.[]('whapi_channel_id') if channel_whatsapp.provider_config&.[]('whapi_channel_id')
        config['whapi_channel_token'] = channel_whatsapp.provider_config&.[]('whapi_channel_token') if channel_whatsapp.provider_config&.[]('whapi_channel_token')
        channel_whatsapp.provider_config = (channel_whatsapp.provider_config || {}).merge(config)
      end
    end

    after(:create) do |channel_whatsapp|
      create(:inbox, channel: channel_whatsapp, account: channel_whatsapp.account)
    end
  end
end
