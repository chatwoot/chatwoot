require 'rails_helper'

RSpec.describe Twilio::CsatTemplateService do
  let(:account) { create(:account) }
  let(:twilio_channel) do
    create(:channel_twilio_sms, account: account, medium: 'whatsapp')
  end
  let(:inbox) { create(:inbox, channel: twilio_channel, account: account) }
  let(:service) { described_class.new(twilio_channel) }

  let(:expected_template_name) { "customer_satisfaction_survey_#{twilio_channel.inbox.id}" }
  let(:template_config) do
    {
      template_name: expected_template_name,
      message: 'How would you rate your experience?',
      button_text: 'Rate Us',
      language: 'en',
      base_url: 'https://example.com'
    }
  end

  describe '#create_template' do
    let(:mock_creation_response) do
      instance_double(HTTParty::Response,
                      :success? => true,
                      :body => '{}',
                      '[]' => 'CT123').tap do |response|
        allow(response).to receive(:dig).with('links', 'approval_create').and_return('https://content.twilio.com/approval')
      end
    end

    let(:mock_approval_response) do
      instance_double(HTTParty::Response,
                      success?: true,
                      body: '{}',
                      parsed_response: { 'sid' => 'AP123', 'whatsapp' => { 'status' => 'pending' } })
    end

    before do
      allow(HTTParty).to receive(:post).and_return(mock_creation_response)
      inbox.update!(csat_config: {})
    end

    it 'creates template with correct request body' do
      expected_body = {
        friendly_name: expected_template_name,
        language: 'en',
        variables: { '1' => '12345' },
        types: {
          'twilio/call-to-action' => {
            body: 'How would you rate your experience?',
            actions: [
              {
                type: 'URL',
                title: 'Rate Us',
                url: 'https://example.com/survey/responses/{{1}}'
              }
            ]
          }
        }
      }

      expect(HTTParty).to receive(:post).with(
        'https://content.twilio.com/v1/Content',
        headers: {
          'Authorization' => "Basic #{Base64.strict_encode64("#{twilio_channel.account_sid}:#{twilio_channel.auth_token}")}",
          'Content-Type' => 'application/json'
        },
        body: expected_body.to_json
      ).and_return(mock_creation_response)

      expect(HTTParty).to receive(:post).with(
        'https://content.twilio.com/approval',
        headers: {
          'Authorization' => "Basic #{Base64.strict_encode64("#{twilio_channel.account_sid}:#{twilio_channel.auth_token}")}",
          'Content-Type' => 'application/json'
        },
        body: {
          name: expected_template_name,
          category: 'UTILITY'
        }.to_json
      ).and_return(mock_approval_response)

      service.create_template(template_config)
    end

    it 'submits for WhatsApp approval when approval URL is provided' do
      allow(mock_creation_response).to receive(:dig).with('links', 'approval_create').and_return('https://content.twilio.com/approval')

      expect(HTTParty).to receive(:post).with(
        'https://content.twilio.com/approval',
        headers: {
          'Authorization' => "Basic #{Base64.strict_encode64("#{twilio_channel.account_sid}:#{twilio_channel.auth_token}")}",
          'Content-Type' => 'application/json'
        },
        body: {
          name: expected_template_name,
          category: 'UTILITY'
        }.to_json
      ).and_return(mock_approval_response)

      service.create_template(template_config)
    end

    it 'returns success response with approval details' do
      allow(mock_creation_response).to receive(:dig).with('links', 'approval_create').and_return('https://content.twilio.com/approval')
      allow(HTTParty).to receive(:post).and_return(mock_creation_response, mock_approval_response)

      result = service.create_template(template_config)

      expect(result).to eq({
                             success: true,
                             content_sid: 'CT123',
                             friendly_name: expected_template_name,
                             language: 'en',
                             status: 'pending',
                             approval_sid: 'AP123',
                             whatsapp_status: 'pending'
                           })
    end

    it 'handles missing approval URL gracefully' do
      no_approval_response = instance_double(HTTParty::Response,
                                             :success? => true,
                                             :body => '{}',
                                             '[]' => 'CT123').tap do |response|
        allow(response).to receive(:dig).with('links', 'approval_create').and_return(nil)
      end
      allow(HTTParty).to receive(:post).and_return(no_approval_response)
      allow(Rails.logger).to receive(:warn)

      result = service.create_template(template_config)

      expect(result).to eq({
                             success: true,
                             content_sid: 'CT123',
                             friendly_name: expected_template_name,
                             language: 'en',
                             status: 'pending'
                           })
    end

    context 'when template creation fails' do
      let(:error_response) do
        instance_double(HTTParty::Response,
                        success?: false,
                        code: 400,
                        body: '{"error": "Invalid template"}')
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
        expect(Rails.logger).to receive(:error).with('Twilio template creation failed: 400 - {"error": "Invalid template"}')
        service.create_template(template_config)
      end
    end

    context 'when approval submission fails' do
      let(:failed_approval_response) do
        instance_double(HTTParty::Response,
                        success?: false,
                        code: 422,
                        body: '{"error": "Approval failed"}')
      end

      before do
        allow(HTTParty).to receive(:post).and_return(mock_creation_response, failed_approval_response)
        allow(Rails.logger).to receive(:error)
      end

      it 'returns template creation success with fallback status' do
        result = service.create_template(template_config)

        expect(result).to eq({
                               success: true,
                               content_sid: 'CT123',
                               friendly_name: expected_template_name,
                               language: 'en',
                               status: 'created'
                             })
      end

      it 'logs the approval error' do
        expect(Rails.logger).to receive(:error).with('Twilio template approval submission failed: 422 - {"error": "Approval failed"}')
        service.create_template(template_config)
      end
    end

    context 'when an exception occurs' do
      before do
        allow(HTTParty).to receive(:post).and_raise(StandardError, 'Network timeout')
        allow(Rails.logger).to receive(:error)
      end

      it 'handles exceptions gracefully' do
        result = service.create_template(template_config)
        expect(result).to eq({ success: false, error: 'Network timeout' })
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with('Error creating Twilio template: Network timeout')
        service.create_template(template_config)
      end
    end
  end

  describe '#delete_template' do
    let(:mock_response) do
      instance_double(HTTParty::Response, success?: true, body: '{}')
    end

    it 'makes DELETE request to correct endpoint' do
      expect(HTTParty).to receive(:delete).with(
        'https://content.twilio.com/v1/Content/CT123',
        headers: {
          'Authorization' => "Basic #{Base64.strict_encode64("#{twilio_channel.account_sid}:#{twilio_channel.auth_token}")}",
          'Content-Type' => 'application/json'
        }
      ).and_return(mock_response)

      result = service.delete_template(nil, 'CT123')
      expect(result).to eq({ success: true, response_body: '{}' })
    end

    it 'uses content_sid from config when none provided' do
      twilio_channel.inbox.update!(
        csat_config: { 'template' => { 'content_sid' => 'CT456' } }
      )

      expect(HTTParty).to receive(:delete).with(
        'https://content.twilio.com/v1/Content/CT456',
        anything
      ).and_return(mock_response)

      service.delete_template
    end

    it 'returns error when no template to delete' do
      result = service.delete_template
      expect(result).to eq({ success: false, error: 'No template to delete' })
    end

    it 'returns failure response when API call fails' do
      error_response = instance_double(HTTParty::Response, success?: false, body: '{"error": "Template not found"}')
      allow(HTTParty).to receive(:delete).and_return(error_response)

      result = service.delete_template(nil, 'CT123')
      expect(result).to eq({ success: false, response_body: '{"error": "Template not found"}' })
    end
  end

  describe '#get_template_status' do
    let(:mock_template_response) do
      instance_double(HTTParty::Response,
                      :success? => true,
                      :body => '{}',
                      '[]' => { 'friendly_name' => 'test_template', 'language' => 'en' }).tap do |response|
        allow(response).to receive(:[]).with('friendly_name').and_return('test_template')
        allow(response).to receive(:[]).with('language').and_return('en')
      end
    end

    let(:mock_approval_response) do
      instance_double(HTTParty::Response,
                      :success? => true,
                      '[]' => { 'whatsapp' => { 'status' => 'approved', 'name' => 'test_template' } }).tap do |response|
        allow(response).to receive(:[]).with('whatsapp').and_return({ 'status' => 'approved', 'name' => 'test_template' })
      end
    end

    before do
      allow(HTTParty).to receive(:get).and_return(mock_template_response, mock_approval_response)
    end

    it 'returns error when no content_sid provided' do
      result = service.get_template_status(nil)
      expect(result).to eq({ success: false, error: 'No content SID provided' })
    end

    it 'makes GET requests to correct endpoints' do
      expect(HTTParty).to receive(:get).with(
        'https://content.twilio.com/v1/Content/CT123',
        headers: {
          'Authorization' => "Basic #{Base64.strict_encode64("#{twilio_channel.account_sid}:#{twilio_channel.auth_token}")}",
          'Content-Type' => 'application/json'
        }
      ).and_return(mock_template_response)

      expect(HTTParty).to receive(:get).with(
        'https://content.twilio.com/v1/Content/CT123/ApprovalRequests',
        headers: {
          'Authorization' => "Basic #{Base64.strict_encode64("#{twilio_channel.account_sid}:#{twilio_channel.auth_token}")}",
          'Content-Type' => 'application/json'
        }
      ).and_return(mock_approval_response)

      service.get_template_status('CT123')
    end

    it 'returns approved template response when approval exists' do
      result = service.get_template_status('CT123')

      expect(result).to eq({
                             success: true,
                             template: {
                               content_sid: 'CT123',
                               friendly_name: 'test_template',
                               status: 'approved',
                               language: 'en'
                             }
                           })
    end

    it 'returns pending template response when no approval' do
      failed_approval_response = instance_double(HTTParty::Response,
                                                 :success? => false,
                                                 '[]' => nil).tap do |response|
        allow(response).to receive(:[]).with('whatsapp').and_return(nil)
      end
      allow(HTTParty).to receive(:get).and_return(mock_template_response, failed_approval_response)

      result = service.get_template_status('CT123')

      expect(result).to eq({
                             success: true,
                             template: {
                               content_sid: 'CT123',
                               friendly_name: 'test_template',
                               status: 'pending',
                               language: 'en'
                             }
                           })
    end

    context 'when template details fetch fails' do
      let(:error_response) do
        instance_double(HTTParty::Response, success?: false, code: 404, body: '{"error": "Not found"}')
      end

      before do
        allow(HTTParty).to receive(:get).and_return(error_response)
        allow(Rails.logger).to receive(:error)
      end

      it 'returns error response' do
        result = service.get_template_status('CT123')
        expect(result).to eq({ success: false, error: 'Template not found' })
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with('Failed to get template details: 404 - {"error": "Not found"}')
        service.get_template_status('CT123')
      end
    end

    context 'when an exception occurs' do
      before do
        allow(HTTParty).to receive(:get).and_raise(StandardError, 'Connection timeout')
        allow(Rails.logger).to receive(:error)
      end

      it 'handles exceptions gracefully' do
        result = service.get_template_status('CT123')
        expect(result).to eq({ success: false, error: 'Connection timeout' })
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with('Error fetching Twilio template status: Connection timeout')
        service.get_template_status('CT123')
      end
    end
  end

  describe 'private methods' do
    describe '#generate_template_name' do
      context 'when no existing template' do
        it 'returns base name as-is' do
          twilio_channel.inbox.update!(csat_config: {})
          result = service.send(:generate_template_name, 'new_template_name')
          expect(result).to eq('new_template_name')
        end
      end

      context 'when existing template has no versioned name' do
        it 'starts versioning from 1' do
          twilio_channel.inbox.update!(csat_config: {
                                         'template' => { 'friendly_name' => expected_template_name }
                                       })
          result = service.send(:generate_template_name, 'new_template_name')
          expect(result).to eq("#{expected_template_name}_1")
        end
      end

      context 'when existing template has versioned name' do
        it 'increments version number' do
          twilio_channel.inbox.update!(csat_config: {
                                         'template' => { 'friendly_name' => "#{expected_template_name}_1" }
                                       })
          result = service.send(:generate_template_name, 'new_template_name')
          expect(result).to eq("#{expected_template_name}_2")
        end
      end
    end

    describe '#build_template_request_body' do
      it 'builds correct request structure' do
        result = service.send(:build_template_request_body, template_config)

        expect(result).to eq({
                               friendly_name: expected_template_name,
                               language: 'en',
                               variables: { '1' => '12345' },
                               types: {
                                 'twilio/call-to-action' => {
                                   body: 'How would you rate your experience?',
                                   actions: [
                                     {
                                       type: 'URL',
                                       title: 'Rate Us',
                                       url: 'https://example.com/survey/responses/{{1}}'
                                     }
                                   ]
                                 }
                               }
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
        expect(result[:types]['twilio/call-to-action'][:actions][0][:title]).to eq('Please rate us')
      end
    end

    describe '#current_template_name_from_config' do
      it 'returns template name from config' do
        twilio_channel.inbox.update!(csat_config: {
                                       'template' => { 'friendly_name' => 'test_template' }
                                     })
        result = service.send(:current_template_name_from_config)
        expect(result).to eq('test_template')
      end

      it 'returns nil when no config' do
        result = service.send(:current_template_name_from_config)
        expect(result).to be_nil
      end
    end

    describe '#current_template_sid_from_config' do
      it 'returns content_sid from config' do
        twilio_channel.inbox.update!(csat_config: {
                                       'template' => { 'content_sid' => 'CT123' }
                                     })
        result = service.send(:current_template_sid_from_config)
        expect(result).to eq('CT123')
      end

      it 'returns nil when no config' do
        result = service.send(:current_template_sid_from_config)
        expect(result).to be_nil
      end
    end
  end
end
