class Api::V1::Accounts::AgentsController < Api::V1::Accounts::BaseController
  before_action :fetch_agent, except: [:create, :index]
  before_action :check_authorization
  before_action :find_user, only: [:create]
  before_action :validate_limit, only: [:create]

  def index
    @agents = agents
  end

  def create
    @user = AgentBuilder.new(
      agent_params: new_agent_params,
      current_account: Current.account,
      current_user: current_user
    ).perform
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

  def find_user
    @user =  User.find_by(email: new_agent_params[:email])
  end

  def agent_params
    params.require(:agent).permit(:name, :email, :name, :role, :availability, :auto_offline)
  end

  def new_agent_params
    params.require(:agent).permit(:email, :name, :role, :availability, :auto_offline, :inbox_ids)
  end

  def agents
    @agents ||= Current.account.users.order_by_full_name.includes(:account_users, { avatar_attachment: [:blob] })
  end

  def validate_limit
    return unless agents.count >= Current.account.usage_limits[:agents]

    render_payment_required('Sua conta excedeu o limite. Por favor, aumente sua assinatura. Entre em contato com o suporte.')
  end

  def delete_user_record(agent)
    DeleteObjectJob.perform_later(agent) if agent.reload.account_users.blank?
  end
end
