class Api::V1::Accounts::Inboxes::EvolutionGoController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :validate_evolution_go_channel
  before_action :authorize_inbox_action!

  def show
    render json: EvolutionGo::SyncStateService.new(channel: @inbox.channel).perform
  end

  def create
    render json: EvolutionGo::ProvisionService.new(channel: @inbox.channel).perform
  rescue EvolutionGo::Client::Error, EvolutionGo::Client::ConfigurationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    EvolutionGo::ProvisionService.new(channel: @inbox.channel).cancel_pairing
    render json: EvolutionGo::SyncStateService.new(channel: @inbox.channel).perform
  rescue EvolutionGo::Client::Error, EvolutionGo::Client::ConfigurationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def authorize_inbox_action!
    policy_method = action_name == 'show' ? :show? : :update?
    authorize @inbox, policy_method
  end

  def validate_evolution_go_channel
    return if @inbox.channel.is_a?(Channel::Whatsapp) && @inbox.channel.provider == 'evolution_go'

    render json: { error: 'Inbox is not an Evolution Go WhatsApp channel' }, status: :bad_request
  end
end
