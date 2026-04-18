class SuperAdmin::PushDiagnosticsController < SuperAdmin::ApplicationController
  def show
    @query = params[:user_query].to_s.strip
    @user = resolve_user(@query)
    @subscriptions = @user ? @user.notification_subscriptions.order(:id) : []
    @results = []
  end

  def create
    @user = User.find_by(id: params[:user_id])
    return redirect_to super_admin_push_diagnostics_path, alert: 'User not found.' if @user.nil? # rubocop:disable Rails/I18nLocaleTexts

    ids = Array(params[:subscription_ids]).reject(&:blank?).map(&:to_i)
    if ids.empty?
      return redirect_to super_admin_push_diagnostics_path(user_query: @user.id),
                         alert: 'Select at least one subscription to test.' # rubocop:disable Rails/I18nLocaleTexts
    end

    run_test_and_render(ids)
  end

  def destroy_subscriptions
    user = User.find_by(id: params[:user_id])
    return redirect_to super_admin_push_diagnostics_path, alert: 'User not found.' if user.nil? # rubocop:disable Rails/I18nLocaleTexts

    ids = Array(params[:subscription_ids]).reject(&:blank?).map(&:to_i)
    if ids.empty?
      return redirect_to super_admin_push_diagnostics_path(user_query: user.id),
                         alert: 'Select at least one subscription to delete.' # rubocop:disable Rails/I18nLocaleTexts
    end

    deleted_count = user.notification_subscriptions.where(id: ids).destroy_all.size
    Rails.logger.info "[SuperAdmin] push diagnostics deleted #{deleted_count} subscriptions for user #{user.id}: #{ids}"
    redirect_to super_admin_push_diagnostics_path(user_query: user.id),
                notice: "Deleted #{deleted_count} subscription(s). The user's device(s) will re-register on next app launch."
  end

  private

  def run_test_and_render(ids)
    @query = @user.id.to_s
    @subscriptions = @user.notification_subscriptions.order(:id)
    @results = Notification::PushTestService.new(
      user: @user, subscription_ids: ids,
      title: params[:push_title], body: params[:push_body]
    ).perform

    Rails.logger.info "[SuperAdmin] push diagnostics test sent for user #{@user.id} subscriptions #{ids}"
    render :show
  end

  def resolve_user(query)
    return if query.blank?

    query.match?(/\A\d+\z/) ? User.find_by(id: query) : User.from_email(query)
  end
end
