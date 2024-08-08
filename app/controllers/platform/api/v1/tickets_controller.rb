class Platform::Api::V1::TicketsController < PlatformController
  skip_before_action :validate_platform_app_permissible, only: %i[show create update]

  def index
    @resources = Ticket.all
    render json: @resources
  end

  def show
    render json: @resource
  end

  def create
    @resource = Ticket.new(ticket_params)
    @resource.save!

    render json: @resource
  end

  def update
    @resource.update!(ticket_params)

    render json: @resource
  end

  private

  def set_resource
    @resource = Ticket.find(params[:id])
  end

  def ticket_params
    request_params = params.require(:ticket).permit(:title, :description, :status, :assigned_to, :conversation_id)
    request_params[:conversation_id] = params.dig(:conversation, :id) if params.dig(:conversation, :id).present?
    request_params
  end
end
