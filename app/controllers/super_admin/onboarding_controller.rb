class SuperAdmin::OnboardingController < ApplicationController
  before_action :ensure_installation_onboarding

  def index; end

  def create
    begin
      AccountBuilder.new(
        account_name: onboarding_params.dig(:user, :company),
        user_full_name: onboarding_params.dig(:user, :name),
        email: onboarding_params.dig(:user, :email),
        user_password: params.dig(:user, :password),
        confirmed: true
      ).perform
    rescue StandardError => e
      redirect_to '/', flash: { error: e.message } and return
    end
    finish_onboarding
    redirect_to '/'
  end

  private

  def onboarding_params
    params.permit(:allow_contact, :subscribe_newsletter, user: [:name, :company, :email])
  end

  def finish_onboarding
    ::Redis::Alfred.delete(::Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
    ChatwootHub.register_instance(onboarding_params) if onboarding_params[:allow_contact] || onboarding_params[:subscribe_newsletter]
  end

  def ensure_installation_onboarding
    redirect_to '/' unless ::Redis::Alfred.get(::Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
  end
end
