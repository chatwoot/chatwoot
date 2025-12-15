class Api::V1::Accounts::OttivConversationsController < Api::V1::Accounts::BaseController
  def index
    result = ottiv_conversation_finder.perform
    @conversations = result[:conversations]
    @conversations_count = result[:count]
    @count_filter = result[:filtered_count] # Total filtrado sem paginação
  rescue StandardError => e
    Rails.logger.error("❌ [OttivConversations] Erro ao buscar conversas: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
  end

  private

  def ottiv_conversation_finder
    @ottiv_conversation_finder ||= OttivConversationFinder.new(Current.user, ottiv_params)
  end

  def ottiv_params
    # Aceitar parâmetros do body JSON + query params para paginação
    body_params = {}

    if request.content_type&.include?('json') && request.body.present?
      begin
        body_content = request.body.read
        request.body.rewind # Reset body stream
        body_params = body_content.present? ? JSON.parse(body_content) : {}
      rescue JSON::ParserError => e
        Rails.logger.error("❌ [OttivConversations] Erro ao parsear JSON: #{e.message}")
        body_params = {}
      end
    end

    # Combinar body params com query params (query params têm prioridade para paginação)
    # Permitir arrays também nos query params
    query_params = params.permit(
      :page, :sort_by, :status, :assignee_type, :conversation_type, :q, :searchTerm, :updated_within,
      inbox_ids: [], label_titles: [], assignee_ids: [], include_unassigned: []
    ).to_h

    # Converter body_params para hash simples antes de fazer merge
    body_hash = body_params.is_a?(Hash) ? body_params : {}
    merged_params = body_hash.with_indifferent_access.merge(query_params.with_indifferent_access)

    # Normalizar searchTerm para q (compatibilidade com ConversationFinder)
    if merged_params[:searchTerm].present? && merged_params[:q].blank?
      merged_params[:q] = merged_params[:searchTerm]
    end

    # Validar e normalizar arrays (apenas se presentes)
    merged_params[:inbox_ids] = normalize_array(merged_params[:inbox_ids]) if merged_params.key?(:inbox_ids)
    merged_params[:label_titles] = normalize_array(merged_params[:label_titles]) if merged_params.key?(:label_titles)
    merged_params[:assignee_ids] = normalize_array(merged_params[:assignee_ids]) if merged_params.key?(:assignee_ids)

    # Validar tipos
    validate_params(merged_params)

    # Garantir que retornamos um hash simples (não ActionController::Parameters)
    # Converter para hash simples para evitar problemas com permit
    result_hash = merged_params.is_a?(Hash) ? merged_params : merged_params.to_h
    result_hash.with_indifferent_access
  end

  def normalize_array(value)
    return [] if value.blank?
    return value if value.is_a?(Array)
    [value].flatten.compact
  end

  def validate_params(params)
    # Validar que inbox_ids são números se fornecidos
    if params[:inbox_ids].present? && params[:inbox_ids].is_a?(Array)
      params[:inbox_ids] = params[:inbox_ids].map(&:to_i).compact.reject(&:zero?)
    end

    # Validar que assignee_ids são números se fornecidos
    if params[:assignee_ids].present? && params[:assignee_ids].is_a?(Array)
      params[:assignee_ids] = params[:assignee_ids].map(&:to_i).compact.reject(&:zero?)
    end

    # Validar que label_titles são strings se fornecidos
    if params[:label_titles].present? && params[:label_titles].is_a?(Array)
      params[:label_titles] = params[:label_titles].map(&:to_s).compact.reject(&:blank?)
    end

    # Validar page é um número positivo
    if params[:page].present?
      params[:page] = params[:page].to_i
      params[:page] = 1 if params[:page] < 1
    end
  end
end

