class Api::V1::Profile::InboxSignaturesController < Api::BaseController
  before_action :set_user
  before_action :set_inbox_signature, only: %i[show update destroy]
  before_action :validate_inbox_access, only: %i[show update destroy]

  def index
    if params[:account_id].present?
      validate_account_access!
      return if performed?

      @inbox_signatures = @user.inbox_signatures.joins(:inbox).where(inboxes: { account_id: params[:account_id] })
    else
      @inbox_signatures = @user.inbox_signatures
    end
  end

  def show
    head :not_found and return unless @inbox_signature
  end

  def update
    if @inbox_signature
      @inbox_signature.update!(inbox_signature_params)
    else
      @inbox_signature = @user.inbox_signatures.create!(
        inbox_signature_params.merge(inbox_id: params[:inbox_id])
      )
    end
  end

  def destroy
    @inbox_signature&.destroy!
    head :no_content
  end

  private

  def set_user
    @user = current_user
  end

  def set_inbox_signature
    @inbox_signature = @user.inbox_signatures.find_by(inbox_id: params[:inbox_id])
  end

  def inbox_signature_params
    params.require(:inbox_signature).permit(:message_signature, :signature_position, :signature_separator)
  end

  def validate_inbox_access
    inbox_id = params[:inbox_id]
    return if InboxMember.exists?(user_id: @user.id, inbox_id: inbox_id)

    head :unauthorized
  end

  def validate_account_access!
    account_id = params[:account_id]
    return if @user.account_ids.include?(account_id.to_i)

    head :unauthorized
  end
end
