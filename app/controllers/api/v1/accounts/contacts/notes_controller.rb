class Api::V1::Accounts::Contacts::NotesController < Api::V1::Accounts::Contacts::BaseController
  before_action :note, except: [:index, :create]

  def index
    @notes = @contact.notes.latest.includes(:user, :updated_by)
  end

  def show; end

  def create
    @note = @contact.notes.create!(create_note_params)
  end

  def update
    @note.update!(update_note_params)
  end

  def destroy
    @note.destroy!
    head :ok
  end

  private

  def note
    @note ||= @contact.notes.find(params[:id])
  end

  def create_note_params
    permitted_note_params.merge(
      contact_id: @contact.id,
      user_id: Current.user.id,
      updated_by_id: Current.user.id
    )
  end

  def update_note_params
    permitted_note_params.merge(updated_by_id: Current.user.id)
  end

  def permitted_note_params
    params_source = params[:note].present? ? params.require(:note) : params
    params_source.permit(:content, metadata: {})
  end
end
