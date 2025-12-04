class Api::V1::Accounts::EmailTemplatesController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    @user_assignments = Current.user.user_assignments
                               .joins(:advanced_email_template)
                               .where(advanced_email_templates: { account_id: Current.account.id })
                               .includes(:advanced_email_template)
                               .order('advanced_email_templates.friendly_name')
  end

  def activate
    @user_assignment = Current.user.user_assignments.find(params[:id])
    authorize @user_assignment, :update?

    if @user_assignment.advanced_email_template.account_id != Current.account.id
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end

    @user_assignment.update!(active: true)
    head :ok
  end

  def deactivate
    @user_assignment = Current.user.user_assignments.find(params[:id])
    authorize @user_assignment, :update?

    if @user_assignment.advanced_email_template.account_id != Current.account.id
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end

    @user_assignment.update!(active: false)
    head :ok
  end

  private

  def check_authorization
    authorize(UserAssignment) if action_name == 'index'
  end
end
