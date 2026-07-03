# Agent-facing copilot for a live conversation (V1). NOT admin-only (any agent who
# can view the conversation may use it) — so it does NOT inherit the admin-gated
# Autonomia::BaseController. Gated by the KANBAN key ("kanban on => copilot") plus an
# ENV kill-switch, so it stays inert until the customer has the kanban feature.
class Api::V1::Accounts::Autonomia::ConversationCopilotController < Api::V1::Accounts::BaseController
  before_action :ensure_copilot_enabled
  before_action :set_conversation

  def create
    result = ::Autonomia::Copilot::ConversationCopilot.new(
      conversation: @conversation,
      task: params[:task],
      draft: params[:draft],
      tone: params[:tone],
      instruction: params[:instruction]
    ).perform

    render json: { text: result.text, grounded: result.grounded, available: result.available }
  end

  # V2.3 — INTERNAL/BOTH agents of the account, usable as team copilots in the chat widget.
  # Lightweight inline json (id/name/actuation/description) — does NOT reuse _agent.json.jbuilder
  # so instruction/scaffold/config never leak through this agent-facing, non-admin endpoint.
  def agents
    agents = Current.account.then do |account|
      ::Autonomia::Agents::Agent
        .where(account: account, actuation: %i[internal both], status: :active, enabled: true)
        .where.not(instruction: [nil, ''])
        .where("config->>'system_key' IS NULL") # agentes de sistema (Guia) fora do copiloto
        .order(:name)
    end

    render json: {
      agents: agents.map do |agent|
        { id: agent.id, name: agent.name, actuation: agent.actuation, description: agent.agent_type }
      end
    }
  end

  # V2.3 — chat turn against the selected internal/both agent, grounded on its knowledge with the
  # live conversation transcript fed as untrusted context. Best-effort: never 500s.
  def chat
    result = ::Autonomia::Copilot::ConversationChat.new(
      conversation: @conversation,
      agent_id: params[:agent_id],
      message: params[:message],
      history: params[:history]
    ).perform

    render json: {
      text: result.text,
      grounded: result.grounded,
      available: result.available,
      reply_suggestion: result.reply_suggestion
    }
  end

  private

  def ensure_copilot_enabled
    # Secure-by-default: BE default matches the FE (dashboard_controller exposes
    # crmCopilotEnabled defaulting false) so "env unset" = fully off on both sides,
    # never UI-hidden-but-endpoint-callable. Prod sets CRM_COPILOT_ENABLED=true.
    enabled = ::Crm::Config.enabled? &&
              ::Autonomia::Agents::Config.enabled?(Current.account) && # respeita o kill-switch master da Autonomia
              ActiveModel::Type::Boolean.new.cast(ENV.fetch('CRM_COPILOT_ENABLED', false))
    head :not_found unless enabled
  end

  # Chatwoot identifies conversations by per-account display_id; show? enforces that
  # the agent may actually view this conversation (admin / assigned / inbox member).
  # On top of that, the CRM `assigned_only` visibility applies (same pattern as
  # Crm::CardsController#authorize_crm_conversation!): an inbox member who is not the
  # assignee/participant must not feed the transcript to the LLM. ensure_copilot_enabled
  # already guarantees the CRM is on, so accounts without CRM never reach this filter.
  def set_conversation
    @conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
    authorize @conversation, :show?
    ::Crm::Conversations::AccessAuthorizer.new(
      account: Current.account,
      user: Current.user,
      account_user: Current.account_user
    ).authorize!(@conversation)
  end
end
