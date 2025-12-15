class OttivConversationFinder < ConversationFinder
  def initialize(current_user, params)
    super(current_user, params)
  end

  # Sobrescrever perform para incluir filtered_count
  def perform
    set_up

    mine_count, unassigned_count, all_count, = set_count_for_all_conversations
    assigned_count = all_count - unassigned_count

    filter_by_assignee_type

    # Calcular total filtrado antes da paginação
    # Usar distinct para evitar duplicatas quando há joins (ex: tagged_with)
    filtered_count = @conversations.distinct.count

    {
      conversations: conversations, # Aplica paginação aqui
      count: {
        mine_count: mine_count,
        assigned_count: assigned_count,
        unassigned_count: unassigned_count,
        all_count: all_count
      },
      filtered_count: filtered_count # Total filtrado sem paginação
    }
  end

  private

  def set_up
    set_inboxes
    set_team
    set_assignee_type

    find_all_conversations
    filter_by_status unless params[:q] || params[:searchTerm] # Não filtrar por status se há busca ativa
    filter_by_team
    filter_by_labels
    filter_by_assignee_ids # Novo filtro para múltiplos assignees
    filter_by_query
    filter_by_source_id
  end

  def set_inboxes
    # Suportar múltiplos inbox_ids
    if params[:inbox_ids].present?
      inbox_ids_array = Array(params[:inbox_ids]).map(&:to_i).compact
      @inbox_ids = @current_user.assigned_inboxes.where(id: inbox_ids_array).pluck(:id)
    elsif params[:inbox_id].present?
      # Manter compatibilidade com o parâmetro singular
      @inbox_ids = @current_user.assigned_inboxes.where(id: params[:inbox_id]).pluck(:id)
    else
      @inbox_ids = @current_user.assigned_inboxes.pluck(:id)
    end
  end

  def find_conversation_by_inbox
    @conversations = current_account.conversations

    # Se o cliente enviou inbox_ids mas, após filtrar pelas inboxes atribuídas ao usuário,
    # não sobrou nenhuma, não devemos retornar conversas de outras inboxes.
    # Isso garante que o filtro de inbox seja estrito.
    if params[:inbox_ids].present? && @inbox_ids.blank?
      @conversations = @conversations.none
      return
    end

    return if @inbox_ids.blank?

    # Filtrar por múltiplos inbox_ids (OR dentro do filtro)
    @conversations = @conversations.where(inbox_id: @inbox_ids)
  end

  def filter_by_labels
    # Suportar múltiplas labels via label_titles (OR dentro do filtro)
    label_titles = params[:label_titles] || params[:labels]
    return unless label_titles.present?

    label_titles_array = Array(label_titles)
    # Usar distinct para evitar duplicatas do join com taggings
    @conversations = @conversations.tagged_with(label_titles_array, any: true).distinct
  end

  # Método para filtrar por múltiplos assignee_ids
  def filter_by_assignee_ids
    assignee_ids = params[:assignee_ids]
    include_unassigned = params[:include_unassigned]

    # Converter para boolean de forma robusta
    include_unassigned = case include_unassigned
                         when true, 'true', 1, '1', 'yes'
                           true
                         else
                           false
                         end

    return unless assignee_ids.present? || include_unassigned

    assignee_ids_array = Array(assignee_ids).map(&:to_i).compact.reject(&:zero?)

    # Se não há assignee_ids e não deve incluir não atribuídas, não fazer nada
    return if assignee_ids_array.empty? && !include_unassigned

    # Construir condições OR usando uma única query
    if assignee_ids_array.any? && include_unassigned
      # Combinar assignee_ids específicos + não atribuídas
      @conversations = @conversations.where(
        "assignee_id IN (?) OR assignee_id IS NULL OR assignee_id = 0",
        assignee_ids_array
      )
    elsif assignee_ids_array.any?
      # Apenas assignee_ids específicos
      @conversations = @conversations.where(assignee_id: assignee_ids_array)
    elsif include_unassigned
      # Apenas não atribuídas
      @conversations = @conversations.where("assignee_id IS NULL OR assignee_id = 0")
    end
  end

  # Garantir que filter_by_query funcione corretamente mesmo com múltiplos filtros
  # O método já existe no ConversationFinder, mas vamos garantir que funcione
  def filter_by_query
    # Normalizar searchTerm para q se necessário
    search_param = params[:q] || params[:searchTerm]
    return unless search_param.present?

    # Usar o método do pai, mas garantir que o parâmetro correto esteja definido
    params[:q] = search_param if params[:q].blank?

    # Corrigir o método do pai que usa conversations ao invés de @conversations
    allowed_message_types = [Message.message_types[:incoming], Message.message_types[:outgoing]]
    @conversations = @conversations.joins(:messages)
                                   .where('messages.content ILIKE :search', search: "%#{params[:q]}%")
                                   .where(messages: { message_type: allowed_message_types })
                                   .distinct
  end

  # Sobrescrever conversations para garantir distinct quando há filtros de labels
  def conversations
    @conversations = conversations_base_query

    sort_by, sort_order = SORT_OPTIONS[params[:sort_by]] || SORT_OPTIONS['last_activity_at_desc']
    @conversations = @conversations.send(sort_by, sort_order)

    # Garantir distinct antes da paginação se há filtros que podem causar duplicatas
    # (labels via tagged_with fazem join com taggings)
    if params[:label_titles].present? || params[:labels].present?
      @conversations = @conversations.distinct
    end

    if params[:updated_within].present?
      @conversations.where('conversations.updated_at > ?', Time.zone.now - params[:updated_within].to_i.seconds)
    else
      @conversations.page(current_page).per(ENV.fetch('CONVERSATION_RESULTS_PER_PAGE', '25').to_i)
    end
  end
end

