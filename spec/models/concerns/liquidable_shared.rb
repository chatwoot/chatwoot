require 'rails_helper'

shared_examples_for 'liqudable' do
  context 'when liquid is present in content' do
    let(:contact) { create(:contact, name: 'john', phone_number: '+912883', custom_attributes: { customer_type: 'platinum' }) }
    let(:conversation) { create(:conversation, id: 1, contact: contact, custom_attributes: { priority: 'high' }) }

    context 'when message is incoming' do
      let(:message) { build(:message, conversation: conversation, message_type: 'incoming') }

      it 'will not process liquid in content' do
        message.content = 'hey {{contact.name}} how are you?'
        message.save!
        expect(message.content).to eq 'hey {{contact.name}} how are you?'
      end
    end

    context 'when message is outgoing' do
      let(:message) { build(:message, conversation: conversation, message_type: 'outgoing') }

      it 'set replaces liquid variables in message' do
        message.content = 'hey {{contact.name}} how are you?'
        message.save!
        expect(message.content).to eq 'hey John how are you?'
      end

      it 'set replaces liquid custom attributes in message' do
        message.content = 'Are you a {{contact.custom_attribute.customer_type}} customer,
        If yes then the priority is {{conversation.custom_attribute.priority}}'
        message.save!
        expect(message.content).to eq 'Are you a platinum customer,
        If yes then the priority is high'
      end

      it 'process liquid operators like default value' do
        message.content = 'Can we send you an email at {{ contact.email | default: "default"  }} ?'
        message.save!
        expect(message.content).to eq 'Can we send you an email at default ?'
      end

      it 'return empty string when value is not available' do
        message.content = 'Can we send you an email at {{contact.email}}?'
        message.save!
        expect(message.content).to eq 'Can we send you an email at ?'
      end

      it 'will skip processing broken liquid tags' do
        message.content = 'Can we send you an email at {{contact.email}  {{hi}} ?'
        message.save!
        expect(message.content).to eq 'Can we send you an email at {{contact.email}  {{hi}} ?'
      end

      it 'will not process liquid tags in multiple code blocks' do
        message.content = 'hey {{contact.name}} how are you? ```code: {{contact.name}}``` ``` code: {{contact.name}} ``` test `{{contact.name}}`'
        message.save!
        expect(message.content).to eq 'hey John how are you? ```code: {{contact.name}}``` ``` code: {{contact.name}} ``` test `{{contact.name}}`'
      end

      it 'will not process liquid tags in single ticks' do
        message.content = 'hey {{contact.name}} how are you? ` code: {{contact.name}} ` ` code: {{contact.name}} ` test'
        message.save!
        expect(message.content).to eq 'hey John how are you? ` code: {{contact.name}} ` ` code: {{contact.name}} ` test'
      end

      it 'will not throw error for broken quotes' do
        message.content = 'hey {{contact.name}} how are you? ` code: {{contact.name}} ` ` code: {{contact.name}} test'
        message.save!
        expect(message.content).to eq 'hey John how are you? ` code: {{contact.name}} ` ` code: John test'
      end
    end
  end

  context 'when liquid is present in template_params' do
    let(:contact) do
      create(:contact, name: 'john', email: 'john@example.com', phone_number: '+912883', custom_attributes: { customer_type: 'platinum' })
    end
    let(:conversation) { create(:conversation, id: 1, contact: contact, custom_attributes: { priority: 'high' }) }

    context 'when message is outgoing with template_params' do
      let(:message) { build(:message, conversation: conversation, message_type: 'outgoing') }

      context 'when sending a WhatsApp template message' do
        let(:whatsapp_channel) { create(:channel_whatsapp, sync_templates: false, validate_provider_config: false) }
        let(:whatsapp_inbox) { whatsapp_channel.reload.inbox }
        let(:conversation) { create(:conversation, account: whatsapp_channel.account, inbox: whatsapp_inbox) }
        let(:message) do
          build(:message, account: whatsapp_channel.account, inbox: whatsapp_inbox, conversation: conversation, message_type: 'outgoing')
        end

        it 'replaces positional placeholders in the saved content' do
          message.content = 'Hello {{1}}, {{2}} is your contact.'
          message.additional_attributes = {
            'template_params' => {
              'name' => 'welcome',
              'language' => 'en',
              'content_mode' => 'raw_template',
              'processed_params' => {
                'body' => {
                  '1' => 'Ahmad',
                  '2' => 'Furqan'
                }
              }
            }
          }

          message.save!

          expect(message.content).to eq 'Hello Ahmad, Furqan is your contact.'
          expect(message.processed_message_content).to eq 'Hello Ahmad, Furqan is your contact.'
          expect(message.additional_attributes.dig('template_params', 'content_mode')).to eq 'rendered'
        end

        it 'replaces named placeholders in the saved content' do
          message.content = 'Hello {{customer_name}}, {{agent_name}} is your contact.'
          message.additional_attributes = {
            'template_params' => {
              'name' => 'welcome',
              'language' => 'en',
              'content_mode' => 'raw_template',
              'processed_params' => {
                'body' => {
                  'customer_name' => 'Ahmad',
                  'agent_name' => 'Furqan'
                }
              }
            }
          }

          message.save!

          expect(message.content).to eq 'Hello Ahmad, Furqan is your contact.'
        end

        it 'uses provider-normalized text values in the saved content' do
          message.content = 'Hello {{1}}.'
          message.additional_attributes = {
            'template_params' => {
              'name' => 'welcome',
              'language' => 'en',
              'content_mode' => 'raw_template',
              'processed_params' => {
                'body' => {
                  '1' => " <\"#{'a' * 1_005}\"> "
                }
              }
            }
          }

          message.save!

          expect(message.content).to eq "Hello #{'a' * 1_000}."
        end

        it 'preserves placeholders when body parameters are empty' do
          message.content = 'Hello {{1}}.'
          message.additional_attributes = {
            'template_params' => {
              'name' => 'welcome',
              'language' => 'en',
              'content_mode' => 'raw_template',
              'processed_params' => {
                'body' => {}
              }
            }
          }

          message.save!

          expect(message.content).to eq 'Hello {{1}}.'
        end

        it 'renders liquid variables used as body parameter values' do
          message.content = 'Hello {{1}}.'
          message.additional_attributes = {
            'template_params' => {
              'name' => 'welcome',
              'language' => 'en',
              'content_mode' => 'raw_template',
              'processed_params' => {
                'body' => {
                  '1' => '{{contact.name}}'
                }
              }
            }
          }

          message.save!

          expect(message.content).to eq "Hello #{conversation.contact.name}."
        end

        it 'does not evaluate rendered body parameter values twice' do
          conversation.contact.update!(name: '{{contact.email}}')
          message.content = 'Hello {{1}}.'
          message.additional_attributes = {
            'template_params' => {
              'name' => 'welcome',
              'language' => 'en',
              'content_mode' => 'raw_template',
              'processed_params' => {
                'body' => {
                  '1' => '{{contact.name}}'
                }
              }
            }
          }

          message.save!

          expect(message.content).to eq 'Hello {{contact.email}}.'
          expect(message.additional_attributes.dig('template_params', 'processed_params', 'body', '1')).to eq '{{contact.email}}'
        end

        it 'uses fallback text for structured body parameters' do
          message.content = 'Total {{1}} on {{2}}.'
          message.additional_attributes = {
            'template_params' => {
              'name' => 'receipt',
              'language' => 'en',
              'content_mode' => 'raw_template',
              'processed_params' => {
                'body' => {
                  '1' => {
                    'type' => 'currency',
                    'fallback_value' => '$10.00',
                    'code' => 'USD',
                    'amount_1000' => 10_000
                  },
                  '2' => {
                    'type' => 'date_time',
                    'fallback_value' => 'July 30, 2026',
                    'day_of_month' => 30,
                    'month' => 7,
                    'year' => 2026
                  }
                }
              }
            }
          }

          message.save!

          expect(message.content).to eq 'Total $10.00 on July 30, 2026.'
        end

        it 'replaces body parameters inside code formatting' do
          message.content = 'Use `{{1}}`.'
          message.additional_attributes = {
            'template_params' => {
              'name' => 'verification_code',
              'language' => 'en',
              'content_mode' => 'raw_template',
              'processed_params' => {
                'body' => {
                  '1' => '123456'
                }
              }
            }
          }

          message.save!

          expect(message.content).to eq 'Use `123456`.'
        end

        it 'preserves missing placeholders inside code formatting while replacing available parameters' do
          message.content = 'Use `{{1}}` and {{2}}.'
          message.additional_attributes = {
            'template_params' => {
              'name' => 'verification_code',
              'language' => 'en',
              'content_mode' => 'raw_template',
              'processed_params' => {
                'body' => {
                  '2' => 'Bob'
                }
              }
            }
          }

          message.save!

          expect(message.content).to eq 'Use `{{1}}` and Bob.'
          expect(message.additional_attributes.dig('template_params', 'content_mode')).to eq 'rendered'
        end

        it 'validates non-object template parameters before rendering' do
          message.content = 'Hello {{1}}.'
          message.additional_attributes = { 'template_params' => [] }

          expect(message).not_to be_valid
          expect(message.errors[:template_params]).to include('must be of type hash')
        end

        it 'validates non-object processed parameters before rendering' do
          message.content = 'Hello {{1}}.'
          message.additional_attributes = {
            'template_params' => {
              'name' => 'welcome',
              'content_mode' => 'raw_template',
              'processed_params' => 'Ahmad'
            }
          }

          expect(message).not_to be_valid
          expect(message.errors[:'template_params/processed_params']).to include('must be of type hash')
        end

        it 'replaces placeholders from legacy flat parameters' do
          message.content = 'Hello {{1}}, {{2}} is your contact.'
          message.additional_attributes = {
            'template_params' => {
              'name' => 'welcome',
              'language' => 'en',
              'content_mode' => 'raw_template',
              'processed_params' => {
                '1' => 'Ahmad',
                '2' => 'Furqan'
              }
            }
          }

          message.save!

          expect(message.content).to eq 'Hello Ahmad, Furqan is your contact.'
        end

        it 'rejects raw template content that exceeds the content limit after rendering' do
          message.content = "#{'a' * 149_995}{{1}}"
          message.additional_attributes = {
            'template_params' => {
              'name' => 'oversized',
              'language' => 'en',
              'content_mode' => 'raw_template',
              'processed_params' => {
                'body' => {
                  '1' => 'b' * 10
                }
              }
            }
          }

          expect(message).not_to be_valid
          expect(message.errors[:content]).to include('is too long (maximum is 150000 characters)')
        end

        it 'preserves rendered content from clients that do not opt into raw template rendering' do
          message.content = '{{2}} / Bob'
          message.additional_attributes = {
            'template_params' => {
              'name' => 'token_values',
              'language' => 'en',
              'processed_params' => {
                'body' => {
                  '1' => '{{2}}',
                  '2' => 'Bob'
                }
              }
            }
          }

          message.save!

          expect(message.content).to eq '2 / Bob'
          expect(message.additional_attributes.dig('template_params', 'processed_params', 'body', '1')).to eq '2'
        end
      end

      it 'replaces liquid variables in template_params body' do
        message.additional_attributes = {
          'template_params' => {
            'name' => 'greet',
            'category' => 'MARKETING',
            'language' => 'en',
            'processed_params' => {
              'body' => {
                'customer_name' => '{{contact.name}}',
                'customer_email' => '{{contact.email}}'
              }
            }
          }
        }
        message.save!

        body_params = message.additional_attributes['template_params']['processed_params']['body']
        expect(body_params['customer_name']).to eq 'John'
        expect(body_params['customer_email']).to eq 'john@example.com'
      end

      it 'replaces liquid variables in nested template_params' do
        message.additional_attributes = {
          'template_params' => {
            'name' => 'test_template',
            'processed_params' => {
              'header' => {
                'media_url' => 'https://example.com/{{contact.name}}.jpg'
              },
              'body' => {
                'customer_name' => '{{contact.name}}',
                'priority' => '{{conversation.custom_attribute.priority}}'
              },
              'footer' => {
                'company' => '{{account.name}}'
              }
            }
          }
        }
        message.save!

        processed = message.additional_attributes['template_params']['processed_params']
        expect(processed['header']['media_url']).to eq 'https://example.com/John.jpg'
        expect(processed['body']['customer_name']).to eq 'John'
        expect(processed['body']['priority']).to eq 'high'
        expect(processed['footer']['company']).to eq conversation.account.name
      end

      it 'handles arrays in template_params' do
        message.additional_attributes = {
          'template_params' => {
            'name' => 'test_template',
            'processed_params' => {
              'buttons' => [
                { 'type' => 'url', 'parameter' => 'https://example.com/{{contact.name}}' },
                { 'type' => 'text', 'parameter' => 'Hello {{contact.name}}' }
              ]
            }
          }
        }
        message.save!

        buttons = message.additional_attributes['template_params']['processed_params']['buttons']
        expect(buttons[0]['parameter']).to eq 'https://example.com/John'
        expect(buttons[1]['parameter']).to eq 'Hello John'
      end

      it 'handles custom attributes in template_params' do
        message.additional_attributes = {
          'template_params' => {
            'name' => 'test_template',
            'processed_params' => {
              'body' => {
                'customer_type' => '{{contact.custom_attribute.customer_type}}',
                'priority' => '{{conversation.custom_attribute.priority}}'
              }
            }
          }
        }
        message.save!

        body_params = message.additional_attributes['template_params']['processed_params']['body']
        expect(body_params['customer_type']).to eq 'platinum'
        expect(body_params['priority']).to eq 'high'
      end

      it 'handles missing email with default filter in template_params' do
        contact.update!(email: nil)
        message.additional_attributes = {
          'template_params' => {
            'name' => 'test_template',
            'processed_params' => {
              'body' => {
                'customer_email' => '{{ contact.email | default: "no-email@example.com" }}'
              }
            }
          }
        }
        message.save!

        body_params = message.additional_attributes['template_params']['processed_params']['body']
        expect(body_params['customer_email']).to eq 'no-email@example.com'
      end

      it 'handles broken liquid syntax in template_params gracefully' do
        message.additional_attributes = {
          'template_params' => {
            'name' => 'test_template',
            'processed_params' => {
              'body' => {
                'broken_liquid' => '{{contact.name}  {{invalid}}'
              }
            }
          }
        }
        message.save!

        body_params = message.additional_attributes['template_params']['processed_params']['body']
        expect(body_params['broken_liquid']).to eq '{{contact.name}  {{invalid}}'
      end

      it 'does not process template_params when message is incoming' do
        incoming_message = build(:message, conversation: conversation, message_type: 'incoming')
        incoming_message.additional_attributes = {
          'template_params' => {
            'name' => 'test_template',
            'processed_params' => {
              'body' => {
                'customer_name' => '{{contact.name}}'
              }
            }
          }
        }
        incoming_message.save!

        body_params = incoming_message.additional_attributes['template_params']['processed_params']['body']
        expect(body_params['customer_name']).to eq '{{contact.name}}'
      end

      it 'does not process template_params when not present' do
        message.additional_attributes = { 'other_data' => 'test' }
        expect { message.save! }.not_to raise_error
      end
    end
  end
end
