Rails.application.config.to_prepare do
  unless Telegram::IncomingMessageService.method_defined?(:original_perform)
    Telegram::IncomingMessageService.class_eval do
      alias_method :original_perform, :perform

      def perform
        original_perform
        set_project_attribute_after_perform
      end

      private

      def set_project_attribute_after_perform
        return unless @contact
        return unless @inbox&.channel

        bot_name = @inbox.channel.try(:bot_name)
        prefix = bot_name.to_s.delete_prefix('@').split('_').first
        return if prefix.blank?

        @contact.custom_attributes ||= {}
        @contact.custom_attributes['project'] = prefix
        @contact.save!
      rescue StandardError => e
        Rails.logger.error "[TG PROJECT] ERROR: #{e.class} #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      end
    end
  end
end
