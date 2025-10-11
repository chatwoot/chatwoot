# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Templates::NameGeneratorService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account.id) }

  describe '#generate_name' do
    context 'with quick_reply message' do
      it 'extracts name from receivedMessage title' do
        message_data = {
          'receivedMessage' => { 'title' => 'What would you like to know?' }
        }

        name = service.generate_name('quick_reply', message_data)
        expect(name).to eq('what_would_you_like_to_know')
      end

      it 'falls back to subtitle if title is missing' do
        message_data = {
          'receivedMessage' => { 'subtitle' => 'Please choose an option' }
        }

        name = service.generate_name('quick_reply', message_data)
        expect(name).to eq('please_choose_an_option')
      end

      it 'uses default name if no text found' do
        message_data = {}

        name = service.generate_name('quick_reply', message_data)
        expect(name).to eq('quick_reply')
      end

      it 'handles snake_case keys' do
        message_data = {
          'received_message' => { 'title' => 'How can we help?' }
        }

        name = service.generate_name('quick_reply', message_data)
        expect(name).to eq('how_can_we_help')
      end
    end

    context 'with list_picker message' do
      it 'extracts name from list picker title' do
        message_data = {
          'listPicker' => {
            'sections' => [
              { 'title' => 'Choose a product' }
            ]
          }
        }

        name = service.generate_name('list_picker', message_data)
        expect(name).to eq('choose_a_product')
      end

      it 'falls back to receivedMessage title' do
        message_data = {
          'receivedMessage' => { 'title' => 'Product Selection' }
        }

        name = service.generate_name('list_picker', message_data)
        expect(name).to eq('product_selection')
      end

      it 'handles snake_case keys' do
        message_data = {
          'list_picker' => {
            'sections' => [
              { 'title' => 'Select service' }
            ]
          }
        }

        name = service.generate_name('list_picker', message_data)
        expect(name).to eq('select_service')
      end
    end

    context 'with time_picker message' do
      it 'extracts name from receivedMessage title' do
        message_data = {
          'receivedMessage' => { 'title' => 'Schedule your appointment' }
        }

        name = service.generate_name('time_picker', message_data)
        expect(name).to eq('schedule_your_appointment')
      end

      it 'uses default name if no title found' do
        message_data = {}

        name = service.generate_name('time_picker', message_data)
        expect(name).to eq('appointment_scheduler')
      end
    end

    context 'with form message' do
      it 'extracts name from receivedMessage title' do
        message_data = {
          'receivedMessage' => { 'title' => 'Customer Feedback Form' }
        }

        name = service.generate_name('form', message_data)
        expect(name).to eq('customer_feedback_form')
      end

      it 'falls back to form title' do
        message_data = {
          'form' => { 'title' => 'Support Request' }
        }

        name = service.generate_name('form', message_data)
        expect(name).to eq('support_request')
      end
    end

    context 'with apple_pay message' do
      it 'extracts name from merchant name' do
        message_data = {
          'payment' => { 'merchantName' => 'Acme Store' }
        }

        name = service.generate_name('apple_pay', message_data)
        expect(name).to eq('payment_acme_store')
      end

      it 'uses default name if no merchant found' do
        message_data = {}

        name = service.generate_name('apple_pay', message_data)
        expect(name).to eq('payment_request')
      end

      it 'handles snake_case keys' do
        message_data = {
          'payment' => { 'merchant_name' => 'Test Shop' }
        }

        name = service.generate_name('apple_pay', message_data)
        expect(name).to eq('payment_test_shop')
      end
    end

    context 'with special characters' do
      it 'removes special characters from name' do
        message_data = {
          'receivedMessage' => { 'title' => 'What\'s your favorite product!?' }
        }

        name = service.generate_name('quick_reply', message_data)
        expect(name).to eq('whats_your_favorite_product')
      end

      it 'handles hyphens and converts to underscores' do
        message_data = {
          'receivedMessage' => { 'title' => 'Sign-up for newsletter' }
        }

        name = service.generate_name('quick_reply', message_data)
        expect(name).to eq('sign_up_for_newsletter')
      end

      it 'handles multiple spaces' do
        message_data = {
          'receivedMessage' => { 'title' => 'Select    product    type' }
        }

        name = service.generate_name('quick_reply', message_data)
        expect(name).to eq('select_product_type')
      end
    end

    context 'with name uniqueness' do
      it 'appends number if name already exists' do
        create(:message_template, account: account, name: 'test_template')

        message_data = {
          'receivedMessage' => { 'title' => 'Test Template' }
        }

        name = service.generate_name('quick_reply', message_data)
        expect(name).to eq('test_template_1')
      end

      it 'increments number for multiple duplicates' do
        create(:message_template, account: account, name: 'test_template')
        create(:message_template, account: account, name: 'test_template_1')
        create(:message_template, account: account, name: 'test_template_2')

        message_data = {
          'receivedMessage' => { 'title' => 'Test Template' }
        }

        name = service.generate_name('quick_reply', message_data)
        expect(name).to eq('test_template_3')
      end
    end

    context 'with long names' do
      it 'truncates name to max length' do
        long_title = 'A' * 150

        message_data = {
          'receivedMessage' => { 'title' => long_title }
        }

        name = service.generate_name('quick_reply', message_data)
        expect(name.length).to be <= 100
      end
    end
  end

  describe '#generate_shortcode' do
    it 'creates shortcode from template name' do
      shortcode = service.generate_shortcode('test_template')
      expect(shortcode).to eq('test_template')
    end

    it 'converts to lowercase' do
      shortcode = service.generate_shortcode('Test_Template')
      expect(shortcode).to eq('test_template')
    end

    it 'removes special characters' do
      shortcode = service.generate_shortcode('test!@#template')
      expect(shortcode).to eq('testtemplate')
    end

    it 'truncates to max length' do
      long_name = 'test_template_with_very_long_name'
      shortcode = service.generate_shortcode(long_name)
      expect(shortcode.length).to be <= 20
      expect(shortcode).to eq('test_template_with_v')
    end

    context 'with uniqueness checks' do
      it 'appends number if shortcode exists in canned responses' do
        create(:canned_response, account: account, short_code: 'test_code')

        shortcode = service.generate_shortcode('test_code')
        expect(shortcode).to eq('test_code_1')
      end

      it 'appends number if shortcode exists in message templates' do
        create(:message_template, account: account, name: 'test_code')

        shortcode = service.generate_shortcode('test_code')
        expect(shortcode).to eq('test_code_1')
      end

      it 'increments number for multiple duplicates' do
        create(:canned_response, account: account, short_code: 'test_code')
        create(:message_template, account: account, name: 'test_code_1')
        create(:canned_response, account: account, short_code: 'test_code_2')

        shortcode = service.generate_shortcode('test_code')
        expect(shortcode).to eq('test_code_3')
      end

      it 'respects max length when appending numbers' do
        long_name = 'test_template_long'
        create(:canned_response, account: account, short_code: 'test_template_long')

        shortcode = service.generate_shortcode(long_name)
        expect(shortcode.length).to be <= 20
        expect(shortcode).to eq('test_template_lon_1')
      end
    end
  end

  describe '#detect_category' do
    it 'returns scheduling for time_picker' do
      expect(service.detect_category('time_picker')).to eq('scheduling')
    end

    it 'returns payment for apple_pay' do
      expect(service.detect_category('apple_pay')).to eq('payment')
    end

    it 'returns authentication for oauth' do
      expect(service.detect_category('oauth')).to eq('authentication')
    end

    it 'returns support for form' do
      expect(service.detect_category('form')).to eq('support')
    end

    it 'returns general for quick_reply' do
      expect(service.detect_category('quick_reply')).to eq('general')
    end

    it 'returns sales for list_picker' do
      expect(service.detect_category('list_picker')).to eq('sales')
    end

    it 'returns integration for imessage_app' do
      expect(service.detect_category('imessage_app')).to eq('integration')
    end

    it 'returns general for unknown types' do
      expect(service.detect_category('unknown_type')).to eq('general')
    end
  end

  describe '#generate_description' do
    context 'with quick_reply message' do
      it 'generates description with title and reply count' do
        message_data = {
          'receivedMessage' => { 'title' => 'Choose an option' },
          'quickReply' => { 'replies' => [{}, {}, {}] }
        }

        description = service.generate_description('quick_reply', message_data)
        expect(description).to eq('Quick reply: Choose an option (3 options)')
      end

      it 'handles missing title' do
        message_data = {
          'quickReply' => { 'replies' => [{}, {}] }
        }

        description = service.generate_description('quick_reply', message_data)
        expect(description).to eq('Quick reply with 2 options')
      end

      it 'handles snake_case keys' do
        message_data = {
          'received_message' => { 'title' => 'Select' },
          'quick_reply' => { 'replies' => [{}] }
        }

        description = service.generate_description('quick_reply', message_data)
        expect(description).to eq('Quick reply: Select (1 options)')
      end
    end

    context 'with list_picker message' do
      it 'generates description with sections and items count' do
        message_data = {
          'receivedMessage' => { 'title' => 'Choose product' },
          'listPicker' => {
            'sections' => [
              { 'items' => [{}, {}] },
              { 'items' => [{}, {}, {}] }
            ]
          }
        }

        description = service.generate_description('list_picker', message_data)
        expect(description).to eq('List picker: Choose product (2 sections, 5 items)')
      end

      it 'handles missing title' do
        message_data = {
          'listPicker' => {
            'sections' => [
              { 'items' => [{}] }
            ]
          }
        }

        description = service.generate_description('list_picker', message_data)
        expect(description).to eq('List picker with 1 sections and 1 items')
      end
    end

    context 'with time_picker message' do
      it 'generates description with slots count' do
        message_data = {
          'receivedMessage' => { 'title' => 'Book appointment' },
          'timePicker' => { 'timeSlots' => [{}, {}, {}] }
        }

        description = service.generate_description('time_picker', message_data)
        expect(description).to eq('Time picker: Book appointment (3 time slots)')
      end

      it 'handles snake_case keys' do
        message_data = {
          'time_picker' => { 'time_slots' => [{}, {}] }
        }

        description = service.generate_description('time_picker', message_data)
        expect(description).to eq('Time picker with 2 available time slots')
      end
    end

    context 'with form message' do
      it 'generates description with fields count' do
        message_data = {
          'receivedMessage' => { 'title' => 'Contact Form' },
          'form' => { 'fields' => [{}, {}, {}, {}] }
        }

        description = service.generate_description('form', message_data)
        expect(description).to eq('Form: Contact Form (4 fields)')
      end

      it 'handles missing title' do
        message_data = {
          'form' => { 'fields' => [{}, {}] }
        }

        description = service.generate_description('form', message_data)
        expect(description).to eq('Form with 2 fields')
      end
    end

    context 'with apple_pay message' do
      it 'generates description with merchant and amount' do
        message_data = {
          'payment' => {
            'merchantName' => 'Acme Store',
            'total' => { 'amount' => '99.99' }
          }
        }

        description = service.generate_description('apple_pay', message_data)
        expect(description).to eq('Apple Pay: Acme Store - 99.99')
      end

      it 'handles missing amount' do
        message_data = {
          'payment' => { 'merchantName' => 'Test Shop' }
        }

        description = service.generate_description('apple_pay', message_data)
        expect(description).to eq('Apple Pay: Test Shop')
      end

      it 'handles missing merchant' do
        message_data = {}

        description = service.generate_description('apple_pay', message_data)
        expect(description).to eq('Apple Pay payment request')
      end
    end

    context 'with long descriptions' do
      it 'truncates long text' do
        long_title = 'A' * 100

        message_data = {
          'receivedMessage' => { 'title' => long_title },
          'quickReply' => { 'replies' => [{}] }
        }

        description = service.generate_description('quick_reply', message_data)
        expect(description.length).to be <= 100
        expect(description).to include('...')
      end
    end

    context 'with unknown message type' do
      it 'returns generic description' do
        description = service.generate_description('unknown_type', {})
        expect(description).to eq('Unknown Type template')
      end
    end
  end
end
