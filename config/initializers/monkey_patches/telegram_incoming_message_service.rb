# cat-fork: derive the contact's `project` custom attribute from the Telegram bot username.
# The first underscore-separated part of the bot name, minus the words listed in
# TELEGRAM_PROJECT_STRIP_WORDS (comma separated, default "casino"), becomes the project.
module TelegramIncomingProjectAttributePatch
  STRIP_WORDS = ENV.fetch('TELEGRAM_PROJECT_STRIP_WORDS', 'casino').split(',').map(&:strip).reject(&:empty?).freeze

  def perform
    super
    set_project_attribute_after_perform
  end

  private

  def set_project_attribute_after_perform
    return unless @contact

    project = project_from_bot_name(@inbox&.channel.try(:bot_name))
    return if project.blank?

    @contact.custom_attributes = (@contact.custom_attributes || {}).merge('project' => project)
    @contact.save!
  rescue StandardError => e
    Rails.logger.error "[TG PROJECT] ERROR: #{e.class} #{e.message}\n#{e.backtrace.first(5).join("\n")}"
  end

  def project_from_bot_name(bot_name)
    parts = bot_name.to_s.delete_prefix('@').split('_')
    parts.map { |part| STRIP_WORDS.reduce(part) { |acc, word| acc.gsub(/#{Regexp.escape(word)}/i, '') } }
         .reject(&:empty?)
         .first
  end
end

Rails.application.config.to_prepare do
  Telegram::IncomingMessageService.prepend(TelegramIncomingProjectAttributePatch)
end
