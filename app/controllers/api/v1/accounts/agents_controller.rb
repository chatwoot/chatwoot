class Api::V1::Accounts::AgentsController < Api::V1::Accounts::BaseController
  before_action :fetch_agent, except: [:create, :index]
  before_action :check_authorization
  before_action :validate_limit, only: [:create]

  def index
    @agents = agents
  end

  def create
    builder = AgentBuilder.new(
      email: new_agent_params['email'],
      name: new_agent_params['name'],
      role: new_agent_params['role'],
      availability: new_agent_params['availability'],
      auto_offline: new_agent_params['auto_offline'],
      current_user: current_user,
      account: Current.account
    )
    @user = builder.perform

    head :ok
  end

  def update
    @agent.update!(agent_params.slice(:name).compact)
    @agent.current_account_user.update!(agent_params.slice(:role, :availability, :auto_offline).compact)
  end

  def destroy
    @agent.current_account_user.destroy!
    delete_user_record(@agent)
    head :ok
  end

  private

  def check_authorization
    super(User)
  end

  def fetch_agent
    @agent = agents.find(params[:id])
  end

  def agent_params
    params.require(:agent).permit(:name, :email, :name, :role, :availability, :auto_offline)
  end

  def new_agent_params
    params.require(:agent).permit(:email, :name, :role, :availability, :auto_offline)
  end

  def agents
    @agents ||= Current.account.users.order_by_full_name.includes(:account_users, { avatar_attachment: [:blob] })
  end

  def validate_limit
    render_payment_required('Account limit exceeded. Please purchase more licenses') if agents.count >= Current.account.usage_limits[:agents]
  end

  def delete_user_record(agent)
    DeleteObjectJob.perform_later(agent) if agent.reload.account_users.blank?
  end
end
