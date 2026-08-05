class Api::V1::Accounts::SenderListEntriesController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    @sender_list_entries = Current.account.sender_list_entries.order(:list_type, :value)
  end

  # Accepts a batch of values for a single list. A value already present in another list is moved,
  # invalid values are reported back individually so the rest of the batch still lands.
  def create
    return render json: { error: 'Invalid list_type' }, status: :unprocessable_entity unless valid_list_type?

    @entries = []
    @errors = []
    Array(permitted_params[:values]).each { |value| upsert_entry(value) }
  end

  def destroy
    Current.account.sender_list_entries.find(params[:id]).destroy!
    head :no_content
  end

  private

  def valid_list_type?
    SenderListEntry.list_types.key?(permitted_params[:list_type])
  end

  def upsert_entry(value)
    entry = Current.account.sender_list_entries.find_or_initialize_by(value: SenderListEntry.normalize(value))
    entry.list_type = permitted_params[:list_type]

    if entry.save
      @entries << entry
    else
      @errors << { value: value, message: entry.errors.full_messages.to_sentence }
    end
  end

  def permitted_params
    params.permit(:list_type, values: [])
  end
end
