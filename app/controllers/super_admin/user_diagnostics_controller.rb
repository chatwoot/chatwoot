class SuperAdmin::UserDiagnosticsController < SuperAdmin::ApplicationController
  TABS = %w[push mobile].freeze
  # X-Chatwoot-Client-Name value sent by the mobile app.
  MOBILE_CLIENT_NAME = 'Chatwoot Mobile'.freeze

  def show
    @tab = TABS.include?(params[:tab]) ? params[:tab] : TABS.first
    @query = params[:user_query].to_s.strip
    @user = resolve_user(@query)
    load_diagnostics
    @results = []
  end

  def create
    @user = User.find_by(id: params[:user_id])
    return redirect_to super_admin_user_diagnostics_path, alert: I18n.t('super_admin.user_diagnostics.user_not_found') if @user.nil?

    ids = parsed_subscription_ids
    if ids.empty?
      return redirect_to super_admin_user_diagnostics_path(user_query: @user.id, tab: 'push'),
                         alert: I18n.t('super_admin.user_diagnostics.push.no_subscriptions_to_test')
    end

    run_test_and_render(ids)
  end

  def destroy_subscriptions
    user = User.find_by(id: params[:user_id])
    return redirect_to super_admin_user_diagnostics_path, alert: I18n.t('super_admin.user_diagnostics.user_not_found') if user.nil?

    ids = parsed_subscription_ids
    if ids.empty?
      return redirect_to super_admin_user_diagnostics_path(user_query: user.id, tab: 'push'),
                         alert: I18n.t('super_admin.user_diagnostics.push.no_subscriptions_to_delete')
    end

    deleted_count = user.notification_subscriptions.where(id: ids).destroy_all.size
    log_super_admin_action("deleted #{deleted_count} subscriptions for user #{user.id}: #{ids}")
    redirect_to super_admin_user_diagnostics_path(user_query: user.id, tab: 'push'),
                notice: I18n.t('super_admin.user_diagnostics.push.subscriptions_deleted', count: deleted_count)
  end

  private

  def load_diagnostics
    @subscriptions = @user ? @user.notification_subscriptions.order(:id) : []
    @mobile_sessions, web_sessions = sessions_for_user.partition { |session| session.browser_name == MOBILE_CLIENT_NAME }
    @web_session_count = web_sessions.size
    @notification_settings = @user ? @user.notification_settings.includes(:account).order(:account_id) : []
    @push_types = helpers.push_types(@notification_settings)
    @accounts_without_push = @notification_settings.reject { |setting| helpers.any_push_enabled?(setting, @push_types) }
  end

  def run_test_and_render(ids)
    @tab = 'push'
    @query = @user.id.to_s
    load_diagnostics
    @results = Notification::PushTestService.new(
      user: @user, subscription_ids: ids,
      title: params[:push_title], body: params[:push_body]
    ).perform

    log_super_admin_action("test sent for user #{@user.id} subscriptions #{ids}")
    render :show
  end

  def log_super_admin_action(message)
    Rails.logger.info(
      "[SuperAdmin] user diagnostics #{message} " \
      "(actor_id=#{current_super_admin&.id}, actor_email=#{current_super_admin&.email})"
    )
  end

  def sessions_for_user
    return [] if @user.nil?

    @user.user_sessions.order(Arel.sql('COALESCE(last_activity_at, created_at) DESC'))
  end

  def resolve_user(query)
    return if query.blank?

    query.match?(/\A\d+\z/) ? User.find_by(id: query) : User.from_email(query)
  end

  def parsed_subscription_ids
    Array(params[:subscription_ids]).reject(&:blank?).map(&:to_i)
  end
end
