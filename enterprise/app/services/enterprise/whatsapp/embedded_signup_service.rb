# frozen_string_literal: true

module Enterprise::Whatsapp::EmbeddedSignupService
  def perform
    @account.inboxes.build.ensure_create_permitted if @inbox_id.blank?
    super
  end
end
