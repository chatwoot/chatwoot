class SuperAdmin::UsersController < SuperAdmin::ApplicationController
  SUPPRESSION_FLASH_TYPES = { not_suppressed: :notice, bounce: :alert, complaint: :error, unavailable: :alert }.freeze
  before_action :ensure_ses_suppression_configured, only: [:check_email_suppression, :clear_email_suppression, :send_test_email]

  # Overwrite any of the RESTful controller actions to implement custom behavior
  # For example, you may want to send an email after a foo is updated.

  def create
    resource = resource_class.new(resource_params)
    authorize_resource(resource)

    if resource.save
      redirect_to super_admin_user_path(resource), notice: translate_with_resource('create.success')
    else
      notice = resource.errors.full_messages.first
      redirect_to new_super_admin_user_path, notice: notice
    end
  end

  def update
    requested_resource.skip_reconfirmation! if resource_params[:confirmed_at].present?
    super
  end

  # Override this method to specify custom lookup behavior.
  # This will be used to set the resource for the `show`, `edit`, and `update`
  # actions.
  #
  # def find_resource(param)
  #   Foo.find_by!(slug: param)
  # end

  # The result of this lookup will be available as `requested_resource`

  # Override this if you have certain roles that require a subset
  # this will be used to set the records shown on the `index` action.
  #
  # def scoped_resource
  #   if current_user.super_admin?
  #     resource_class
  #   else
  #     resource_class.with_less_stuff
  #   end
  # end

  # Override `resource_params` if you want to transform the submitted
  # data before it's persisted. For example, the following would turn all
  # empty values into nil values. It uses other APIs such as `resource_class`
  # and `dashboard`:
  #

  def destroy_avatar
    avatar = requested_resource.avatar
    avatar.purge
    redirect_back(fallback_location: super_admin_users_path)
  end

  def resend_confirmation
    user = requested_resource
    if user.confirmed?
      redirect_back(fallback_location: super_admin_user_path(user), alert: I18n.t('super_admin.users.resend_confirmation.already_confirmed'))
    else
      return if redirect_if_email_blocked(user)

      user.send_confirmation_instructions
      redirect_back(fallback_location: super_admin_user_path(user), notice: I18n.t('super_admin.users.resend_confirmation.sent'))
    end
  end

  def check_email_suppression
    user = requested_resource
    redirect_with_suppression_result(user, Email::SesSuppressionService.new.lookup(user.email))
  end

  def clear_email_suppression
    user = requested_resource
    service = Email::SesSuppressionService.new
    result = service.lookup(user.email)
    return redirect_with_suppression_result(user, result) unless result[:status] == :bounce

    begin
      service.clear!(user.email)
    rescue StandardError => e
      message = I18n.t('super_admin.users.email_suppression.clear.failed',
                       email: ERB::Util.html_escape(user.email), error: ERB::Util.html_escape(e.message))
      return redirect_to super_admin_user_path(user), flash: { error: message }
    end

    log_email_diagnostic('ses_suppression_cleared', user)
    redirect_to super_admin_user_path(user),
                notice: I18n.t('super_admin.users.email_suppression.clear.success', email: ERB::Util.html_escape(user.email))
  end

  def send_test_email
    user = requested_resource
    return if redirect_if_email_blocked(user)

    EmailDeliveryTestMailer.delivery_test(user.email, user.name).deliver_later
    log_email_diagnostic('ses_test_email_sent', user)
    redirect_to super_admin_user_path(user),
                notice: I18n.t('super_admin.users.email_suppression.test_email.queued', email: ERB::Util.html_escape(user.email))
  end

  def scoped_resource
    resource_class.with_attached_avatar
  end

  def resource_params
    permitted_params = super
    permitted_params.delete(:password) if permitted_params[:password].blank?
    permitted_params
  end

  # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
  # for more information
  def find_resource(param)
    super.becomes(User)
  end

  private

  def redirect_if_email_blocked(user)
    return false unless Email::SesSuppressionService.configured?

    result = Email::SesSuppressionService.new.lookup(user.email)
    return false unless result[:status].in?(%i[bounce complaint])

    redirect_with_suppression_result(user, result)
    true
  end

  def redirect_with_suppression_result(user, result)
    message = I18n.t("super_admin.users.email_suppression.check.#{result[:status]}",
                     email: ERB::Util.html_escape(user.email), since: suppressed_since(result[:since]))
    redirect_to super_admin_user_path(user, suppression: result[:status]), flash: { SUPPRESSION_FLASH_TYPES.fetch(result[:status]) => message }
  end

  def suppressed_since(time)
    return if time.blank?

    "#{time.utc.strftime('%-d %b %Y')} (#{helpers.time_ago_in_words(time)} ago)"
  end

  def ensure_ses_suppression_configured
    head :not_found unless Email::SesSuppressionService.configured?
  end

  def log_email_diagnostic(event, user)
    Rails.logger.info({
      event: event,
      super_admin_id: current_super_admin.id,
      super_admin_email: current_super_admin.email,
      user_id: user.id,
      email: user.email,
      at: Time.current.utc.iso8601
    }.to_json)
  end
end
