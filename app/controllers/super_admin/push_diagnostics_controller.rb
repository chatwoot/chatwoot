class SuperAdmin::PushDiagnosticsController < SuperAdmin::ApplicationController
  def show
    @query = params[:user_query].to_s.strip
    @user = resolve_user(@query)
    @subscriptions = @user ? @user.notification_subscriptions.order(:id) : []
    @results = []
  end

  def create
    @user = User.find_by(id: params[:user_id])
    return redirect_to super_admin_push_diagnostics_path, alert: I18n.t('super_admin.push_diagnostics.user_not_found') if @user.nil?

    ids = parsed_subscription_ids
    if ids.empty?
      return redirect_to super_admin_push_diagnostics_path(user_query: @user.id),
                         alert: I18n.t('super_admin.push_diagnostics.no_subscriptions_to_test')
    end

    run_test_and_render(ids)
  end

  def destroy_subscriptions
    user = User.find_by(id: params[:user_id])
    return redirect_to super_admin_push_diagnostics_path, alert: I18n.t('super_admin.push_diagnostics.user_not_found') if user.nil?

    ids = parsed_subscription_ids
    if ids.empty?
      return redirect_to super_admin_push_diagnostics_path(user_query: user.id),
                         alert: I18n.t('super_admin.push_diagnostics.no_subscriptions_to_delete')
    end

    deleted_count = user.notification_subscriptions.where(id: ids).destroy_all.size
    log_super_admin_action("deleted #{deleted_count} subscriptions for user #{user.id}: #{ids}")
    redirect_to super_admin_push_diagnostics_path(user_query: user.id),
                notice: I18n.t('super_admin.push_diagnostics.subscriptions_deleted', count: deleted_count)
  end

  private

  def run_test_and_render(ids)
    @query = @user.id.to_s
    @subscriptions = @user.notification_subscriptions.order(:id)
    @results = Notification::PushTestService.new(
      user: @user, subscription_ids: ids,
      title: params[:push_title], body: params[:push_body]
    ).perform

    log_super_admin_action("test sent for user #{@user.id} subscriptions #{ids}")
    render :show
  end

  def log_super_admin_action(message)
    Rails.logger.info(
      "[SuperAdmin] push diagnostics #{message} " \
      "(actor_id=#{current_super_admin&.id}, actor_email=#{current_super_admin&.email})"
    )
  end

  def resolve_user(query)
    return if query.blank?

    query.match?(/\A\d+\z/) ? User.find_by(id: query) : User.from_email(query)
  end

  def parsed_subscription_ids
    Array(params[:subscription_ids]).reject(&:blank?).map(&:to_i)
  end
end
