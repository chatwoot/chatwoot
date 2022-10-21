class Api::V1::Accounts::MacrosController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_macro, only: [:show, :update, :destroy, :execute]

  def index
    @macros = Macro.with_visibility(current_user, params)
  end

  def create
    @macro = Current.account.macros.new(macros_with_user.merge(created_by_id: current_user.id))
    @macro.set_visibility(current_user, permitted_params)
    @macro.actions = params[:actions]

    render json: { error: @macro.errors.messages }, status: :unprocessable_entity and return unless @macro.valid?

    @macro.save!
    process_attachments
    @macro
  end

  def show
    head :not_found if @macro.nil?
  end

  def destroy
    @macro.destroy!
    head :ok
  end

  def attach_file
    file_blob = ActiveStorage::Blob.create_and_upload!(
      key: nil,
      io: params[:attachment].tempfile,
      filename: params[:attachment].original_filename,
      content_type: params[:attachment].content_type
    )
    render json: { blob_key: file_blob.key, blob_id: file_blob.id }
  end

  def update
    ActiveRecord::Base.transaction do
      @macro.update!(macros_with_user)
      @macro.set_visibility(current_user, permitted_params)
      process_attachments
      @macro.save!
    rescue StandardError => e
      Rails.logger.error e
      render json: { error: @macro.errors.messages }.to_json, status: :unprocessable_entity
    end
  end

  def execute
    ::MacrosExecutionJob.perform_later(@macro, conversation_ids: params[:conversation_ids], user: Current.user)

    head :ok
  end

  def process_attachments
    actions = @macro.actions.filter_map { |k, _v| k if k['action_name'] == 'send_attachment' }
    return if actions.blank?

    actions.each do |action|
      blob_id = action['action_params']
      blob = ActiveStorage::Blob.find_by(id: blob_id)
      @macro.files.attach(blob)
    end
  end

  def permitted_params
    params.permit(
      :name, :account_id, :visibility,
      actions: [:action_name, { action_params: [] }]
    )
  end

  def macros_with_user
    permitted_params.merge(updated_by_id: current_user.id)
  end

  def fetch_macro
    @macro = Current.account.macros.find_by(id: params[:id])
  end
end
