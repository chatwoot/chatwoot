class Platform::Api::V1::TicketsController < PlatformController
  include Api::V2::Tickets::TicketHelper

  skip_before_action :validate_platform_app_permissible, only: %i[show create update]

  def index
    @resources = Ticket.all
    render json: @resources
  end

  def show
    render json: @resource
  end

  def create
    render json: build_ticket
  end

  def update
    render json: update_ticket(@resource)
  end

  private

  def set_resource
    @resource = Ticket.find(params[:id])
  end
end
