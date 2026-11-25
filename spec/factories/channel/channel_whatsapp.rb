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
         'namespace' => '23423423_2342423_324234234_2343224',
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
       },
       {
         'name' => 'test_no_params_template',
         'status' => 'APPROVED',
         'category' => 'UTILITY',
         'language' => 'en',
         'namespace' => 'ed41a221_133a_4558_a1d6_192960e3aee9',
         'id' => '9876543210987654',
         'length' => 1,
         'parameter_format' => 'POSITIONAL',
         'previous_category' => 'MARKETING',
         'sub_category' => 'CUSTOM',
         'components' => [
           {
             'text' => 'Thank you for contacting us! Your request has been processed successfully. Have a great day! 🙂',
             'type' => 'BODY'
           }
         ],
         'rejected_reason' => 'NONE'
       }]
    end
    message_templates_last_updated { Time.now.utc }

    transient do
      sync_templates { true }
      validate_provider_config { true }
      received_messages { true }
      session_provider_enabled { true }
    end

    # Both session providers are on offer to an account nobody has touched, so a channel on
    # either needs no setup to be valid; `session_provider_enabled: false` withdraws the
    # provider from the account, which is what the examples about that gate pass.
    after(:build) do |channel_whatsapp, options|
      account = channel_whatsapp.account
      next if options.session_provider_enabled
      next unless account && channel_whatsapp.provider.in?(Whatsapp::Session::PROVIDERS)

      account.update!("whatsapp_#{channel_whatsapp.provider}_disabled" => true)
    end

    before(:create) do |channel_whatsapp, options|
      # since factory already has the required message templates, we just need to bypass it getting updated
      channel_whatsapp.define_singleton_method(:sync_templates) { nil } unless options.sync_templates
      channel_whatsapp.define_singleton_method(:validate_provider_config) { nil } unless options.validate_provider_config
      channel_whatsapp.define_singleton_method(:received_messages) { |_, _| nil } unless options.received_messages
      if channel_whatsapp.provider == 'baileys'
        channel_whatsapp.provider_config = channel_whatsapp.provider_config.merge({ 'api_key' => 'test_key', 'provider_url' => 'https://baileys.api',
                                                                                    'phone_number_id' => '123456789', 'mark_as_read' => true })
      elsif channel_whatsapp.provider.in?(Whatsapp::Session::PROVIDERS)
        # Session providers carry their own config; the cloud defaults above are noise for them.
        defaults = { 'mark_as_read' => true }
        if channel_whatsapp.provider == 'uazapi'
          defaults['base_url'] = 'https://uazapi.test'
          defaults['token'] = 'test_token'
        end
        channel_whatsapp.provider_config = defaults.merge(channel_whatsapp.provider_config.except('api_key', 'phone_number_id'))
      elsif channel_whatsapp.provider == 'whatsapp_cloud'
        # Add 'source' => 'embedded_signup' to skip after_commit :setup_webhooks callback in tests
        # The callback is for manual setup flow; embedded signup handles webhook setup explicitly
        # Only set source if not already provided (allows tests to override)
        default_config = {
          'api_key' => 'test_key',
          'phone_number_id' => '123456789',
          'business_account_id' => '123456789'
        }
        default_config['source'] = 'embedded_signup' unless channel_whatsapp.provider_config.key?('source')
        # A manual inbox is created with its Meta app's secret (Channel::Whatsapp#app_secret_required?).
        manual = (default_config['source'] || channel_whatsapp.provider_config['source']) != 'embedded_signup'
        default_config['app_secret'] = 'test_app_secret' if manual && !channel_whatsapp.provider_config.key?('app_secret')
        channel_whatsapp.provider_config = channel_whatsapp.provider_config.merge(default_config)
      end
    end

    after(:create) do |channel_whatsapp|
      create(:inbox, channel: channel_whatsapp, account: channel_whatsapp.account)
    end
  end
end
