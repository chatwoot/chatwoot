class Platform::Api::V1::InboxesController < PlatformController
  before_action :set_account
  before_action :validate_account_permissible
  before_action :set_inbox

  def disable
    update_active_state(false)
  end

  def enable
    update_active_state(true)
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end

  def validate_account_permissible
    return if @platform_app.platform_app_permissibles.find_by(permissible: @account)

    render json: { error: 'Non permissible resource' }, status: :unauthorized
  end

  def set_inbox
    @inbox = @account.inboxes.find(params[:id])
  end

  def update_active_state(active)
    @inbox.update!(active: active)
    render json: { success: true, inbox_id: @inbox.id, active: @inbox.active }
  end
end
