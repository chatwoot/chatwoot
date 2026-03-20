require 'rails_helper'

RSpec.describe Whatsapp::CsatTemplateService do
  let(:account) { create(:account) }
  let(:whatsapp_channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
  end
  let(:inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
  let(:service) { described_class.new(whatsapp_channel) }

  let(:expected_template_name) { "customer_satisfaction_survey_#{whatsapp_channel.inbox.id}" }
  let(:template_config) do
    {
      message: 'How would you rate your experience?',
      button_text: 'Rate Us',
      language: 'en',
      base_url: 'https://example.com',
      template_name: expected_template_name
    }
  end

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('WHATSAPP_CLOUD_BASE_URL', anything).and_return('https://graph.facebook.com')
  end

  describe '#generate_template_name' do
    context 'when no existing template' do
      it 'returns base name as-is' do
        whatsapp_channel.inbox.update!(csat_config: {})
        result = service.send(:generate_template_name, 'new_template_name')
        expect(result).to eq('new_template_name')
      end

      it 'returns base name when template key is missing' do
        whatsapp_channel.inbox.update!(csat_config: { 'other_config' => 'value' })
        result = service.send(:generate_template_name, 'new_template_name')
        expect(result).to eq('new_template_name')
      end
    end

    context 'when existing template has no versioned name' do
      it 'starts versioning from 1' do
        whatsapp_channel.inbox.update!(csat_config: {
                                         'template' => { 'name' => expected_template_name }
                                       })
        result = service.send(:generate_template_name, 'new_template_name')
        expect(result).to eq("#{expected_template_name}_1")
      end

      it 'starts versioning from 1 for custom name' do
        whatsapp_channel.inbox.update!(csat_config: {
                                         'template' => { 'name' => 'custom_survey' }
                                       })
        result = service.send(:generate_template_name, 'new_template_name')
        expect(result).to eq("#{expected_template_name}_1")
      end
    end

    context 'when existing template has versioned name' do
      it 'increments version number' do
        whatsapp_channel.inbox.update!(csat_config: {
                                         'template' => { 'name' => "#{expected_template_name}_1" }
                                       })
        result = service.send(:generate_template_name, 'new_template_name')
        expect(result).to eq("#{expected_template_name}_2")
      end

      it 'increments higher version numbers' do
        whatsapp_channel.inbox.update!(csat_config: {
                                         'template' => { 'name' => "#{expected_template_name}_5" }
                                       })
        result = service.send(:generate_template_name, 'new_template_name')
        expect(result).to eq("#{expected_template_name}_6")
      end

      it 'handles double digit version numbers' do
        whatsapp_channel.inbox.update!(csat_config: {
                                         'template' => { 'name' => "#{expected_template_name}_12" }
                                       })
        result = service.send(:generate_template_name, 'new_template_name')
        expect(result).to eq("#{expected_template_name}_13")
      end
    end

    context 'when existing template has non-matching versioned name' do
      it 'starts versioning from 1' do
        whatsapp_channel.inbox.update!(csat_config: {
                                         'template' => { 'name' => 'different_survey_3' }
                                       })
        result = service.send(:generate_template_name, 'new_template_name')
        expect(result).to eq("#{expected_template_name}_1")
      end
    end

    context 'when template name is blank' do
      it 'returns base name' do
        whatsapp_channel.inbox.update!(csat_config: {
                                         'template' => { 'name' => '' }
                                       })
        result = service.send(:generate_template_name, 'new_template_name')
        expect(result).to eq('new_template_name')
      end

      it 'returns base name when template name is nil' do
        whatsapp_channel.inbox.update!(csat_config: {
                                         'template' => { 'name' => nil }
                                       })
        result = service.send(:generate_template_name, 'new_template_name')
        expect(result).to eq('new_template_name')
      end
    end
  end

  describe '#build_template_request_body' do
    it 'builds correct request structure' do
      result = service.send(:build_template_request_body, template_config)

      expect(result).to eq({
                             name: expected_template_name,
                             language: 'en',
                             category: 'UTILITY',
                             components: [
                               {
                                 type: 'BODY',
                                 text: 'How would you rate your experience?'
                               },
                               {
                                 type: 'BUTTONS',
                                 buttons: [
                                   {
                                     type: 'URL',
                                     text: 'Rate Us',
                                     url: 'https://example.com/survey/responses/{{1}}',
                                     example: ['12345']
                                   }
                                 ]
                               }
                             ]
                           })
    end

    it 'uses default language when not provided' do
      config_without_language = template_config.except(:language)
      result = service.send(:build_template_request_body, config_without_language)
      expect(result[:language]).to eq('en')
    end

    it 'uses default button text when not provided' do
      config_without_button = template_config.except(:button_text)
      result = service.send(:build_template_request_body, config_without_button)
      expect(result[:components][1][:buttons][0][:text]).to eq('Please rate us')
    end
  end

  describe '#create_template' do
    let(:mock_response) do
      # rubocop:disable RSpec/VerifiedDoubles
      double('response', :success? => true, :body => '{}', '[]' => { 'id' => '123', 'name' => 'template_name' })
      # rubocop:enable RSpec/VerifiedDoubles
    end

    before do
      allow(HTTParty).to receive(:post).and_return(mock_response)
      inbox.update!(csat_config: {})
    end

    it 'creates template with generated name' do
      expected_body = {
        name: expected_template_name,
        language: 'en',
        category: 'UTILITY',
        components: [
          {
            type: 'BODY',
            text: 'How would you rate your experience?'
          },
          {
            type: 'BUTTONS',
            buttons: [
              {
                type: 'URL',
                text: 'Rate Us',
                url: 'https://example.com/survey/responses/{{1}}',
                example: ['12345']
              }
            ]
          }
        ]
      }

      expect(HTTParty).to receive(:post).with(
        "https://graph.facebook.com/v14.0/#{whatsapp_channel.provider_config['business_account_id']}/message_templates",
        headers: {
          'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}",
          'Content-Type' => 'application/json'
        },
        body: expected_body.to_json
      )

      service.create_template(template_config)
    end

    it 'returns success response on successful creation' do
      allow(mock_response).to receive(:[]).with('id').and_return('template_123')
      allow(mock_response).to receive(:[]).with('name').and_return(expected_template_name)

      result = service.create_template(template_config)

      expect(result).to eq({
                             success: true,
                             template_id: 'template_123',
                             template_name: expected_template_name,
                             language: 'en',
                             status: 'PENDING'
                           })
    end

    context 'when API call fails' do
      let(:error_response) do
        # rubocop:disable RSpec/VerifiedDoubles
        double('response', success?: false, code: 400, body: '{"error": "Invalid template"}')
        # rubocop:enable RSpec/VerifiedDoubles
      end

      before do
        allow(HTTParty).to receive(:post).and_return(error_response)
        allow(Rails.logger).to receive(:error)
      end

      it 'returns error response' do
        result = service.create_template(template_config)

        expect(result).to eq({
                               success: false,
                               error: 'Template creation failed',
                               response_body: '{"error": "Invalid template"}'
                             })
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with('WhatsApp template creation failed: 400 - {"error": "Invalid template"}')
        service.create_template(template_config)
      end
    end
  end

  describe '#delete_template' do
    it 'makes DELETE request to correct endpoint' do
      # rubocop:disable RSpec/VerifiedDoubles
      mock_response = double('response', success?: true, body: '{}')
      # rubocop:enable RSpec/VerifiedDoubles

      expect(HTTParty).to receive(:delete).with(
        "https://graph.facebook.com/v14.0/#{whatsapp_channel.provider_config['business_account_id']}/message_templates?name=test_template",
        headers: {
          'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}",
          'Content-Type' => 'application/json'
        }
      ).and_return(mock_response)

      result = service.delete_template('test_template')
      expect(result).to eq({ success: true, response_body: '{}' })
    end

    it 'uses default template name when none provided' do
      # rubocop:disable RSpec/VerifiedDoubles
      mock_response = double('response', success?: true, body: '{}')
      # rubocop:enable RSpec/VerifiedDoubles

      expect(HTTParty).to receive(:delete).with(
        "https://graph.facebook.com/v14.0/#{whatsapp_channel.provider_config['business_account_id']}/message_templates?name=#{expected_template_name}",
        anything
      ).and_return(mock_response)

      service.delete_template
    end

    it 'returns failure response when API call fails' do
      # rubocop:disable RSpec/VerifiedDoubles
      mock_response = double('response', success?: false, body: '{"error": "Template not found"}')
      # rubocop:enable RSpec/VerifiedDoubles
      allow(HTTParty).to receive(:delete).and_return(mock_response)

      result = service.delete_template('test_template')
      expect(result).to eq({ success: false, response_body: '{"error": "Template not found"}' })
    end
  end

  describe '#get_template_status' do
    it 'makes GET request to correct endpoint' do
      # rubocop:disable RSpec/VerifiedDoubles
      mock_response = double('response', success?: true, body: '{}')
      # rubocop:enable RSpec/VerifiedDoubles
      allow(mock_response).to receive(:[]).with('data').and_return([{
                                                                     'id' => '123',
                                                                     'name' => 'test_template',
                                                                     'status' => 'APPROVED',
                                                                     'language' => 'en'
                                                                   }])

      expect(HTTParty).to receive(:get).with(
        "https://graph.facebook.com/v14.0/#{whatsapp_channel.provider_config['business_account_id']}/message_templates?name=test_template",
        headers: {
          'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}",
          'Content-Type' => 'application/json'
        }
      ).and_return(mock_response)

      service.get_template_status('test_template')
    end

    it 'returns success response when template exists' do
      # rubocop:disable RSpec/VerifiedDoubles
      mock_response = double('response', success?: true, body: '{}')
      # rubocop:enable RSpec/VerifiedDoubles
      allow(mock_response).to receive(:[]).with('data').and_return([{
                                                                     'id' => '123',
                                                                     'name' => 'test_template',
                                                                     'status' => 'APPROVED',
                                                                     'language' => 'en'
                                                                   }])
      allow(HTTParty).to receive(:get).and_return(mock_response)

      result = service.get_template_status('test_template')

      expect(result).to eq({
                             success: true,
                             template: {
                               id: '123',
                               name: 'test_template',
                               status: 'APPROVED',
                               language: 'en'
                             }
                           })
    end

    it 'returns failure response when template not found' do
      # rubocop:disable RSpec/VerifiedDoubles
      mock_response = double('response', success?: true, body: '{}')
      # rubocop:enable RSpec/VerifiedDoubles
      allow(mock_response).to receive(:[]).with('data').and_return([])
      allow(HTTParty).to receive(:get).and_return(mock_response)

      result = service.get_template_status('test_template')
      expect(result).to eq({ success: false, error: 'Template not found' })
    end

    it 'returns failure response when API call fails' do
      # rubocop:disable RSpec/VerifiedDoubles
      mock_response = double('response', success?: false, body: '{}')
      # rubocop:enable RSpec/VerifiedDoubles
      allow(HTTParty).to receive(:get).and_return(mock_response)

      result = service.get_template_status('test_template')
      expect(result).to eq({ success: false, error: 'Template not found' })
    end

    context 'when API raises an exception' do
      before do
        allow(HTTParty).to receive(:get).and_raise(StandardError, 'Network error')
        allow(Rails.logger).to receive(:error)
      end

      it 'handles exceptions gracefully' do
        result = service.get_template_status('test_template')
        expect(result).to eq({ success: false, error: 'Network error' })
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with('Error fetching template status: Network error')
        service.get_template_status('test_template')
      end
    end
  end

  describe '#valid_csat_template?' do
    it 'returns true for a template with URL button containing {{1}}' do
      template = {
        'components' => [
          { 'type' => 'BODY', 'text' => 'How was your experience?' },
          {
            'type' => 'BUTTONS',
            'buttons' => [
              { 'type' => 'URL', 'text' => 'Rate us', 'url' => 'https://example.com/survey/{{1}}' }
            ]
          }
        ]
      }

      expect(service.valid_csat_template?(template)).to be true
    end

    it 'returns false for a template without BUTTONS component' do
      template = {
        'components' => [
          { 'type' => 'BODY', 'text' => 'No buttons here' }
        ]
      }

      expect(service.valid_csat_template?(template)).to be false
    end

    it 'returns false for a template without URL button' do
      template = {
        'components' => [
          {
            'type' => 'BUTTONS',
            'buttons' => [
              { 'type' => 'QUICK_REPLY', 'text' => 'Yes' }
            ]
          }
        ]
      }

      expect(service.valid_csat_template?(template)).to be false
    end

    it 'returns false for a URL button without {{1}} parameter' do
      template = {
        'components' => [
          {
            'type' => 'BUTTONS',
            'buttons' => [
              { 'type' => 'URL', 'text' => 'Visit', 'url' => 'https://example.com/static' }
            ]
          }
        ]
      }

      expect(service.valid_csat_template?(template)).to be false
    end

    it 'returns false when components are nil' do
      template = { 'components' => nil }
      expect(service.valid_csat_template?(template)).to be false
    end
  end

  describe '#available_csat_templates' do
    it 'returns approved templates with valid CSAT structure' do
      valid_template = {
        'name' => 'survey_1',
        'status' => 'approved',
        'language' => 'en',
        'components' => [
          { 'type' => 'BODY', 'text' => 'Rate us please' },
          {
            'type' => 'BUTTONS',
            'buttons' => [
              { 'type' => 'URL', 'text' => 'Rate', 'url' => 'https://example.com/{{1}}' }
            ]
          }
        ]
      }

      invalid_template = {
        'name' => 'promo',
        'status' => 'approved',
        'language' => 'en',
        'components' => [{ 'type' => 'BODY', 'text' => 'Buy now' }]
      }

      pending_template = {
        'name' => 'survey_pending',
        'status' => 'pending',
        'language' => 'en',
        'components' => [
          { 'type' => 'BODY', 'text' => 'Rate us' },
          {
            'type' => 'BUTTONS',
            'buttons' => [
              { 'type' => 'URL', 'text' => 'Rate', 'url' => 'https://example.com/{{1}}' }
            ]
          }
        ]
      }

      whatsapp_channel.update!(message_templates: [valid_template, invalid_template, pending_template])

      result = service.available_csat_templates
      expect(result.length).to eq(1)
      expect(result.first[:name]).to eq('survey_1')
      expect(result.first[:body_text]).to eq('Rate us please')
      expect(result.first[:button_text]).to eq('Rate')
    end

    it 'returns empty array when no templates exist' do
      whatsapp_channel.update!(message_templates: nil)
      expect(service.available_csat_templates).to eq([])
    end
  end
end
