class Contacts::FilterService < FilterService
  ATTRIBUTE_MODEL = 'contact_attribute'.freeze

  def initialize(account, user, params)
    @account = account
    # TODO: Change the order of arguments in FilterService maybe?
    # account, user, params makes more sense
    super(params, user)
  end

  def perform
    validate_query_operator
    # Verificar se há filtro de team_id para fazer JOIN com conversas
    has_team_filter = @params[:payload]&.any? { |f| f['attribute_key'] == 'team_id' }

    if has_team_filter
      # Adicionar JOIN com conversas para filtrar por team_id
      # Usar subquery com DISTINCT para evitar contatos duplicados quando há múltiplas conversas
      # Isso permite que o ORDER BY funcione corretamente depois
      @base_relation_with_conversations = base_relation.joins(:conversations)
      filtered_contacts = query_builder_with_conversations(@filters['contacts'])
      # Usar subquery para obter IDs únicos, depois buscar os contatos completos
      # Isso evita o problema de ORDER BY com DISTINCT
      contact_ids_subquery = filtered_contacts.select('DISTINCT contacts.id')
      @contacts = base_relation.where(id: contact_ids_subquery)
    else
      @contacts = query_builder(@filters['contacts'])
    end

    {
      contacts: @contacts,
      count: @contacts.count
    }
  end

  def filter_values(query_hash)
    if query_hash['attribute_key'] == 'phone_number'
      values = query_hash['values'].is_a?(Array) ? query_hash['values'] : [query_hash['values']]
      values.map { |val| "+#{val&.delete('+')}" }
    elsif query_hash['attribute_key'] == 'country_code'
      values = query_hash['values'].is_a?(Array) ? query_hash['values'] : [query_hash['values']]
      values.map(&:downcase)
    elsif query_hash['attribute_key'] == 'team_id'
      # Para team_id, retornar array de valores (números)
      query_hash['values'].is_a?(Array) ? query_hash['values'] : [query_hash['values']]
    else
      values = query_hash['values'].is_a?(Array) ? query_hash['values'] : [query_hash['values']]
      values.map { |val| val.is_a?(String) ? val.downcase : val }
    end
  end

  def base_relation
    @account.contacts.resolved_contacts(use_crm_v2: @account.feature_enabled?('crm_v2'))
  end

  def filter_config
    {
      entity: 'Contact',
      table_name: 'contacts'
    }
  end

  private

  def equals_to_filter_string(filter_operator, current_index)
    # Usar IN para permitir múltiplos valores, como no FilterService base
    return "IN (:value_#{current_index})" if filter_operator == 'equal_to'

    "NOT IN (:value_#{current_index})"
  end

  def query_builder_with_conversations(model_filters)
    @query_string = ''
    @params[:payload].each_with_index do |query_hash, current_index|
      condition_query = build_condition_query_for_team(model_filters, query_hash, current_index)
      @query_string += " #{condition_query.strip}" if condition_query.present?
    end

    # Validar que a query não está vazia
    raise CustomExceptions::CustomFilter::InvalidValue.new(attribute_name: 'team_id') if @query_string.strip.blank?

    # Validar que há valores para os placeholders
    raise CustomExceptions::CustomFilter::InvalidValue.new(attribute_name: 'team_id') if @filter_values.empty?

    @base_relation_with_conversations.where(@query_string.strip, @filter_values.with_indifferent_access)
  end

  def build_condition_query_for_team(model_filters, query_hash, current_index)
    # Se for team_id, filtrar através de conversas
    if query_hash['attribute_key'] == 'team_id'
      # Sempre chamar filter_operation primeiro para popular @filter_values
      filter_operator_value = filter_operation(query_hash, current_index)

      # Para o último filtro, query_operator deve ser nil/undefined
      # Para outros, usar o query_operator fornecido ou 'AND' como padrão
      is_last_filter = current_index == @params[:payload].length - 1
      query_operator = if is_last_filter
                         ''
                       elsif query_hash[:query_operator].present?
                         " #{query_hash[:query_operator].upcase}"
                       else
                         ' AND'
                       end

      # Para is_present e is_not_present, filter_operation retorna nil
      # O valor real está em @filter_values
      if filter_operator_value.nil?
        filter_value = @filter_values["value_#{current_index}"]
        "conversations.team_id #{filter_value}#{query_operator}"
      else
        # Para outros operadores, usar o padrão: column operator_value query_operator
        "conversations.team_id #{filter_operator_value}#{query_operator}"
      end
    else
      # Para outros atributos, usar a lógica padrão
      build_condition_query(model_filters, query_hash, current_index)
    end
  end
end
