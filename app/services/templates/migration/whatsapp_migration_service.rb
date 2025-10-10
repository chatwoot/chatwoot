# frozen_string_literal: true

module Templates
  module Migration
    class WhatsappMigrationService < BaseMigrationService
      def migrate
        log_info 'Starting WhatsApp template migration...'

        ActiveRecord::Base.transaction do
          Channel::Whatsapp.find_each do |channel|
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

        log_info "Rolled back #{count} WhatsApp templates"
        { deleted: count }
      end

      protected

      def migration_source
        'whatsapp_migration'
      end

      private

      def migrate_channel_templates(channel)
        return if channel.message_templates.blank?

        log_info "Processing channel #{channel.id} (#{channel.phone_number})"

        channel.message_templates.each do |template_id, template_data|
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
          template_data['name'] || template_data['template_name'] || "whatsapp_#{template_id}"
        )

        # Skip if already migrated
        if template_exists?(account_id, template_name)
          log_skip "Template '#{template_name}' already exists"
          increment_skipped
          return
        end

        # Parse WhatsApp template structure
        parsed_template = parse_whatsapp_template(template_data, template_id, template_name)

        # Create unified template
        template = create_template(account_id, parsed_template)

        log_success "Migrated template '#{template_name}' (ID: #{template.id})"
        increment_success
      rescue StandardError => e
        log_error "Failed to migrate template '#{template_name}'", e
        increment_failed
      end

      def parse_whatsapp_template(template_data, template_id, template_name)
        # WhatsApp template structure varies by provider
        # Common fields: name, language, status, category, components
        components = template_data['components'] || []
        language = template_data['language'] || 'en'
        status = template_data['status'] || 'APPROVED'
        category = template_data['category']&.downcase || 'marketing'

        # Extract parameters from components
        parameters = extract_parameters_from_components(components)

        # Build content blocks
        content_blocks = build_content_blocks_from_components(components)

        {
          name: template_name,
          category: map_whatsapp_category(category),
          description: "WhatsApp template (Language: #{language})",
          parameters: parameters,
          supported_channels: ['whatsapp'],
          status: status == 'APPROVED' ? 'active' : 'draft',
          tags: ['whatsapp', language, category].compact,
          use_cases: [category],
          content_blocks: content_blocks,
          channel_mappings: [
            {
              channel_type: 'whatsapp',
              content_type: 'template',
              field_mappings: build_whatsapp_field_mappings(template_data)
            }
          ],
          original_id: template_id,
          original_data: template_data
        }
      end

      def extract_parameters_from_components(components)
        parameters = {}

        components.each do |component|
          next unless component['type'] == 'BODY' || component['type'] == 'HEADER'

          text = component['text'] || ''

          # WhatsApp uses {{1}}, {{2}}, etc. for parameters
          text.scan(/\{\{(\d+)\}\}/).uniq.each do |match|
            param_name = "param_#{match[0]}"
            parameters[param_name] = {
              'type' => 'string',
              'required' => true,
              'description' => "Parameter #{match[0]} for #{component['type'].downcase}",
              'example' => "Value #{match[0]}"
            }
          end
        end

        parameters
      end

      def build_content_blocks_from_components(components)
        blocks = []

        components.each_with_index do |component, index|
          block = build_block_from_component(component, index)
          blocks << block if block
        end

        blocks
      end

      def build_block_from_component(component, index)
        case component['type']
        when 'HEADER'
          build_header_block(component, index)
        when 'BODY'
          build_body_block(component, index)
        when 'FOOTER'
          build_footer_block(component, index)
        when 'BUTTONS'
          build_buttons_block(component, index)
        end
      end

      def build_header_block(component, _index)
        if component['format'] == 'TEXT'
          {
            type: 'text',
            properties: {
              'content' => component['text'] || '',
              'style' => 'header'
            }
          }
        elsif component['format'] == 'IMAGE' || component['format'] == 'VIDEO' || component['format'] == 'DOCUMENT'
          {
            type: 'media',
            properties: {
              'media_type' => component['format'].downcase,
              'media_url' => component['example']&.dig('header_handle', 0)
            }
          }
        end
      end

      def build_body_block(component, _index)
        {
          type: 'text',
          properties: {
            'content' => component['text'] || '',
            'style' => 'body'
          }
        }
      end

      def build_footer_block(component, _index)
        {
          type: 'text',
          properties: {
            'content' => component['text'] || '',
            'style' => 'footer'
          }
        }
      end

      def build_buttons_block(component, _index)
        buttons = component['buttons'] || []

        {
          type: 'button_group',
          properties: {
            'buttons' => buttons.map do |button|
              {
                'type' => button['type']&.downcase,
                'text' => button['text'],
                'url' => button['url'],
                'phone_number' => button['phone_number']
              }.compact
            end
          }
        }
      end

      def map_whatsapp_category(whatsapp_category)
        # Map WhatsApp categories to unified template categories
        category_map = {
          'marketing' => 'marketing',
          'utility' => 'notification',
          'authentication' => 'notification',
          'service' => 'support',
          'payment' => 'payment'
        }

        category_map[whatsapp_category] || 'notification'
      end

      def build_whatsapp_field_mappings(template_data)
        {
          'template.name' => '{{name}}',
          'template.language.code' => template_data['language'] || 'en',
          'template.components' => '{{content_blocks}}'
        }
      end
    end
  end
end
