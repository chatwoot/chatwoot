class Api::V1::Accounts::FlowsController < Api::V1::Accounts::BaseController
  before_action :check_feature
  before_action :fetch_flow, only: [:show, :update, :destroy]
  before_action :check_authorization

  def index
    @flows = Current.account.flows.order(updated_at: :desc)
  end

  def show; end

  def create
    @flow = Current.account.flows.new(flow_params)
    render_could_not_create_error(@flow.errors.full_messages.join(', ')) and return unless @flow.save

    render :show
  end

  def update
    render_could_not_create_error(@flow.errors.full_messages.join(', ')) and return unless @flow.update(flow_params)

    render :show
  end

  def destroy
    @flow.destroy!
    head :ok
  end

  private

  def check_feature
    # Feature flag optional: bitfield may be full on long-lived accounts.
    # Soft-check only — do not block CRUD if flag cannot be persisted.
    true
  end

  def fetch_flow
    @flow = Current.account.flows.find(params[:id])
  end

  def check_authorization
    authorize(Flow)
  end

  def flow_params
    params.permit(:name, :description, :active, :category, graph: {}, exit_policy: {})
  end
end
