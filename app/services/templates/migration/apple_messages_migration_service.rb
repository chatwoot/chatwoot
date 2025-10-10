# frozen_string_literal: true

module Templates
  module Migration
    class AppleMessagesMigrationService < BaseMigrationService
      def migrate
        log_info 'Starting Apple Messages template migration...'
        log_info 'Creating example templates for common Apple Messages use cases...'

        ActiveRecord::Base.transaction do
          Channel::AppleMessagesForBusiness.find_each do |channel|
            create_example_templates(channel)
          end
        rescue StandardError => e
          log_error 'Migration failed, rolling back', e
          raise ActiveRecord::Rollback
        end

        log_info "Migration completed: #{@stats[:migrated]} created"
        @stats
      end

      def rollback
        count = MessageTemplate.where("metadata->>'migration_source' = ?", migration_source).count
        MessageTemplate.where("metadata->>'migration_source' = ?", migration_source).destroy_all

        log_info "Rolled back #{count} Apple Messages templates"
        { deleted: count }
      end

      protected

      def migration_source
        'apple_messages_migration'
      end

      private

      def create_example_templates(channel)
        inbox = channel.inbox
        account_id = inbox.account_id

        log_info "Creating example templates for channel #{channel.id} (Business ID: #{channel.business_id})"

        # Create templates for common use cases
        [
          time_picker_template,
          list_picker_template,
          apple_pay_template,
          form_template,
          rich_link_template
        ].each do |template_data|
          increment_total
          create_example_template(account_id, template_data)
        end
      rescue StandardError => e
        log_error "Error creating templates for channel #{channel.id}", e
        increment_failed
      end

      def create_example_template(account_id, template_data)
        template_name = template_data[:name]

        # Skip if already exists
        if template_exists?(account_id, template_name)
          log_skip "Template '#{template_name}' already exists"
          increment_skipped
          return
        end

        template = create_template(account_id, template_data)

        log_success "Created template '#{template_name}' (ID: #{template.id})"
        increment_success
      rescue StandardError => e
        log_error "Failed to create template '#{template_data[:name]}'", e
        increment_failed
      end

      def time_picker_template
        {
          name: 'Apple Messages - Appointment Booking',
          category: 'scheduling',
          description: 'Time picker template for booking appointments via Apple Messages',
          parameters: {
            'business_name' => {
              'type' => 'string',
              'required' => true,
              'description' => 'Name of the business',
              'example' => 'Acme Healthcare'
            },
            'event_title' => {
              'type' => 'string',
              'required' => true,
              'description' => 'Title of the appointment',
              'example' => 'Doctor Appointment'
            },
            'event_description' => {
              'type' => 'string',
              'required' => false,
              'description' => 'Description of the appointment',
              'example' => 'Annual checkup'
            },
            'timeslots' => {
              'type' => 'array',
              'required' => true,
              'description' => 'Array of available time slots',
              'example' => [
                { 'identifier' => 'slot1', 'startTime' => '2025-10-15T10:00:00Z', 'duration' => 3600 },
                { 'identifier' => 'slot2', 'startTime' => '2025-10-15T14:00:00Z', 'duration' => 3600 }
              ]
            }
          },
          supported_channels: ['apple_messages_for_business'],
          status: 'active',
          tags: %w[apple_messages time_picker appointment scheduling],
          use_cases: %w[appointment_booking scheduling],
          content_blocks: [
            {
              type: 'time_picker',
              properties: {
                'event' => {
                  'title' => '{{event_title}}',
                  'description' => '{{event_description}}',
                  'timeslots' => '{{timeslots}}'
                },
                'receivedMessage' => {
                  'title' => 'Please select a time for your {{event_title}}',
                  'subtitle' => 'Choose from the available slots below'
                },
                'replyMessage' => {
                  'title' => 'Great! We have you scheduled',
                  'subtitle' => 'You will receive a confirmation shortly'
                }
              }
            }
          ],
          channel_mappings: [
            {
              channel_type: 'apple_messages_for_business',
              content_type: 'apple_time_picker',
              field_mappings: {
                'event.title' => '{{event_title}}',
                'event.description' => '{{event_description}}',
                'event.timeslots' => '{{timeslots}}',
                'receivedMessage.title' => '{{properties.receivedMessage.title}}',
                'replyMessage.title' => '{{properties.replyMessage.title}}'
              }
            }
          ],
          original_id: 'example_time_picker',
          original_data: { source: 'example_template' }
        }
      end

      def list_picker_template
        {
          name: 'Apple Messages - Product Selection',
          category: 'support',
          description: 'List picker template for selecting products or options',
          parameters: {
            'list_title' => {
              'type' => 'string',
              'required' => true,
              'description' => 'Title of the list',
              'example' => 'Select a Product'
            },
            'sections' => {
              'type' => 'array',
              'required' => true,
              'description' => 'Sections with items to display',
              'example' => [
                {
                  'title' => 'Popular Items',
                  'items' => [
                    { 'identifier' => 'item1', 'title' => 'Product A', 'subtitle' => '$99' },
                    { 'identifier' => 'item2', 'title' => 'Product B', 'subtitle' => '$149' }
                  ]
                }
              ]
            }
          },
          supported_channels: ['apple_messages_for_business'],
          status: 'active',
          tags: %w[apple_messages list_picker product selection],
          use_cases: %w[product_selection menu_selection],
          content_blocks: [
            {
              type: 'list_picker',
              properties: {
                'receivedMessage' => {
                  'title' => '{{list_title}}',
                  'subtitle' => 'Please choose from the options below'
                },
                'replyMessage' => {
                  'title' => 'Thanks for your selection!',
                  'subtitle' => 'We will process your choice'
                },
                'sections' => '{{sections}}'
              }
            }
          ],
          channel_mappings: [
            {
              channel_type: 'apple_messages_for_business',
              content_type: 'apple_list_picker',
              field_mappings: {
                'receivedMessage.title' => '{{list_title}}',
                'listPicker.sections' => '{{sections}}'
              }
            }
          ],
          original_id: 'example_list_picker',
          original_data: { source: 'example_template' }
        }
      end

      def apple_pay_template
        {
          name: 'Apple Messages - Payment Request',
          category: 'payment',
          description: 'Apple Pay payment request template',
          parameters: {
            'merchant_name' => {
              'type' => 'string',
              'required' => true,
              'description' => 'Name of the merchant',
              'example' => 'Acme Store'
            },
            'amount' => {
              'type' => 'number',
              'required' => true,
              'description' => 'Payment amount',
              'example' => 99.99
            },
            'currency' => {
              'type' => 'string',
              'required' => true,
              'description' => 'Currency code',
              'example' => 'USD'
            },
            'description' => {
              'type' => 'string',
              'required' => false,
              'description' => 'Payment description',
              'example' => 'Order #12345'
            }
          },
          supported_channels: ['apple_messages_for_business'],
          status: 'active',
          tags: %w[apple_messages apple_pay payment],
          use_cases: %w[payment_request checkout],
          content_blocks: [
            {
              type: 'apple_pay',
              properties: {
                'payment' => {
                  'merchantName' => '{{merchant_name}}',
                  'total' => {
                    'amount' => '{{amount}}',
                    'label' => '{{description}}'
                  },
                  'currencyCode' => '{{currency}}'
                },
                'receivedMessage' => {
                  'title' => 'Payment Request',
                  'subtitle' => 'Please review and complete payment'
                },
                'replyMessage' => {
                  'title' => 'Payment Received',
                  'subtitle' => 'Thank you for your payment'
                }
              }
            }
          ],
          channel_mappings: [
            {
              channel_type: 'apple_messages_for_business',
              content_type: 'apple_pay',
              field_mappings: {
                'payment.merchantName' => '{{merchant_name}}',
                'payment.total.amount' => '{{amount}}',
                'payment.currencyCode' => '{{currency}}'
              }
            }
          ],
          original_id: 'example_apple_pay',
          original_data: { source: 'example_template' }
        }
      end

      def form_template
        {
          name: 'Apple Messages - Information Collection',
          category: 'support',
          description: 'Form template for collecting customer information',
          parameters: {
            'form_title' => {
              'type' => 'string',
              'required' => true,
              'description' => 'Title of the form',
              'example' => 'Contact Information'
            },
            'fields' => {
              'type' => 'array',
              'required' => true,
              'description' => 'Form fields to display',
              'example' => [
                { 'id' => 'name', 'title' => 'Full Name', 'type' => 'text', 'required' => true },
                { 'id' => 'email', 'title' => 'Email', 'type' => 'email', 'required' => true }
              ]
            }
          },
          supported_channels: ['apple_messages_for_business'],
          status: 'active',
          tags: %w[apple_messages form data_collection],
          use_cases: %w[information_collection survey feedback],
          content_blocks: [
            {
              type: 'form',
              properties: {
                'receivedMessage' => {
                  'title' => '{{form_title}}',
                  'subtitle' => 'Please fill out the form below'
                },
                'replyMessage' => {
                  'title' => 'Thank you!',
                  'subtitle' => 'Your information has been submitted'
                },
                'fields' => '{{fields}}'
              }
            }
          ],
          channel_mappings: [
            {
              channel_type: 'apple_messages_for_business',
              content_type: 'apple_form',
              field_mappings: {
                'receivedMessage.title' => '{{form_title}}',
                'fields' => '{{fields}}'
              }
            }
          ],
          original_id: 'example_form',
          original_data: { source: 'example_template' }
        }
      end

      def rich_link_template
        {
          name: 'Apple Messages - Rich Link',
          category: 'marketing',
          description: 'Rich link template for sharing content with preview',
          parameters: {
            'url' => {
              'type' => 'string',
              'required' => true,
              'description' => 'URL to share',
              'example' => 'https://example.com/product'
            },
            'title' => {
              'type' => 'string',
              'required' => true,
              'description' => 'Link title',
              'example' => 'Check out our new product'
            },
            'image_url' => {
              'type' => 'string',
              'required' => false,
              'description' => 'Preview image URL',
              'example' => 'https://example.com/image.jpg'
            }
          },
          supported_channels: ['apple_messages_for_business'],
          status: 'active',
          tags: %w[apple_messages rich_link marketing],
          use_cases: %w[content_sharing marketing],
          content_blocks: [
            {
              type: 'rich_link',
              properties: {
                'url' => '{{url}}',
                'title' => '{{title}}',
                'imageURL' => '{{image_url}}'
              }
            }
          ],
          channel_mappings: [
            {
              channel_type: 'apple_messages_for_business',
              content_type: 'rich_link',
              field_mappings: {
                'URL' => '{{url}}',
                'title' => '{{title}}',
                'imageURL' => '{{image_url}}'
              }
            }
          ],
          original_id: 'example_rich_link',
          original_data: { source: 'example_template' }
        }
      end
    end
  end
end
