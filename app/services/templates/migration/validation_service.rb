# frozen_string_literal: true

module Templates
  module Migration
    class ValidationService
      def validate_all
        {
          whatsapp: validate_whatsapp,
          twilio: validate_twilio,
          apple_messages: validate_apple_messages,
          canned_responses: validate_canned_responses
        }
      end

      def validate_whatsapp
        original_count = count_whatsapp_templates
        migrated_count = MessageTemplate.where("metadata->>'migration_source' = ?", 'whatsapp_migration').count

        errors = []
        errors << 'Mismatch in template count' if original_count != migrated_count

        # Validate channel mappings exist
        templates = MessageTemplate.where("metadata->>'migration_source' = ?", 'whatsapp_migration')
        templates.each do |template|
          errors << "Template #{template.id} missing WhatsApp channel mapping" unless template.channel_mappings.exists?(channel_type: 'whatsapp')
        end

        {
          status: errors.empty? ? 'valid' : 'invalid',
          original_count: original_count,
          migrated_count: migrated_count,
          errors: errors
        }
      end

      def validate_twilio
        original_count = count_twilio_templates
        migrated_count = MessageTemplate.where("metadata->>'migration_source' = ?", 'twilio_migration').count

        errors = []
        errors << 'Mismatch in template count' if original_count != migrated_count

        # Validate channel mappings exist
        templates = MessageTemplate.where("metadata->>'migration_source' = ?", 'twilio_migration')
        templates.each do |template|
          has_sms = template.channel_mappings.exists?(channel_type: 'sms')
          has_whatsapp = template.channel_mappings.exists?(channel_type: 'whatsapp')

          errors << "Template #{template.id} missing SMS/WhatsApp channel mapping" unless has_sms || has_whatsapp
        end

        {
          status: errors.empty? ? 'valid' : 'invalid',
          original_count: original_count,
          migrated_count: migrated_count,
          errors: errors
        }
      end

      def validate_apple_messages
        # Apple Messages creates example templates, not migrating existing data
        migrated_count = MessageTemplate.where("metadata->>'migration_source' = ?", 'apple_messages_migration').count
        channel_count = Channel::AppleMessagesForBusiness.count

        errors = []

        # Validate each migrated template has proper structure
        templates = MessageTemplate.where("metadata->>'migration_source' = ?", 'apple_messages_migration')
        templates.each do |template|
          errors << "Template #{template.id} missing content blocks" if template.content_blocks.empty?
          errors << "Template #{template.id} missing Apple Messages channel mapping" unless template.channel_mappings.exists?(channel_type: 'apple_messages_for_business')
        end

        {
          status: errors.empty? ? 'valid' : 'invalid',
          original_count: channel_count * 5, # 5 example templates per channel
          migrated_count: migrated_count,
          errors: errors
        }
      end

      def validate_canned_responses
        original_count = CannedResponse.count
        migrated_count = MessageTemplate.where("metadata->>'migration_source' = ?", 'canned_response_migration').count

        errors = []
        errors << 'Mismatch in template count' if original_count != migrated_count

        # Validate each canned response was migrated
        CannedResponse.find_each do |canned_response|
          unless MessageTemplate.exists?(
            account_id: canned_response.account_id,
            name: canned_response.short_code
          )
            errors << "Canned response '#{canned_response.short_code}' not migrated"
          end
        end

        # Validate migrated templates have text content blocks
        templates = MessageTemplate.where("metadata->>'migration_source' = ?", 'canned_response_migration')
        templates.each do |template|
          text_blocks = template.content_blocks.where(block_type: 'text')
          errors << "Template #{template.id} missing text content block" if text_blocks.empty?
        end

        {
          status: errors.empty? ? 'valid' : 'invalid',
          original_count: original_count,
          migrated_count: migrated_count,
          errors: errors
        }
      end

      private

      def count_whatsapp_templates
        total = 0

        Channel::Whatsapp.find_each do |channel|
          total += (channel.message_templates&.keys&.count || 0)
        end

        total
      end

      def count_twilio_templates
        total = 0

        Channel::TwilioSms.find_each do |channel|
          total += (channel.content_templates&.keys&.count || 0)
        end

        total
      end
    end
  end
end
