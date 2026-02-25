class Api::V1::Accounts::Contacts::NotesController < Api::V1::Accounts::Contacts::BaseController
  before_action :note, except: [:index, :create]

  def index
    @notes = @contact.notes.latest.includes(:user)
  end

  def show; end

  def create
    @note = @contact.notes.create!(note_params)
  end

  def update
    @note.update(note_params)
  end

  def destroy
    @note.destroy!
    head :ok
  end

  private

  def note
    @note ||= @contact.notes.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:content).merge({ contact_id: @contact.id, user_id: Current.user.id })
  end
end
