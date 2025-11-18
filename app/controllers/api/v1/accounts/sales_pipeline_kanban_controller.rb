class Api::V1::Accounts::SalesPipelineKanbanController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_sales_pipeline
  before_action :check_authorization

  def show
    @stages = @sales_pipeline.sales_pipeline_stages.includes(:label)
    @kanban_data = build_kanban_data
  end

  private

  def fetch_sales_pipeline
    @sales_pipeline = current_account.sales_pipelines.first_or_create!
  end

  def build_kanban_data
    stages = @sales_pipeline.sales_pipeline_stages.includes(:label).ordered
    stage_labels = stages.joins(:label).pluck('labels.title', 'sales_pipeline_stages.id').to_h

    base_conversations = current_account.conversations
    base_conversations = base_conversations.where(inbox_id: filter_params[:inbox_id]) if filter_params[:inbox_id].present?
    base_conversations = base_conversations.where(assignee_id: filter_params[:assignee_id]) if filter_params[:assignee_id].present?
    base_conversations = base_conversations.where(status: filter_params[:status]) if filter_params[:status].present?

    conversations_with_labels = base_conversations
      .joins(:labels)
      .where('tags.name IN (?)', stage_labels.keys)
      .includes(:contact, :assignee, :inbox)
      .limit(per_stage_limit * stages.count)

    kanban_columns = stages.map do |stage|
      conversations = conversations_with_labels.select do |conv|
        conv.labels.pluck(:name).include?(stage.label.title)
      end

      {
        stage_id: stage.id,
        name: stage.name,
        color: stage.color,
        position: stage.position,
        is_default: stage.is_default,
        is_closed_won: stage.is_closed_won,
        is_closed_lost: stage.is_closed_lost,
        cards: conversations.map { |conv| build_conversation_card(conv) }
      }
    end

    kanban_columns
  end

  def build_conversation_card(conversation)
    last_message = conversation.messages.order(:created_at).last

    {
      conversation_id: conversation.id,
      contact_name: conversation.contact&.name || 'Contato Sem Nome',
      inbox_name: conversation.inbox&.name,
      last_message_snippet: last_message&.content&.truncate(100),
      assignee_name: conversation.assignee&.available_name || 'Não atribuído',
      last_activity_at: conversation.last_activity_at,
      status: conversation.status,
      priority: conversation.priority,
      custom_attributes: conversation.custom_attributes
    }
  end

  def filter_params
    params.permit(:inbox_id, :assignee_id, :status, :limit)
  end

  def per_stage_limit
    filter_params[:limit].present? ? filter_params[:limit].to_i : 50
  end
end