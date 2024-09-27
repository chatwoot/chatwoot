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
      ratio: open_resolved_sum.zero? ? 0 : (resolved / open_resolved_sum * 100).round(0)
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

  def conversion_metrics
    @qualified_stage = Stage.find_by(code: 'Qualified')
    @won_stage = Stage.find_by(code: 'Won')

    case params[:criteria_type]
    when :team
      team_conversion_metrics
    when :data_source
      data_source_conversion_metrics
    when :agent
      agent_conversion_metrics
    when :inbox
      inbox_conversion_metrics
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
    @team ||= account.teams.find(params[:id])
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
    @open_conversations = scope.conversations.where(account_id: @account.id).open
    metric = {
      open: @open_conversations.count,
      unattended: @open_conversations.unattended.count
    }
    metric[:unassigned] = @open_conversations.unassigned.count if params[:type].equal?(:account)
    metric[:resolved] = scope.conversations.where(account_id: @account.id).resolved.count
    metric
  end

  def team_conversion_metrics
    return [] unless @qualified_stage.present? && @won_stage.present?

    teams = Team.where(account_id: account.id).page(params[:page]).per(RESULTS_PER_PAGE)

    teams.each_with_object([]) do |team, arr|
      arr << {
        id: team.id,
        name: team.name.humanize,
        metric: live_conversions(relation: team.contacts)
      }
    end
  end

  def data_source_conversion_metrics
    return [] unless @qualified_stage.present? && @won_stage.present?

    data_sources = CustomAttributeDefinition.find_by(account_id: account.id, attribute_key: 'nguon_thong_tin').attribute_values

    data_sources.each_with_object([]).with_index do |(data_source, arr), index|
      base_relation =
        Contact.where("custom_attributes->>'nguon_thong_tin' = ?", data_source)
      arr << {
        id: index,
        name: data_source,
        metric: live_conversions(relation: base_relation)
      }
    end
  end

  def agent_conversion_metrics
    return [] unless @qualified_stage.present? && @won_stage.present?

    account_users = @account.account_users.page(params[:page]).per(RESULTS_PER_PAGE)

    account_users.each_with_object([]) do |account_user, arr|
      @user = account_user.user
      arr << {
        id: @user.id,
        name: @user.name,
        email: @user.email,
        thumbnail: @user.avatar_url,
        availability: account_user.availability_status,
        metric: live_conversions(relation: user.assigned_contacts)
      }
    end
  end

  def inbox_conversion_metrics
    return [] unless @qualified_stage.present? && @won_stage.present?

    inboxes = @account.inboxes.page(params[:page]).per(RESULTS_PER_PAGE)

    inboxes.each_with_object([]) do |inbox, arr|
      arr << {
        id: inbox.id,
        name: inbox.name,
        inbox_type: inbox.inbox_type,
        thumbnail: inbox.avatar_url,
        metric: live_conversions(relation: inbox.contacts)
      }
    end
  end

  def live_conversions(relation: Contact.all)
    metric = {
      won: relation.where(account_id: account.id, stage_id: @won_stage.id, created_at: range).distinct.count,
      qualified: relation.where(account_id: account.id, stage_id: (@qualified_stage.id.to_i)..., created_at: range).distinct.count
    }
    metric[:ratio] = (metric[:qualified].zero? ? 0 : (metric[:won] / metric[:qualified])).round
    metric
  end

  def contacts_by_stage
    stages = Stage.where(account_id: @account.id)

    result = {}
    stages.each do |stage|
      result[stage.code] = @user ? stage.contacts.where(assignee_id: @user.id).count : stage.contacts.count
    end
    result
  end

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
