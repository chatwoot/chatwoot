# frozen_string_literal: true

module Templates
  module Migration
    class CannedResponseMigrationService < BaseMigrationService
      def migrate
        log_info 'Starting Canned Response migration...'
        log_info 'Converting canned responses to unified templates...'

        ActiveRecord::Base.transaction do
          CannedResponse.find_each do |canned_response|
            migrate_canned_response(canned_response)
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

        log_info "Rolled back #{count} Canned Response templates"
        log_info "Original canned_responses table remains untouched"
        { deleted: count }
      end

      protected

      def migration_source
        'canned_response_migration'
      end

      private

      def migrate_canned_response(canned_response)
        increment_total

        template_name = sanitize_template_name(canned_response.short_code)
        account_id = canned_response.account_id

        # Skip if already migrated
        if template_exists?(account_id, template_name)
          log_skip "Canned response '#{template_name}' already migrated"
          increment_skipped
          return
        end

        # Parse canned response
        parsed_template = parse_canned_response(canned_response)

        # Create unified template
        template = create_template(account_id, parsed_template)

        log_success "Migrated canned response '#{template_name}' (ID: #{template.id})"
        increment_success
      rescue StandardError => e
        log_error "Failed to migrate canned response '#{canned_response.short_code}'", e
        increment_failed
      end

      def parse_canned_response(canned_response)
        content = canned_response.content || ''

        # Extract variables from content (e.g., {{name}}, {{order_id}})
        variables = extract_variables(content)

        # Build parameters from variables
        parameters = build_parameters_from_variables(variables)

        # Determine category from content
        category = determine_category_from_content(content)

        # Extract tags from content
        tags = extract_tags_from_content(content)

        # Determine supported channels (canned responses work on all text-based channels)
        supported_channels = determine_supported_channels

        {
          name: canned_response.short_code,
          category: category,
          description: "Canned response: #{canned_response.short_code}",
          parameters: parameters,
          supported_channels: supported_channels,
          status: 'active',
          tags: tags + ['canned_response'],
          use_cases: [category, 'quick_reply'].compact,
          content_blocks: [
            {
              type: 'text',
              properties: {
                'content' => content
              }
            }
          ],
          channel_mappings: build_channel_mappings(content, supported_channels),
          original_id: canned_response.id,
          original_data: {
            'short_code' => canned_response.short_code,
            'content' => content,
            'created_at' => canned_response.created_at.iso8601,
            'updated_at' => canned_response.updated_at.iso8601
          }
        }
      end

      def extract_variables(content)
        # Match {{variable_name}} patterns
        content.scan(/\{\{([^}]+)\}\}/).flatten.uniq
      end

      def build_parameters_from_variables(variables)
        parameters = {}

        variables.each do |var_name|
          cleaned_name = var_name.strip

          parameters[cleaned_name] = {
            'type' => infer_variable_type(cleaned_name),
            'required' => false, # Canned responses don't enforce required params
            'description' => "Variable: #{cleaned_name}",
            'example' => generate_example_value(cleaned_name)
          }
        end

        parameters
      end

      def infer_variable_type(variable_name)
        # Infer type from variable name
        name_lower = variable_name.downcase

        return 'number' if name_lower.match?(/count|quantity|amount|price|total|id$/)
        return 'datetime' if name_lower.match?(/date|time|datetime|timestamp/)
        return 'boolean' if name_lower.match?(/is_|has_|can_|enabled|disabled/)
        return 'array' if name_lower.match?(/list|items|array/)

        'string' # Default to string
      end

      def generate_example_value(variable_name)
        name_lower = variable_name.downcase

        return 'John Doe' if name_lower.include?('name')
        return 'customer@example.com' if name_lower.include?('email')
        return '+1234567890' if name_lower.include?('phone')
        return '123' if name_lower.match?(/id$/)
        return '99.99' if name_lower.include?('price') || name_lower.include?('amount')
        return Time.current.iso8601 if name_lower.match?(/date|time/)

        "Example #{variable_name}"
      end

      def determine_supported_channels
        # Canned responses are text-based and work on most channels
        %w[
          web_widget
          email
          sms
          whatsapp
          telegram
          line
          twitter
          facebook
          apple_messages_for_business
        ]
      end

      def build_channel_mappings(content, supported_channels)
        mappings = []

        # Text-based channels use simple content mapping
        text_channels = %w[web_widget email sms telegram line twitter facebook]
        text_channels.each do |channel|
          next unless supported_channels.include?(channel)

          mappings << {
            channel_type: channel,
            content_type: 'text',
            field_mappings: {
              'content' => '{{content}}',
              'text' => '{{content}}',
              'body' => '{{content}}'
            }
          }
        end

        # WhatsApp uses specific text format
        if supported_channels.include?('whatsapp')
          mappings << {
            channel_type: 'whatsapp',
            content_type: 'text',
            field_mappings: {
              'text.body' => '{{content}}'
            }
          }
        end

        # Apple Messages uses text format
        if supported_channels.include?('apple_messages_for_business')
          mappings << {
            channel_type: 'apple_messages_for_business',
            content_type: 'text',
            field_mappings: {
              'text' => '{{content}}'
            }
          }
        end

        mappings
      end
    end
  end
end
