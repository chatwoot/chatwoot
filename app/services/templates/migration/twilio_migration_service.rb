# frozen_string_literal: true

module Templates
  module Migration
    class TwilioMigrationService < BaseMigrationService
      def migrate
        log_info 'Starting Twilio template migration...'

        ActiveRecord::Base.transaction do
          Channel::TwilioSms.find_each do |channel|
            migrate_channel_templates(channel)
          end
        rescue StandardError => e
          log_error 'Migration failed, rolling back', e
          raise ActiveRecord::Rollback
        end

        log_info "Migration completed: #{@stats[:migrated]} migrated, #{@stats[:skipped]} skipped, #{@stats[:failed]} failed"
        @stats
      end

      def rollback
        count = MessageTemplate.where("metadata->>'migration_source' = ?", migration_source).count
        MessageTemplate.where("metadata->>'migration_source' = ?", migration_source).destroy_all

        log_info "Rolled back #{count} Twilio templates"
        { deleted: count }
      end

      protected

      def migration_source
        'twilio_migration'
      end

      private

      def migrate_channel_templates(channel)
        return if channel.content_templates.blank?

        log_info "Processing channel #{channel.id} (#{channel.phone_number || channel.messaging_service_sid})"

        channel.content_templates.each do |template_id, template_data|
          increment_total
          migrate_single_template(channel, template_id, template_data)
        end
      rescue StandardError => e
        log_error "Error processing channel #{channel.id}", e
        increment_failed
      end

      def migrate_single_template(channel, template_id, template_data)
        inbox = channel.inbox
        account_id = inbox.account_id

        template_name = sanitize_template_name(
          template_data['friendly_name'] || template_data['name'] || "twilio_#{template_id}"
        )

        # Skip if already migrated
        if template_exists?(account_id, template_name)
          log_skip "Template '#{template_name}' already exists"
          increment_skipped
          return
        end

        # Parse Twilio content template structure
        parsed_template = parse_twilio_template(template_data, template_id, template_name, channel)

        # Create unified template
        template = create_template(account_id, parsed_template)

        log_success "Migrated template '#{template_name}' (ID: #{template.id})"
        increment_success
      rescue StandardError => e
        log_error "Failed to migrate template '#{template_name}'", e
        increment_failed
      end

      def parse_twilio_template(template_data, template_id, template_name, channel)
        # Twilio Content API structure
        # https://www.twilio.com/docs/content-api
        types = template_data['types'] || {}
        language = template_data['language'] || 'en'
        variables = template_data['variables'] || {}

        # Determine channel type
        supported_channels = determine_supported_channels(types, channel)

        # Extract parameters
        parameters = extract_parameters(variables)

        # Build content blocks
        content_blocks = build_content_blocks(types, variables)

        # Determine category
        category = determine_category_from_types(types)

        {
          name: template_name,
          category: category,
          description: "Twilio content template (Language: #{language})",
          parameters: parameters,
          supported_channels: supported_channels,
          status: 'active',
          tags: ['twilio', language, channel.medium].compact,
          use_cases: [channel.medium, category].compact,
          content_blocks: content_blocks,
          channel_mappings: build_channel_mappings(types, channel, template_data),
          original_id: template_id,
          original_data: template_data
        }
      end

      def determine_supported_channels(types, channel)
        channels = []

        # Map Twilio content types to channel types
        if types['twilio/text'] || types['text']
          channels << 'sms' if channel.sms?
          channels << 'whatsapp' if channel.whatsapp?
        end

        if types['twilio/media']
          channels << 'sms' if channel.sms?
          channels << 'whatsapp' if channel.whatsapp?
        end

        channels << 'whatsapp' if (types['twilio/quick-reply']) && channel.whatsapp?

        channels << 'whatsapp' if types['twilio/list-picker'] || types['twilio/call-to-action']

        channels.uniq.presence || ['sms']
      end

      def extract_parameters(variables)
        parameters = {}

        variables.each do |var_name, var_config|
          parameters[var_name] = {
            'type' => map_variable_type(var_config['type']),
            'required' => var_config['required'] || false,
            'description' => var_config['description'] || "Variable #{var_name}",
            'example' => var_config['example']
          }.compact
        end

        parameters
      end

      def map_variable_type(twilio_type)
        type_map = {
          'text' => 'string',
          'number' => 'number',
          'boolean' => 'boolean',
          'date' => 'datetime',
          'url' => 'string',
          'phone_number' => 'string'
        }

        type_map[twilio_type&.downcase] || 'string'
      end

      def build_content_blocks(types, _variables)
        blocks = []

        # Process each content type
        blocks << build_text_block(types['twilio/text'] || types['text']) if types['twilio/text'] || types['text']

        blocks << build_media_block(types['twilio/media']) if types['twilio/media']

        blocks << build_quick_reply_block(types['twilio/quick-reply']) if types['twilio/quick-reply']

        blocks << build_list_picker_block(types['twilio/list-picker']) if types['twilio/list-picker']

        blocks << build_call_to_action_block(types['twilio/call-to-action']) if types['twilio/call-to-action']

        blocks.compact
      end

      def build_text_block(text_config)
        {
          type: 'text',
          properties: {
            'content' => text_config['body'] || text_config['text'] || ''
          }
        }
      end

      def build_media_block(media_config)
        {
          type: 'media',
          properties: {
            'media_url' => media_config['url'],
            'media_type' => media_config['type']
          }.compact
        }
      end

      def build_quick_reply_block(quick_reply_config)
        {
          type: 'quick_reply',
          properties: {
            'body' => quick_reply_config['body'],
            'actions' => quick_reply_config['actions'] || []
          }
        }
      end

      def build_list_picker_block(list_config)
        {
          type: 'list_picker',
          properties: {
            'body' => list_config['body'],
            'button' => list_config['button'],
            'items' => list_config['items'] || []
          }
        }
      end

      def build_call_to_action_block(cta_config)
        {
          type: 'button_group',
          properties: {
            'body' => cta_config['body'],
            'actions' => cta_config['actions'] || []
          }
        }
      end

      def determine_category_from_types(types)
        return 'notification' if types['twilio/text']
        return 'support' if types['twilio/quick-reply']
        return 'marketing' if types['twilio/call-to-action']

        nil
      end

      def build_channel_mappings(types, channel, template_data)
        mappings = []

        if channel.sms?
          mappings << {
            channel_type: 'sms',
            content_type: 'text',
            field_mappings: {
              'body' => '{{content}}'
            }
          }
        end

        mappings << build_whatsapp_mapping(types, template_data) if channel.whatsapp?

        mappings
      end

      def build_whatsapp_mapping(types, _template_data)
        if types['twilio/list-picker']
          {
            channel_type: 'whatsapp',
            content_type: 'interactive',
            field_mappings: {
              'type' => 'list',
              'body.text' => '{{body}}',
              'action.button' => '{{button}}',
              'action.sections' => '{{items}}'
            }
          }
        elsif types['twilio/quick-reply']
          {
            channel_type: 'whatsapp',
            content_type: 'interactive',
            field_mappings: {
              'type' => 'button',
              'body.text' => '{{body}}',
              'action.buttons' => '{{actions}}'
            }
          }
        else
          {
            channel_type: 'whatsapp',
            content_type: 'text',
            field_mappings: {
              'text.body' => '{{content}}'
            }
          }
        end
      end
    end
  end
end
