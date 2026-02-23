class Api::V1::Accounts::LocationsController < Api::V1::Accounts::BaseController
  include Sift

  sort_on :name, type: :string
  sort_on :type_name, type: :string
  sort_on :created_at, type: :datetime
  sort_on :updated_at, type: :datetime

  before_action :check_authorization
  before_action :location, only: [:show, :update, :destroy]

  def index
    @locations = Current.account.locations.includes(:address, :parent_locations)
  end

  def user_locations
    user_location = Current.account_user&.location
    @locations = user_location ? user_location.with_descendants.includes(:address, :parent_locations) : []
    render :index
  end

  def show; end

  def create
    @location = Current.account.locations.build(location_params)

    if @location.save
      assign_parent_locations
      render :show, status: :created
    else
      render json: { errors: @location.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @location.update(location_params)
      assign_parent_locations
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
    params.require(:location).permit(:name, :description, :type_name,
                                     address_attributes: %i[id street exterior_number interior_number neighborhood
                                                            postal_code city state email phone webpage
                                                            establishment_summary _destroy])
  end

  def assign_parent_locations
    # wrap_parameters only wraps model column attributes; has_many :through _ids stay at top level
    ids_param = params.dig(:location, :parent_location_ids) || params[:parent_location_ids]
    return if ids_param.nil?

    parent_ids = Array(ids_param).map(&:to_i).select(&:positive?)
    @location.location_hierarchies_as_child.where.not(parent_location_id: parent_ids).destroy_all
    parent_ids.each do |parent_id|
      @location.location_hierarchies_as_child.find_or_create_by!(
        parent_location_id: parent_id,
        account_id: Current.account.id
      )
    end
  end
end
