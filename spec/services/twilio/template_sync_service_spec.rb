require 'rails_helper'

RSpec.describe Twilio::TemplateSyncService do
  subject(:sync_service) { described_class.new(channel: twilio_channel) }

  let!(:account) { create(:account) }
  let!(:twilio_channel) { create(:channel_twilio_sms, medium: :whatsapp, account: account) }

  let(:twilio_client) { instance_double(Twilio::REST::Client) }
  let(:content_api) { double }
  let(:contents_list) { double }

  # Mock Twilio template objects
  let(:text_template) do
    instance_double(
      Twilio::REST::Content::V1::ContentInstance,
      sid: 'HX123456789',
      friendly_name: 'hello_world',
      language: 'en',
      date_created: Time.current,
      date_updated: Time.current,
      variables: {},
      types: { 'twilio/text' => { 'body' => 'Hello World!' } }
    )
  end

  let(:media_template) do
    instance_double(
      Twilio::REST::Content::V1::ContentInstance,
      sid: 'HX987654321',
      friendly_name: 'product_showcase',
      language: 'en',
      date_created: Time.current,
      date_updated: Time.current,
      variables: { '1' => 'iPhone', '2' => '$999' },
      types: {
        'twilio/media' => {
          'body' => 'Check out {{1}} for {{2}}',
          'media' => ['https://example.com/image.jpg']
        }
      }
    )
  end

  let(:quick_reply_template) do
    instance_double(
      Twilio::REST::Content::V1::ContentInstance,
      sid: 'HX555666777',
      friendly_name: 'welcome_message',
      language: 'en_US',
      date_created: Time.current,
      date_updated: Time.current,
      variables: {},
      types: {
        'twilio/quick-reply' => {
          'body' => 'Welcome! How can we help?',
          'actions' => [
            { 'id' => 'support', 'title' => 'Support' },
            { 'id' => 'sales', 'title' => 'Sales' }
          ]
        }
      }
    )
  end

  let(:catalog_template) do
    instance_double(
      Twilio::REST::Content::V1::ContentInstance,
      sid: 'HX111222333',
      friendly_name: 'product_catalog',
      language: 'en',
      date_created: Time.current,
      date_updated: Time.current,
      variables: {},
      types: {
        'twilio/catalog' => {
          'body' => 'Check our catalog',
          'catalog_id' => 'catalog123'
        }
      }
    )
  end

  let(:call_to_action_template) do
    instance_double(
      Twilio::REST::Content::V1::ContentInstance,
      sid: 'HX444555666',
      friendly_name: 'payment_reminder',
      language: 'en',
      date_created: Time.current,
      date_updated: Time.current,
      variables: {},
      types: {
        'twilio/call-to-action' => {
          'body' => 'Hello, this is a gentle reminder regarding your RVA Astrology course fee.' \
                    '\n\n• Vignana Course: ₹3,000\n• Panditha Course: ₹6,000' \
                    '\n\nThe payment is due on {{date}}.\nKindly complete the payment at your convenience',
          'actions' => [
            { 'id' => 'make_payment', 'title' => 'Make Payment', 'url' => 'https://example.com/payment' }
          ]
        }
      }
    )
  end

  let(:templates) { [text_template, media_template, quick_reply_template, catalog_template, call_to_action_template] }

  before do
    allow(twilio_channel).to receive(:send).and_call_original
    allow(twilio_channel).to receive(:send).with(:client).and_return(twilio_client)
    allow(twilio_client).to receive(:content).and_return(content_api)
    allow(content_api).to receive(:v1).and_return(content_api)
    allow(content_api).to receive(:contents).and_return(contents_list)
    allow(contents_list).to receive(:list).with(limit: 1000).and_return(templates)
  end

  describe '#call' do
    context 'with successful sync' do
      it 'fetches templates from Twilio and updates the channel' do
        freeze_time do
          result = sync_service.call

          expect(result).to be_truthy
          expect(contents_list).to have_received(:list).with(limit: 1000)

          twilio_channel.reload
          expect(twilio_channel.content_templates).to be_present
          expect(twilio_channel.content_templates['templates']).to be_an(Array)
          expect(twilio_channel.content_templates['templates'].size).to eq(5)
          expect(twilio_channel.content_templates_last_updated).to be_within(1.second).of(Time.current)
        end
      end

      it 'correctly formats text templates' do
        sync_service.call

        twilio_channel.reload
        text_template_data = twilio_channel.content_templates['templates'].find do |t|
          t['friendly_name'] == 'hello_world'
        end

        expect(text_template_data).to include(
          'content_sid' => 'HX123456789',
          'friendly_name' => 'hello_world',
          'language' => 'en',
          'status' => 'approved',
          'template_type' => 'text',
          'media_type' => nil,
          'variables' => {},
          'category' => 'utility',
          'body' => 'Hello World!'
        )
      end

      it 'correctly formats media templates' do
        sync_service.call

        twilio_channel.reload
        media_template_data = twilio_channel.content_templates['templates'].find do |t|
          t['friendly_name'] == 'product_showcase'
        end

        expect(media_template_data).to include(
          'content_sid' => 'HX987654321',
          'friendly_name' => 'product_showcase',
          'language' => 'en',
          'status' => 'approved',
          'template_type' => 'media',
          'media_type' => nil, # Would be derived from media content if present
          'variables' => { '1' => 'iPhone', '2' => '$999' },
          'category' => 'utility',
          'body' => 'Check out {{1}} for {{2}}'
        )
      end

      it 'correctly formats quick reply templates' do
        sync_service.call

        twilio_channel.reload
        quick_reply_template_data = twilio_channel.content_templates['templates'].find do |t|
          t['friendly_name'] == 'welcome_message'
        end

        expect(quick_reply_template_data).to include(
          'content_sid' => 'HX555666777',
          'friendly_name' => 'welcome_message',
          'language' => 'en_US',
          'status' => 'approved',
          'template_type' => 'quick_reply',
          'media_type' => nil,
          'variables' => {},
          'category' => 'utility',
          'body' => 'Welcome! How can we help?'
        )
      end

      it 'correctly formats call-to-action templates with variables' do
        sync_service.call

        twilio_channel.reload
        call_to_action_data = twilio_channel.content_templates['templates'].find do |t|
          t['friendly_name'] == 'payment_reminder'
        end

        expect(call_to_action_data).to include(
          'content_sid' => 'HX444555666',
          'friendly_name' => 'payment_reminder',
          'language' => 'en',
          'status' => 'approved',
          'template_type' => 'call_to_action',
          'media_type' => nil,
          'variables' => {},
          'category' => 'utility'
        )

        expected_body = 'Hello, this is a gentle reminder regarding your RVA Astrology course fee.' \
                        '\n\n• Vignana Course: ₹3,000\n• Panditha Course: ₹6,000' \
                        '\n\nThe payment is due on {{date}}.\nKindly complete the payment at your convenience'
        expect(call_to_action_data['body']).to eq(expected_body)
        expect(call_to_action_data['body']).to match(/{{date}}/)
      end

      it 'categorizes marketing templates correctly' do
        marketing_template = instance_double(
          Twilio::REST::Content::V1::ContentInstance,
          sid: 'HX_MARKETING',
          friendly_name: 'promo_offer_50_off',
          language: 'en',
          date_created: Time.current,
          date_updated: Time.current,
          variables: {},
          types: { 'twilio/text' => { 'body' => '50% off sale!' } }
        )

        allow(contents_list).to receive(:list).with(limit: 1000).and_return([marketing_template])

        sync_service.call

        twilio_channel.reload
        marketing_data = twilio_channel.content_templates['templates'].first

        expect(marketing_data['category']).to eq('marketing')
      end

      it 'categorizes authentication templates correctly' do
        auth_template = instance_double(
          Twilio::REST::Content::V1::ContentInstance,
          sid: 'HX_AUTH',
          friendly_name: 'otp_verification',
          language: 'en',
          date_created: Time.current,
          date_updated: Time.current,
          variables: {},
          types: { 'twilio/text' => { 'body' => 'Your OTP is {{1}}' } }
        )

        allow(contents_list).to receive(:list).with(limit: 1000).and_return([auth_template])

        sync_service.call

        twilio_channel.reload
        auth_data = twilio_channel.content_templates['templates'].first

        expect(auth_data['category']).to eq('authentication')
      end
    end

    context 'with API error' do
      before do
        allow(contents_list).to receive(:list).and_raise(Twilio::REST::TwilioError.new('API Error'))
        allow(Rails.logger).to receive(:error)
      end

      it 'handles Twilio::REST::TwilioError gracefully' do
        result = sync_service.call

        expect(result).to be_falsey
        expect(Rails.logger).to have_received(:error).with('Twilio template sync failed: API Error')
      end
    end

    context 'with generic error' do
      before do
        allow(contents_list).to receive(:list).and_raise(StandardError, 'Connection failed')
        allow(Rails.logger).to receive(:error)
      end

      it 'propagates non-Twilio errors' do
        expect { sync_service.call }.to raise_error(StandardError, 'Connection failed')
      end
    end

    context 'with empty templates list' do
      before do
        allow(contents_list).to receive(:list).with(limit: 1000).and_return([])
      end

      it 'updates channel with empty templates array' do
        sync_service.call

        twilio_channel.reload
        expect(twilio_channel.content_templates['templates']).to eq([])
        expect(twilio_channel.content_templates_last_updated).to be_present
      end
    end
  end

  describe 'template categorization behavior' do
    it 'defaults to utility category for unrecognized patterns' do
      generic_template = instance_double(
        Twilio::REST::Content::V1::ContentInstance,
        sid: 'HX_GENERIC',
        friendly_name: 'order_status',
        language: 'en',
        date_created: Time.current,
        date_updated: Time.current,
        variables: {},
        types: { 'twilio/text' => { 'body' => 'Order updated' } }
      )

      allow(contents_list).to receive(:list).with(limit: 1000).and_return([generic_template])

      sync_service.call

      twilio_channel.reload
      template_data = twilio_channel.content_templates['templates'].first

      expect(template_data['category']).to eq('utility')
    end
  end

  describe 'template type detection' do
    context 'with multiple type definitions' do
      let(:mixed_template) do
        instance_double(
          Twilio::REST::Content::V1::ContentInstance,
          sid: 'HX_MIXED',
          friendly_name: 'mixed_type',
          language: 'en',
          date_created: Time.current,
          date_updated: Time.current,
          variables: {},
          types: {
            'twilio/media' => { 'body' => 'Media content' },
            'twilio/text' => { 'body' => 'Text content' }
          }
        )
      end

      before do
        allow(contents_list).to receive(:list).with(limit: 1000).and_return([mixed_template])
      end

      it 'prioritizes media type for type detection but text for body extraction' do
        sync_service.call

        twilio_channel.reload
        template_data = twilio_channel.content_templates['templates'].first

        # derive_template_type prioritizes media
        expect(template_data['template_type']).to eq('media')
        # but extract_body_content prioritizes text
        expect(template_data['body']).to eq('Text content')
      end
    end
  end
end
