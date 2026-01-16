class Api::V1::Accounts::LocationsController < Api::V1::Accounts::BaseController
  include Sift

  sort_on :name, type: :string
  sort_on :type_name, type: :string
  sort_on :created_at, type: :datetime
  sort_on :updated_at, type: :datetime

  before_action :check_authorization
  before_action :location, only: [:show, :update, :destroy]

  def index
    @locations = Current.account.locations.includes(:address, :parent_location)
  end

  def show; end

  def create
    @location = Current.account.locations.build(location_params)

    if @location.save
      render :show, status: :created
    else
      render json: { errors: @location.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @location.update(location_params)
      render :show
    else
      render json: { errors: @location.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @location.destroy!
    head :ok
  end

  private

  def location
    @location ||= Current.account.locations.find(params[:id])
  end

  def location_params
    params.require(:location).permit(
      :name,
      :description,
      :type_name,
      :parent_location_id,
      address_attributes: [
        :id,
        :street,
        :exterior_number,
        :interior_number,
        :neighborhood,
        :postal_code,
        :city,
        :state,
        :email,
        :phone,
        :webpage,
        :establishment_summary,
        :_destroy
      ]
    )
  end
end
