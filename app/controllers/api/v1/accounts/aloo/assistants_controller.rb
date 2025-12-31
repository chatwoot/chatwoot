# frozen_string_literal: true

class Api::V1::Accounts::Aloo::AssistantsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_assistant, except: %i[index create]

  def index
    @assistants = Current.account.aloo_assistants.order(:name)
  end

  def show
    render json: assistant_json(@assistant)
  end

  def create
    @assistant = Current.account.aloo_assistants.create!(assistant_params)
    render json: assistant_json(@assistant), status: :created
  end

  def update
    @assistant.update!(assistant_params)
    render json: assistant_json(@assistant)
  end

  def destroy
    @assistant.destroy!
    head :ok
  end

  # GET /api/v1/accounts/:account_id/aloo/assistants/:id/stats
  def stats
    render json: {
      total_conversations: @assistant.conversation_contexts.count,
      total_messages: @assistant.conversation_contexts.sum(:message_count),
      total_tokens: @assistant.conversation_contexts.sum('input_tokens + output_tokens'),
      total_memories: @assistant.memories.active.count,
      total_documents: @assistant.documents.processed.count
    }
  end

  # POST /api/v1/accounts/:account_id/aloo/assistants/:id/assign_inbox
  def assign_inbox
    inbox = Current.account.inboxes.find(params[:inbox_id])

    # Remove existing assignment if any
    Aloo::AssistantInbox.find_by(inbox: inbox)&.destroy

    # Create new assignment
    Aloo::AssistantInbox.create!(
      assistant: @assistant,
      inbox: inbox,
      active: true
    )

    render json: { message: 'Assistant assigned to inbox' }
  end

  # DELETE /api/v1/accounts/:account_id/aloo/assistants/:id/unassign_inbox
  def unassign_inbox
    inbox = Current.account.inboxes.find(params[:inbox_id])
    Aloo::AssistantInbox.find_by(assistant: @assistant, inbox: inbox)&.destroy
    render json: { message: 'Assistant unassigned from inbox' }
  end

  private

  def set_assistant
    @assistant = Current.account.aloo_assistants.find(params[:id])
  end

  def assistant_params
    params.require(:assistant).permit(
      :name,
      :description,
      :active,
      :language,
      :dialect,
      :model_name,
      :tone,
      :formality,
      :empathy_level,
      :verbosity,
      :emoji_usage,
      :greeting_style,
      :custom_greeting,
      :personality_description,
      :language_instruction,
      :business_context,
      :admin_config,
      :feature_memory_enabled,
      :feature_faq_enabled,
      :feature_handoff_enabled
    )
  end

  def assistant_json(assistant)
    {
      id: assistant.id,
      name: assistant.name,
      description: assistant.description,
      active: assistant.active,
      language: assistant.language,
      dialect: assistant.dialect,
      model_name: assistant.model_name,
      personality: {
        tone: assistant.tone,
        formality: assistant.formality,
        empathy_level: assistant.empathy_level,
        verbosity: assistant.verbosity,
        emoji_usage: assistant.emoji_usage,
        greeting_style: assistant.greeting_style,
        custom_greeting: assistant.custom_greeting,
        personality_description: assistant.personality_description,
        language_instruction: assistant.language_instruction
      },
      business_context: assistant.business_context,
      features: {
        memory_enabled: assistant.feature_memory_enabled,
        faq_enabled: assistant.feature_faq_enabled,
        handoff_enabled: assistant.feature_handoff_enabled
      },
      assigned_inboxes: assistant.inboxes.map { |i| { id: i.id, name: i.name } },
      created_at: assistant.created_at,
      updated_at: assistant.updated_at
    }
  end

  def check_authorization
    authorize(Current.account, :manage?)
  end
end
