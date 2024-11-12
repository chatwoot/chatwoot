class V2::ReportBuilder # rubocop:disable Metrics/ClassLength
  include DateRangeHelper
  include ReportHelper
  attr_reader :account, :params

  DEFAULT_GROUP_BY = 'day'.freeze
  RESULTS_PER_PAGE = 10

  def initialize(account, params)
    @account = account
    @params = params

    timezone_offset = (params[:timezone_offset] || 0).to_f
    @timezone = ActiveSupport::TimeZone[timezone_offset]&.name
  end

  def timeseries
    return send(params[:metric]) if metric_valid?

    Rails.logger.error "ReportBuilder: Invalid metric - #{params[:metric]}"
    {}
  end

  # For backward compatible with old report
  def build
    if %w[avg_first_response_time avg_resolution_time reply_time].include?(params[:metric])
      timeseries.each_with_object([]) do |p, arr|
        arr << { value: p[1], timestamp: p[0].in_time_zone(@timezone).to_i, count: @grouped_values.count[p[0]] }
      end
    else
      timeseries.each_with_object([]) do |p, arr|
        arr << { value: p[1], timestamp: p[0].in_time_zone(@timezone).to_i }
      end
    end
  end

  def summary
    {
      conversations_count: conversations.count,
      incoming_messages_count: incoming_messages.count,
      outgoing_messages_count: outgoing_messages.count,
      avg_first_response_time: avg_first_response_time_summary,
      avg_resolution_time: avg_resolution_time_summary,
      resolutions_count: resolutions.count,
      reply_time: reply_time_summary
    }
  end

  def short_summary
    {
      conversations_count: conversations.count,
      avg_first_response_time: avg_first_response_time_summary,
      avg_resolution_time: avg_resolution_time_summary
    }
  end

  def bot_summary
    {
      bot_resolutions_count: bot_resolutions.count,
      bot_handoffs_count: bot_handoffs.count
    }
  end

  def conversation_metrics
    if params[:type].equal?(:account)
      live_conversations
    else
      agent_metrics.sort_by { |hash| hash[:metric][:open] }.reverse
    end
  end

  def contact_metrics
    if params[:type].equal?(:account)
      contacts_by_stage
    else
      agent_contacts.sort_by { |hash| hash[:metric][:New] }.reverse
    end
  end

  def agent_contacts_by_stage
    stages = Stage.where(account_id: @account.id)

    result = {}
    stages.each do |stage|
      result[stage.code] = stage.contacts.where(assignee_id: params[:user_id]).count
    end
    result
  end

  def agent_conversations
    conversations = @account.conversations.where(assignee_id: params[:user_id])
    {
      open: conversations.open.count,
      unattended: conversations.unattended.count,
      pending: conversations.pending.count,
      resolved: conversations.resolved.count
    }
  end

  def agent_planned
    base_relation = @account.conversation_plans
    planned = base_relation.incomplete.joins(:conversation).where(conversations: { status: :snoozed, assignee_id: params[:user_id] }).count
    open = base_relation.incomplete.joins(:conversation).where(conversations: { status: :open, assignee_id: params[:user_id] }).count
    resolved = base_relation.completed.joins(:conversation).where(conversations: { assignee_id: params[:user_id] }).count
    open_resolved_sum = open + resolved

    {
      planned: planned,
      open: open,
      resolved: resolved,
      ratio: open_resolved_sum.zero? ? 0 : (resolved.to_f / open_resolved_sum * 100).round(0)
    }
  end

  def agent_planned_conversations
    conversations = @account.conversations.where(assignee_id: params[:user_id]).where.not(snoozed_until: nil)

    conversations.map do |conversation|
      {
        id: conversation.display_id,
        startDate: conversation.snoozed_until,
        title: "#{conversation.contact.name} | #{conversation.inbox.name}"
      }
    end
  end

  private

  def metric_valid?
    %w[conversations_count
       incoming_messages_count
       outgoing_messages_count
       avg_first_response_time
       avg_resolution_time reply_time
       resolutions_count
       bot_resolutions_count
       bot_handoffs_count
       reply_time].include?(params[:metric])
  end

  def inbox
    @inbox ||= account.inboxes.find(params[:id])
  end

  def user
    @user ||= account.users.find(params[:id])
  end

  def label
    @label ||= account.labels.find(params[:id])
  end

  def team
    @team ||=
      if params[:type].equal?(:team)
        account.teams.find(params[:id])
      elsif params[:team_id].present?
        account.teams.find(params[:team_id])
      end
  end

  def get_grouped_values(object_scope)
    @grouped_values = object_scope.group_by_period(
      params[:group_by] || DEFAULT_GROUP_BY,
      :created_at,
      default_value: 0,
      range: range,
      permit: %w[day week month year hour],
      time_zone: @timezone
    )
  end

  def agent_metrics
    account_users = @account.account_users.page(params[:page]).per(RESULTS_PER_PAGE)
    account_users.each_with_object([]) do |account_user, arr|
      @user = account_user.user
      arr << {
        id: @user.id,
        name: @user.name,
        email: @user.email,
        thumbnail: @user.avatar_url,
        availability: account_user.availability_status,
        metric: live_conversations
      }
    end
  end

  def live_conversations
    @open_conversations = if filter_by_team?
                            open_conversations_by_team
                          else
                            scope.conversations.where(account_id: @account.id, created_at: range).open
                          end

    metric = {
      open: @open_conversations.count,
      unattended: @open_conversations.unattended.count
    }
    metric[:unassigned] = @open_conversations.unassigned.count if params[:type].equal?(:account)
    metric[:resolved] = scope.conversations.where(account_id: @account.id, created_at: range).resolved.count
    metric
  end

  def open_conversations_by_team
    scope.conversations
         .joins(:assignee_team_members)
         .where(account_id: account.id, created_at: range, team_members: { team_id: team.id }).open
         .or(
           scope.conversations.joins(:assignee_team_members).where(account_id: account.id, created_at: range,
                                                                   team_id: team.id).open
         )
  end

  # rubocop:disable Metrics/AbcSize
  def contacts_by_stage
    result = {}

    stages = Stage.where(account_id: @account.id).order(:id)
    stages.each do |stage|
      result[stage.code] =
        @user ? stage.contacts.where(assignee_id: @user.id, last_stage_changed_at: range).count : stage.contacts.where(created_at: range).count
    end

    # Based on contact_transaction, we count contact_transactions if = 1 is won by new customers,
    # if > 1 is won by old customers
    won_fr_new_count, won_fr_care_count = won_count_from_contacts.values_at(:won_fr_new_count, :won_fr_care_count)
    result[:wonFromNew] = won_fr_new_count
    result[:wonFromCare] = won_fr_care_count

    # For the new total, we sum the stages with the type deal or both, and the old ones are retention or both
    fr_new_all_contacts, fr_care_all_contacts =
      total_of_won_from_contacts.values_at(:fr_new_all_contacts, :fr_care_all_contacts)

    # Results need to except the 'Won' contacts from non-relevant source
    result[:totalFromNew] = fr_new_all_contacts.count - result[:wonFromCare]
    result[:totalFromCare] = fr_care_all_contacts.count - result[:wonFromNew]

    result
  end
  # rubocop:enable Metrics/AbcSize

  def won_count_from_contacts
    @won_stage = Stage.find_by(code: 'Won')
    query_string, filter_values = contacts_by_stage_query_hash.values_at(:query_string, :filter_values)
    # @base_relation gets contacts by 'Won' stage with filter conditions
    @base_relation = @won_stage.contacts.where(query_string, filter_values.with_indifferent_access)

    # Based on contact_transaction, we count contact_transactions if = 1 is won by new customers,
    # if > 1 is won by old customers
    @won_fr_new_contacts = @base_relation.joins(:contact_transactions).group('contacts.id').having('COUNT(contact_transactions.id) = 1')
    @won_fr_care_contacts = @base_relation.joins(:contact_transactions).group('contacts.id').having('COUNT(contact_transactions.id) > 1')

    {
      won_fr_new_count: @won_fr_new_contacts.count.values.sum,
      won_fr_care_count: @won_fr_care_contacts.count.values.sum
    }
  end

  def total_of_won_from_contacts
    query_string, filter_values = contacts_by_stage_query_hash.values_at(:query_string, :filter_values)
    # Get the stages relevant to contacts just messaged at first time
    fr_new_stages = Stage.where(stage_type: %i[deals both]).enabled
    # Get the stages relevant to contacts we are taking care of
    fr_care_stages = Stage.where(stage_type: %i[retention both]).enabled

    {
      fr_new_all_contacts: Contact.joins(:stage)
                                  .where(query_string, filter_values.with_indifferent_access)
                                  .where(stage: { id: fr_new_stages.ids }),
      fr_care_all_contacts: Contact.joins(:stage)
                                   .where(query_string, filter_values.with_indifferent_access)
                                   .where(stage: { id: fr_care_stages.ids })
    }
  end

  # rubocop:disable Metrics/AbcSize
  def contacts_by_stage_query_hash # rubocop:disable Metrics/MethodLength
    @query_string = ''
    @filter_values = {}

    if @user.present?
      @query_string += 'contacts.assignee_id = (:value_0)'
      @filter_values['value_0'] = @user.id
      if range.present?
        @query_string += ' AND contacts.last_stage_changed_at > (:value_1) AND contacts.last_stage_changed_at < (:value_2)'
        @filter_values['value_1'] = parse_date_time(params[:since])
        @filter_values['value_2'] = parse_date_time(params[:until])
      end
    elsif range.present?
      @query_string += ' contacts.created_at > (:value_1) AND contacts.created_at < (:value_2)'
      @filter_values['value_1'] = parse_date_time(params[:since])
      @filter_values['value_2'] = parse_date_time(params[:until])
    end

    if filter_by_team?
      @query_string += ' AND contacts.team_id = (:value_3)'
      @filter_values['value_3'] = team.id
    end

    {
      query_string: @query_string,
      filter_values: @filter_values
    }
  end
  # rubocop:enable Metrics/AbcSize

  def agent_contacts
    account_users = @account.account_users.page(params[:page]).per(RESULTS_PER_PAGE)
    account_users.each_with_object([]) do |account_user, arr|
      @user = account_user.user
      arr << {
        id: @user.id,
        name: @user.name,
        email: @user.email,
        thumbnail: @user.avatar_url,
        availability: account_user.availability_status,
        metric: contacts_by_stage
      }
    end
  end
end
