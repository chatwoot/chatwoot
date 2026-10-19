class Api::V1::Accounts::Inboxes::CallBusinessHoursController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox

  def update
    Voice::BusinessHoursSettingsService.new(
      inbox: @inbox,
      enabled: ActiveModel::Type::Boolean.new.cast(params[:business_hours_calls_enabled]),
      message: params[:out_of_hours_call_message],
      voicemail: ActiveModel::Type::Boolean.new.cast(params[:voicemail_enabled]) == true
    ).perform
    @inbox.update_account_cache # bump inbox cache key so the cached inbox list refetches the new settings
    render 'api/v1/accounts/inboxes/show'
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :set_call_business_hours?
    render_could_not_create_error('Inbox does not support calling') unless @inbox.channel.try(:voice_enabled?)
  end
end
