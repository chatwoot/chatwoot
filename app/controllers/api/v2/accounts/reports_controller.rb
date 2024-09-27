class Api::V2::Accounts::ReportsController < Api::V1::Accounts::BaseController
  include Api::V2::Accounts::ReportsHelper
  include Api::V2::Accounts::HeatmapHelper

  before_action :check_authorization

  def index
    builder = V2::ReportBuilder.new(Current.account, report_params)
    data = builder.build
    render json: data
  end

  def summary
    render json: summary_metrics
  end

  def bot_summary
    summary = V2::ReportBuilder.new(Current.account, current_summary_params).bot_summary
    summary[:previous] = V2::ReportBuilder.new(Current.account, previous_summary_params).bot_summary
    render json: summary
  end

  def agents
    @report_data = generate_agents_report
    generate_csv('agents_report', 'api/v2/accounts/reports/agents')
  end

  def inboxes
    @report_data = generate_inboxes_report
    generate_csv('inboxes_report', 'api/v2/accounts/reports/inboxes')
  end

  def labels
    @report_data = generate_labels_report
    generate_csv('labels_report', 'api/v2/accounts/reports/labels')
  end

  def teams
    @report_data = generate_teams_report
    generate_csv('teams_report', 'api/v2/accounts/reports/teams')
  end

  def conversation_traffic
    @report_data = generate_conversations_heatmap_report
    timezone_offset = (params[:timezone_offset] || 0).to_f
    @timezone = ActiveSupport::TimeZone[timezone_offset]

    generate_csv('conversation_traffic_reports', 'api/v2/accounts/reports/conversation_traffic')
  end

  def conversations
    return head :unprocessable_entity if params[:type].blank?

    render json: conversation_metrics
  end

  def contacts
    return head :unprocessable_entity if params[:type].blank?

    render json: contact_metrics
  end

  def bot_metrics
    bot_metrics = V2::Reports::BotMetricsBuilder.new(Current.account, params).metrics
    render json: bot_metrics
  end

  def agent_contacts_metrics
    agent_contacts = V2::ReportBuilder.new(Current.account, user_params).agent_contacts_by_stage
    render json: agent_contacts
  end

  def agent_conversations_metrics
    agent_conversations = V2::ReportBuilder.new(Current.account, user_params).agent_conversations
    render json: agent_conversations
  end

  def agent_planned_metrics
    agent_planned = V2::ReportBuilder.new(Current.account, user_params).agent_planned
    render json: agent_planned
  end

  def agent_planned_conversations
    agent_planned_conversations = V2::ReportBuilder.new(Current.account, user_params).agent_planned_conversations
    render json: agent_planned_conversations
  end

  def conversions
    return head :unprocessable_entity if params[:criteria_type].blank?

    render json: conversion_metrics
  end

  private

  def generate_csv(filename, template)
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}.csv"
    render layout: false, template: template, formats: [:csv]
  end

  def check_authorization
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator? || Current.account_user.agent?
  end

  def common_params
    {
      type: params[:type].to_sym,
      id: params[:id],
      group_by: params[:group_by],
      business_hours: ActiveModel::Type::Boolean.new.cast(params[:business_hours])
    }
  end

  def current_summary_params
    common_params.merge({
                          since: range[:current][:since],
                          until: range[:current][:until],
                          timezone_offset: params[:timezone_offset]
                        })
  end

  def previous_summary_params
    common_params.merge({
                          since: range[:previous][:since],
                          until: range[:previous][:until],
                          timezone_offset: params[:timezone_offset]
                        })
  end

  def report_params
    common_params.merge({
                          metric: params[:metric],
                          since: params[:since],
                          until: params[:until],
                          timezone_offset: params[:timezone_offset]
                        })
  end

  def conversation_params
    {
      type: params[:type].to_sym,
      user_id: params[:user_id],
      page: params[:page].presence || 1
    }
  end

  def user_params
    {
      user_id: Current.user.id
    }
  end

  def conversion_params
    {
      criteria_type: params[:criteria_type].to_sym || :inbox,
      page: params[:page].presence || 1,
      since: params[:since],
      until: params[:until]
    }
  end

  def range
    {
      current: {
        since: params[:since],
        until: params[:until]
      },
      previous: {
        since: (params[:since].to_i - (params[:until].to_i - params[:since].to_i)).to_s,
        until: params[:since]
      }
    }
  end

  def summary_metrics
    summary = V2::ReportBuilder.new(Current.account, current_summary_params).summary
    summary[:previous] = V2::ReportBuilder.new(Current.account, previous_summary_params).summary
    summary
  end

  def conversation_metrics
    V2::ReportBuilder.new(Current.account, conversation_params).conversation_metrics
  end

  def contact_metrics
    V2::ReportBuilder.new(Current.account, conversation_params).contact_metrics
  end

  def conversion_metrics
    V2::ReportBuilder.new(Current.account, conversion_params).conversion_metrics
  end
end
