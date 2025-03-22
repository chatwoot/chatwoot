class ConversationFinder
  attr_reader :current_user, :current_account, :params

  DEFAULT_STATUS = 'open'.freeze
  SORT_OPTIONS = {
    'last_activity_at_asc' => %w[sort_on_last_activity_at asc],
    'last_activity_at_desc' => %w[sort_on_last_activity_at desc],
    'created_at_asc' => %w[sort_on_created_at asc],
    'created_at_desc' => %w[sort_on_created_at desc],
    'priority_asc' => %w[sort_on_priority asc],
    'priority_desc' => %w[sort_on_priority desc],
    'waiting_since_asc' => %w[sort_on_waiting_since asc],
    'waiting_since_desc' => %w[sort_on_waiting_since desc],

    # To be removed in v3.5.0
    'latest' => %w[sort_on_last_activity_at desc],
    'sort_on_created_at' => %w[sort_on_created_at asc],
    'sort_on_priority' => %w[sort_on_priority desc],
    'sort_on_waiting_since' => %w[sort_on_waiting_since asc]
  }.with_indifferent_access
  # assumptions
  # inbox_id if not given, take from all conversations, else specific to inbox
  # assignee_type if not given, take 'all'
  # conversation_status if not given, take 'open'

  # response of this class will be of type
  # {conversations: [array of conversations], count: {open: count, resolved: count}}

  # params
  # assignee_type, inbox_id, :status

  def initialize(current_user, params)
    @current_user = current_user
    @current_account = current_user.account
    @params = params
  end

  def perform
    set_up

    mine_count, unassigned_count, all_count, = set_count_for_all_conversations
    assigned_count = all_count - unassigned_count

    filter_by_assignee_type

    {
      conversations: conversations,
      count: {
        mine_count: mine_count,
        assigned_count: assigned_count,
        unassigned_count: unassigned_count,
        all_count: all_count
      }
    }
  end

  private

  def set_up
    set_inboxes
    set_team
    set_assignee_type

    find_all_conversations
    filter_by_status unless params[:q]
    filter_by_team
    filter_by_labels
    filter_by_query
    filter_by_source_id
  end

  def set_inboxes
    @inbox_ids = if params[:inbox_id]
                   @current_user.assigned_inboxes.where(id: params[:inbox_id])
                 else
                   @current_user.assigned_inboxes.pluck(:id)
                 end
  end

  def set_assignee_type
    @assignee_type = params[:assignee_type]
  end

  def set_team
    @team = current_account.teams.find(params[:team_id]) if params[:team_id]
  end

  def find_all_conversations
    @conversations = current_account.conversations.where(inbox_id: @inbox_ids)
    filter_by_conversation_type if params[:conversation_type]
    @conversations
  end

  def filter_by_assignee_type
    @conversations = filter_service.filter_by_assignee_type(@conversations, @assignee_type, current_user)
  end

  def filter_by_conversation_type
    @conversations = filter_service.filter_by_conversation_type(
      @conversations,
      @params[:conversation_type],
      current_user,
      current_account
    )
  end

  def filter_by_query
    @conversations = filter_service.filter_by_query(@conversations, params[:q])
  end

  def filter_by_status
    @conversations = filter_service.filter_by_status(@conversations, params[:status], DEFAULT_STATUS)
  end

  def filter_by_team
    @conversations = filter_service.filter_by_team(@conversations, @team)
  end

  def filter_by_labels
    @conversations = filter_service.filter_by_labels(@conversations, params[:labels])
  end

  def filter_by_source_id
    @conversations = filter_service.filter_by_source_id(@conversations, params[:source_id])
  end

  def set_count_for_all_conversations
    [
      @conversations.assigned_to(current_user).count,
      @conversations.unassigned.count,
      @conversations.count
    ]
  end

  def current_page
    params[:page] || 1
  end

  def conversations_base_query
    @conversations.includes(
      :taggings, :inbox, { assignee: { avatar_attachment: [:blob] } }, { contact: { avatar_attachment: [:blob] } }, :team, :contact_inbox
    )
  end

  def conversations
    @conversations = conversations_base_query
    apply_sorting_and_filtering
    result_conversations = params[:updated_within].present? ? @conversations : apply_pagination
    preloader.preload_data_if_needed(result_conversations, params)
    result_conversations
  end

  def apply_sorting_and_filtering
    @conversations = filter_service.apply_sorting(@conversations, params[:sort_by], SORT_OPTIONS)
    @conversations = filter_service.filter_by_updated_date(@conversations, params[:updated_within]) if params[:updated_within].present?
  end

  def apply_pagination
    per_page = ENV.fetch('CONVERSATION_RESULTS_PER_PAGE', '25').to_i
    @conversations.page(current_page).per(per_page)
  end

  def filter_service
    @filter_service ||= filter_service_class.new
  end

  def preloader
    @preloader ||= preloader_class.new
  end

  def filter_service_class
    Class.new do
      include ConversationFilterService
    end
  end

  def preloader_class
    Class.new do
      include ConversationPreloader
    end
  end
end

# Load the modules
require 'conversation_preloader'
require 'conversation_filter_service'

ConversationFinder.prepend_mod_with('ConversationFinder')
