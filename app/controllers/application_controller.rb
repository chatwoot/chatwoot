class ApplicationController < ActionController::Base
  include DeviseTokenAuth::Concerns::SetUserByToken
  include RequestExceptionHandler
  include Pundit::Authorization
  include SwitchLocale

  skip_before_action :verify_authenticity_token

  before_action :set_current_user, unless: :devise_controller?
  after_action :touch_current_employee_session, unless: :devise_controller?
  around_action :switch_locale
  around_action :handle_with_exception, unless: :devise_controller?

  private

  def set_current_user
    @user ||= current_user
    Current.user = @user
  end

  def touch_current_employee_session
    return unless Current.user&.local_employee?

    client_id = request.headers[DeviseTokenAuth.headers_names[:client]] || request.headers['client']
    return if client_id.blank?

    Current.user.employee_sessions.where(client_id: client_id).open.find_each do |employee_session|
      employee_session.update!(last_seen_at: Time.current)
    end
  end

  def pundit_user
    {
      user: Current.user,
      account: Current.account,
      account_user: Current.account_user
    }
  end
end
ApplicationController.include_mod_with('Concerns::ApplicationControllerConcern')
