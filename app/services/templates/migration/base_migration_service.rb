# frozen_string_literal: true

module Templates
  module Migration
    class BaseMigrationService
      attr_reader :stats, :errors

      def initialize
        @stats = { total: 0, migrated: 0, failed: 0, skipped: 0 }
        @errors = []
      end

      def migrate
        raise NotImplementedError, 'Subclasses must implement #migrate'
      end

      def rollback
        raise NotImplementedError, 'Subclasses must implement #rollback'
      end

      protected

      def migration_source
        raise NotImplementedError, 'Subclasses must implement #migration_source'
      end

      def log_success(message)
        Rails.logger.info "[TemplatesMigration] ✓ #{message}"
        puts "  ✓ #{message}"
      end

      def log_error(message, exception = nil)
        error_msg = exception ? "#{message}: #{exception.message}" : message
        Rails.logger.error "[TemplatesMigration] ❌ #{error_msg}"
        puts "  ❌ #{error_msg}"
        @errors << error_msg
      end

      def log_skip(message)
        Rails.logger.info "[TemplatesMigration] ⏭️  #{message}"
        puts "  ⏭️  #{message}"
      end

      def log_info(message)
        Rails.logger.info "[TemplatesMigration] ℹ️  #{message}"
        puts "  ℹ️  #{message}"
      end

      def template_exists?(account_id, name)
        MessageTemplate.exists?(
          account_id: account_id,
          name: name
        )
      end

      def create_template(account_id, template_data)
        MessageTemplate.create!(
          account_id: account_id,
          name: template_data[:name],
          category: template_data[:category],
          description: template_data[:description],
          parameters: template_data[:parameters] || {},
          supported_channels: template_data[:supported_channels] || [],
          status: template_data[:status] || 'active',
          tags: template_data[:tags] || [],
          use_cases: template_data[:use_cases] || [],
          metadata: build_metadata(template_data)
        ).tap do |template|
          # Create content blocks
          template_data[:content_blocks]&.each_with_index do |block_data, index|
            template.content_blocks.create!(
              block_type: block_data[:type],
              properties: block_data[:properties] || {},
              conditions: block_data[:conditions] || {},
              order_index: index
            )
          end

          # Create channel mappings
          template_data[:channel_mappings]&.each do |mapping_data|
            template.channel_mappings.create!(
              channel_type: mapping_data[:channel_type],
              content_type: mapping_data[:content_type],
              field_mappings: mapping_data[:field_mappings] || {}
            )
          end
        end
      end

      def build_metadata(template_data)
        {
          migration_source: migration_source,
          migrated_at: Time.current.iso8601,
          original_id: template_data[:original_id],
          original_data: template_data[:original_data],
          migration_version: '1.0'
        }.compact
      end

      def increment_success
        @stats[:migrated] += 1
      end

      def increment_failed
        @stats[:failed] += 1
      end

      def increment_skipped
        @stats[:skipped] += 1
      end

      def increment_total
        @stats[:total] += 1
      end

      def sanitize_template_name(name)
        name.to_s.strip.presence || 'Unnamed Template'
      end

      def extract_tags_from_content(content)
        tags = []

        # Extract common keywords
        tags << 'greeting' if content.match?(/hello|hi|hey|welcome/i)
        tags << 'closing' if content.match?(/thanks|regards|goodbye|bye/i)
        tags << 'support' if content.match?(/help|support|assist/i)
        tags << 'payment' if content.match?(/payment|invoice|bill/i)
        tags << 'appointment' if content.match?(/appointment|schedule|booking/i)
        tags << 'order' if content.match?(/order|purchase|delivery/i)

        tags.uniq
      end

      def determine_category_from_content(content)
        return 'support' if content.match?(/help|support|assist|issue|problem/i)
        return 'payment' if content.match?(/payment|invoice|bill|pay|charge/i)
        return 'scheduling' if content.match?(/appointment|schedule|booking|meet/i)
        return 'notification' if content.match?(/notify|alert|update|status/i)
        return 'marketing' if content.match?(/offer|discount|sale|promo/i)
        return 'confirmation' if content.match?(/confirm|verified|approved/i)

        nil # No specific category
      end
    end
  end
end
