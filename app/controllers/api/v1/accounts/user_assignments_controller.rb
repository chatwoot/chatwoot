class Api::V1::Accounts::UserAssignmentsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    @user_assignments = Current.account.user_assignments
                               .includes(:user, :advanced_email_template)
                               .order('users.name')
  end

  def create
    @user_assignment = UserAssignment.new(user_assignment_params)
    @user_assignment.save!
    render json: @user_assignment, status: :created
  end

  def destroy
    @user_assignment = Current.account.user_assignments.find(params[:id])
    @user_assignment.destroy!
    head :no_content
  end

  def available_templates
    @templates = Current.account.advanced_email_templates.order(:friendly_name)
    render json: @templates.as_json(only: [:id, :name, :friendly_name, :description, :template_type])
  end

  private

  def check_authorization
    authorize(UserAssignment)
  end

  def user_assignment_params
    params.require(:user_assignment).permit(:advanced_email_template_id, :user_id, :active)
  end
end
