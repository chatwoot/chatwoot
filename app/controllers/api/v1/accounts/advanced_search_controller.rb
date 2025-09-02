class Api::V1::Accounts::AdvancedSearchController < Api::V1::Accounts::BaseController
  before_action :set_current_page, only: [:index, :conversations, :messages, :contacts]
  before_action :validate_search_params, only: [:index, :conversations, :messages, :contacts]

  # GET /api/v1/accounts/:account_id/advanced_search
  def index
    @result = perform_search('all')
    render json: format_response(@result)
  end

  # GET /api/v1/accounts/:account_id/advanced_search/conversations
  def conversations
    @result = perform_search('conversations')
    render json: format_response(@result)
  end

  # GET /api/v1/accounts/:account_id/advanced_search/messages
  def messages
    @result = perform_search('messages')
    render json: format_response(@result)
  end

  # GET /api/v1/accounts/:account_id/advanced_search/contacts
  def contacts
    @result = perform_search('contacts')
    render json: format_response(@result)
  end

  # GET /api/v1/accounts/:account_id/advanced_search/suggestions
  def suggestions
    @suggestions = generate_search_suggestions
    render json: { suggestions: @suggestions }
  end

  # GET /api/v1/accounts/:account_id/advanced_search/filters
  def filters
    @filters = get_available_filters
    render json: { filters: @filters }
  end

  # POST /api/v1/accounts/:account_id/advanced_search/saved_searches
  def create_saved_search
    @saved_search = current_account.saved_searches.build(saved_search_params)
    @saved_search.user = Current.user

    if @saved_search.save
      render json: { 
        saved_search: @saved_search,
        message: 'Search saved successfully'
      }, status: :created
    else
      render json: { 
        errors: @saved_search.errors,
        message: 'Failed to save search'
      }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/accounts/:account_id/advanced_search/saved_searches
  def saved_searches
    @saved_searches = current_account.saved_searches
                                    .where(user: Current.user)
                                    .order(created_at: :desc)
    render json: { saved_searches: @saved_searches }
  end

  private

  def perform_search(search_type)
    search_service = AdvancedSearchService.new(
      current_user: Current.user,
      current_account: Current.account,
      search_type: search_type,
      **search_params
    )

    search_service.perform
  end

  def search_params
    @search_params ||= {
      query: params[:q] || params[:query],
      page: @current_page,
      per_page: per_page_limit,
      
      # Filter parameters
      channel_types: array_param(:channel_types),
      inbox_ids: array_param(:inbox_ids),
      agent_ids: array_param(:agent_ids),
      team_ids: array_param(:team_ids),
      tags: array_param(:tags),
      labels: array_param(:labels),
      status: array_param(:status),
      priority: array_param(:priority),
      message_types: array_param(:message_types),
      sender_types: array_param(:sender_types),
      sentiment: array_param(:sentiment),
      sla_status: array_param(:sla_status),
      contact_segments: array_param(:contact_segments),
      
      # Date filters
      date_from: parse_date(params[:date_from]),
      date_to: parse_date(params[:date_to]),
      
      # String filters
      custom_attributes: params[:custom_attributes],
      
      # Boolean filters
      has_attachments: parse_boolean(params[:has_attachments]),
      unread_only: parse_boolean(params[:unread_only]),
      assigned_only: parse_boolean(params[:assigned_only]),
      unassigned_only: parse_boolean(params[:unassigned_only])
    }.compact
  end

  def array_param(param_name)
    param_value = params[param_name]
    return [] if param_value.blank?
    
    case param_value
    when Array
      param_value.compact.reject(&:blank?)
    when String
      param_value.split(',').map(&:strip).compact.reject(&:blank?)
    else
      [param_value.to_s].reject(&:blank?)
    end
  end

  def parse_date(date_string)
    return nil if date_string.blank?
    
    Date.parse(date_string.to_s)
  rescue ArgumentError
    nil
  end

  def parse_boolean(value)
    return nil if value.blank?
    
    %w[true 1 yes on].include?(value.to_s.downcase)
  end

  def per_page_limit
    per_page = params[:per_page].to_i
    per_page = 20 if per_page <= 0
    per_page = 100 if per_page > 100  # Max limit
    per_page
  end

  def set_current_page
    @current_page = params[:page].to_i
    @current_page = 1 if @current_page <= 0
  end

  def validate_search_params
    # Validate date range
    if search_params[:date_from] && search_params[:date_to] && 
       search_params[:date_from] > search_params[:date_to]
      render json: { 
        error: 'Invalid date range: date_from must be before date_to' 
      }, status: :bad_request
      return
    end

    # Validate query length for performance
    query = search_params[:query]
    if query.present? && query.length > 500
      render json: { 
        error: 'Query too long: maximum 500 characters allowed' 
      }, status: :bad_request
      return
    end

    # Validate conflicting filters
    if search_params[:assigned_only] && search_params[:unassigned_only]
      render json: { 
        error: 'Conflicting filters: cannot use both assigned_only and unassigned_only' 
      }, status: :bad_request
      return
    end
  end

  def format_response(result)
    formatted = {
      results: result.except(:meta),
      meta: result[:meta],
      applied_filters: extract_applied_filters
    }

    # Add search suggestions if query was provided but no results found
    if result[:meta][:total_results] == 0 && search_params[:query].present?
      formatted[:suggestions] = generate_search_suggestions
    end

    formatted
  end

  def extract_applied_filters
    active_filters = {}
    
    search_params.each do |key, value|
      next if %i[query page per_page].include?(key)
      next if value.blank? || (value.is_a?(Array) && value.empty?)
      next if value == false
      
      active_filters[key] = value
    end
    
    active_filters
  end

  def generate_search_suggestions
    query = search_params[:query]
    return [] if query.blank? || query.length < 2

    suggestions = []
    
    # Suggest based on recent conversations
    recent_contacts = Current.account.contacts
                             .joins(:conversations)
                             .where('conversations.created_at >= ?', 30.days.ago)
                             .where('contacts.name ILIKE ? OR contacts.email ILIKE ?', 
                                    "%#{query}%", "%#{query}%")
                             .distinct
                             .limit(5)
                             .pluck(:name, :email)
    
    recent_contacts.each do |name, email|
      suggestions << { type: 'contact', text: name, subtitle: email } if name.present?
    end

    # Suggest based on common labels
    if Current.account.labels.exists?
      matching_labels = Current.account.labels
                                       .where('title ILIKE ?', "%#{query}%")
                                       .limit(3)
                                       .pluck(:title)
      
      matching_labels.each do |label|
        suggestions << { type: 'label', text: label, subtitle: 'Label' }
      end
    end

    # Suggest agent names
    matching_agents = Current.account.users
                             .where('name ILIKE ?', "%#{query}%")
                             .limit(3)
                             .pluck(:name)
    
    matching_agents.each do |name|
      suggestions << { type: 'agent', text: name, subtitle: 'Agent' }
    end

    suggestions.uniq { |s| s[:text] }
  end

  def get_available_filters
    account_user = Current.account.account_users.find_by(user: Current.user)
    is_admin = account_user&.administrator?

    filters = {
      channel_types: get_channel_types,
      inboxes: get_accessible_inboxes(is_admin),
      agents: get_agents,
      teams: get_teams,
      labels: get_labels,
      status_options: Conversation.statuses.keys,
      priority_options: Conversation.priorities.keys,
      message_types: Message.message_types.keys,
      sender_types: %w[Contact User],
      sentiment_options: %w[positive negative neutral],
      sla_status_options: AppliedSla.sla_statuses.keys
    }

    # Add admin-only filters
    if is_admin
      filters[:all_inboxes] = Current.account.inboxes.pluck(:name, :id)
    end

    filters
  end

  def get_channel_types
    Current.account.inboxes.distinct.pluck(:channel_type).compact.sort
  end

  def get_accessible_inboxes(is_admin)
    if is_admin
      Current.account.inboxes.pluck(:name, :id)
    else
      Current.user.assigned_inboxes.pluck(:name, :id)
    end
  end

  def get_agents
    Current.account.users
           .joins(:account_users)
           .where(account_users: { role: ['agent', 'administrator'] })
           .pluck(:name, :id)
  end

  def get_teams
    Current.account.teams.pluck(:name, :id)
  end

  def get_labels
    Current.account.labels.pluck(:title, :id)
  end

  def saved_search_params
    params.require(:saved_search).permit(
      :name, :description, :search_type,
      :query, :filters => {}
    )
  end
end