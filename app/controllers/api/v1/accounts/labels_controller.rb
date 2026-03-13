class Api::V1::Accounts::LabelsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_label, except: [:index, :create]
  before_action :check_authorization

  def index
    @labels = policy_scope(Current.account.labels)
  end

  def show; end

  def create
    @label = Current.account.labels.create!(permitted_params)
  end

  def update
    @label.update!(permitted_params)
  end

  def destroy
    label_title = @label.title
    conversation_ids = @label.conversations.pluck(:id)
    contact_ids = Current.account.contacts.tagged_with(label_title).pluck(:id)
    tagging_ids = labels_taggings_for_cleanup(conversation_ids: conversation_ids, contact_ids: contact_ids)

    @label.destroy!
    Labels::RemoveAssociationsJob.perform_later(
      label_title: label_title,
      account_id: Current.account.id,
      tagging_ids: tagging_ids
    )
    head :ok
  end

  private

  def fetch_label
    @label = Current.account.labels.find(params[:id])
  end

  def permitted_params
    params.require(:label).permit(:title, :description, :color, :show_on_sidebar)
  end

  def labels_taggings_for_cleanup(conversation_ids:, contact_ids:)
    ActsAsTaggableOn::Tagging
      .where(context: 'labels')
      .where(
        '(taggings.taggable_type = :conversation AND taggings.taggable_id IN (:conversation_ids)) OR ' \
        '(taggings.taggable_type = :contact AND taggings.taggable_id IN (:contact_ids))',
        conversation: 'Conversation',
        contact: 'Contact',
        conversation_ids: conversation_ids,
        contact_ids: contact_ids
      )
      .pluck(:id)
  end
end
