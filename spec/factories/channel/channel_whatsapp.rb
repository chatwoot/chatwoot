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
         'rejected_reason' => 'NONE' }]
    end
    message_templates_last_updated { Time.now.utc }

    transient do
      sync_templates { true }
      validate_provider_config { true }
    end

    before(:create) do |channel_whatsapp, options|
      # since factory already has the required message templates, we just need to bypass it getting updated
      channel_whatsapp.define_singleton_method(:sync_templates) { nil } unless options.sync_templates
      channel_whatsapp.define_singleton_method(:validate_provider_config) { nil } unless options.validate_provider_config
      if channel_whatsapp.provider == 'whatsapp_cloud'
        channel_whatsapp.provider_config = channel_whatsapp.provider_config.merge({ 'api_key' => 'test_key', 'phone_number_id' => '123456789',
                                                                                    'business_account_id' => '123456789' })
      end
    end

    after(:create) do |channel_whatsapp|
      create(:inbox, channel: channel_whatsapp, account: channel_whatsapp.account)
    end
  end
end
