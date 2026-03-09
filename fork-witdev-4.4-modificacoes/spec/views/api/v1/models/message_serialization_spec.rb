# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Message JSON serialization' do
  let(:account) { create(:account) }
  let(:instagram_channel) { create(:channel_instagram, account: account) }
  let(:inbox) { create(:inbox, channel: instagram_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, inbox: inbox, contact: contact, account: account) }

  describe 'content_type serialization' do
    context 'when message has cards content_type' do
      let(:message) do
        create(:message,
               conversation: conversation,
               account: account,
               inbox: inbox,
               message_type: :outgoing,
               content_type: :cards,
               content: 'Rich card message',
               content_attributes: {
                 'items' => [
                   {
                     'title' => 'Test Card',
                     'description' => 'Test Description'
                   }
                 ]
               })
      end

      it 'stores content_type as integer enum in database' do
        # Verify database stores integer value
        expect(message.read_attribute_before_type_cast('content_type')).to eq(Message.content_types['cards'])
        expect(message.read_attribute_before_type_cast('content_type')).to be_a(Integer)
        expect(message.read_attribute_before_type_cast('content_type')).to eq(5) # cards enum value
      end

      it 'serializes content_type as string in JSON view' do
        # Render the JSON view
        json_output = render_template('api/v1/models/_message', message: message)
        parsed_json = JSON.parse(json_output)

        # Verify JSON contains string value
        expect(parsed_json['content_type']).to eq('cards')
        expect(parsed_json['content_type']).to be_a(String)
      end

      it 'includes content_attributes in JSON serialization' do
        json_output = render_template('api/v1/models/_message', message: message)
        parsed_json = JSON.parse(json_output)

        expect(parsed_json['content_attributes']).to be_present
        expect(parsed_json['content_attributes']['items']).to be_an(Array)
        expect(parsed_json['content_attributes']['items'].first['title']).to eq('Test Card')
      end
    end

    context 'when message has input_select content_type' do
      let(:message) do
        create(:message,
               conversation: conversation,
               account: account,
               inbox: inbox,
               message_type: :outgoing,
               content_type: :input_select,
               content: 'Select an option',
               content_attributes: {
                 'items' => [
                   {
                     'title' => 'Option 1',
                     'value' => 'OPTION_1'
                   }
                 ]
               })
      end

      it 'stores content_type as integer enum in database' do
        expect(message.read_attribute_before_type_cast('content_type')).to eq(Message.content_types['input_select'])
        expect(message.read_attribute_before_type_cast('content_type')).to be_a(Integer)
        expect(message.read_attribute_before_type_cast('content_type')).to eq(4) # input_select enum value
      end

      it 'serializes content_type as string in JSON view' do
        json_output = render_template('api/v1/models/_message', message: message)
        parsed_json = JSON.parse(json_output)

        expect(parsed_json['content_type']).to eq('input_select')
        expect(parsed_json['content_type']).to be_a(String)
      end
    end

    context 'when message has text content_type' do
      let(:message) do
        create(:message,
               conversation: conversation,
               account: account,
               inbox: inbox,
               message_type: :outgoing,
               content_type: :text,
               content: 'Simple text message')
      end

      it 'stores content_type as integer enum in database' do
        expect(message.read_attribute_before_type_cast('content_type')).to eq(Message.content_types['text'])
        expect(message.read_attribute_before_type_cast('content_type')).to be_a(Integer)
        expect(message.read_attribute_before_type_cast('content_type')).to eq(0) # text enum value
      end

      it 'serializes content_type as string in JSON view' do
        json_output = render_template('api/v1/models/_message', message: message)
        parsed_json = JSON.parse(json_output)

        expect(parsed_json['content_type']).to eq('text')
        expect(parsed_json['content_type']).to be_a(String)
      end
    end
  end

  describe 'enum to string conversion verification' do
    it 'verifies all content_type enums serialize to strings' do
      Message.content_types.each do |string_key, integer_value|
        message = create(:message,
                         conversation: conversation,
                         account: account,
                         inbox: inbox,
                         message_type: :outgoing,
                         content_type: string_key,
                         content: "Test #{string_key} message")

        # Verify database storage
        expect(message.read_attribute_before_type_cast('content_type')).to eq(integer_value)

        # Verify enum method returns string
        expect(message.content_type).to eq(string_key)

        # Verify JSON serialization
        json_output = render_template('api/v1/models/_message', message: message)
        parsed_json = JSON.parse(json_output)
        expect(parsed_json['content_type']).to eq(string_key)
      end
    end
  end

  describe 'API response format verification' do
    let(:message) do
      create(:message,
             conversation: conversation,
             account: account,
             inbox: inbox,
             message_type: :outgoing,
             content_type: :cards,
             content: 'Rich message',
             content_attributes: {
               'items' => [
                 {
                   'title' => 'Product Card',
                   'description' => 'Product Description',
                   'media_url' => 'https://example.com/image.jpg',
                   'actions' => [
                     {
                       'type' => 'link',
                       'text' => 'View More',
                       'uri' => 'https://example.com/product'
                     }
                   ]
                 }
               ]
             })
    end

    it 'includes all required fields for rich message rendering' do
      json_output = render_template('api/v1/models/_message', message: message)
      parsed_json = JSON.parse(json_output)

      # Verify core message fields
      expect(parsed_json['id']).to eq(message.id)
      expect(parsed_json['content']).to eq('Rich message')
      expect(parsed_json['content_type']).to eq('cards')
      expect(parsed_json['message_type']).to be_present

      # Verify rich content attributes
      expect(parsed_json['content_attributes']).to be_present
      expect(parsed_json['content_attributes']['items']).to be_an(Array)

      # Verify card structure
      card = parsed_json['content_attributes']['items'].first
      expect(card['title']).to eq('Product Card')
      expect(card['description']).to eq('Product Description')
      expect(card['media_url']).to eq('https://example.com/image.jpg')
      expect(card['actions']).to be_an(Array)

      # Verify action structure
      action = card['actions'].first
      expect(action['type']).to eq('link')
      expect(action['text']).to eq('View More')
      expect(action['uri']).to eq('https://example.com/product')
    end

    it 'maintains backward compatibility with existing message fields' do
      json_output = render_template('api/v1/models/_message', message: message)
      parsed_json = JSON.parse(json_output)

      # Verify all standard message fields are present
      expected_fields = %w[
        id content inbox_id conversation_id message_type
        content_type status content_attributes created_at
        private source_id
      ]

      expected_fields.each do |field|
        expect(parsed_json).to have_key(field), "Missing field: #{field}"
      end
    end
  end

  private

  def render_template(template_path, locals = {})
    # Create a view context for rendering
    view_context = ActionView::Base.new(ActionController::Base.view_paths, locals)
    view_context.extend(ApplicationHelper)

    # Render the template
    view_context.render(template: template_path, locals: locals)
  end
end