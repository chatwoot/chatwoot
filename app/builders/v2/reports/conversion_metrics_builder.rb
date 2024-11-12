class V2::Reports::ConversionMetricsBuilder
  include DateRangeHelper
  attr_reader :account, :params

  RESULTS_PER_PAGE = 10

  def initialize(account, params)
    @account = account
    @params = params
  end

  def metrics
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

  def team_conversion_metrics
    return [] if @won_stage.blank?

    teams = if filter_by_team?
              Team.where(account_id: account.id, id: @params[:team_id]).page(params[:page]).per(RESULTS_PER_PAGE)
            else
              Team.where(account_id: account.id).page(params[:page]).per(RESULTS_PER_PAGE)
            end

    teams.each_with_object([]) do |team, arr|
      arr << {
        id: team.id,
        name: team.name.humanize,
        metric: live_conversions(relation: team.contacts)
      }
    end
  end

  def data_source_conversion_metrics
    return [] if @won_stage.blank?

    data_sources = CustomAttributeDefinition.find_by(account_id: account.id, attribute_model: :contact_attribute,
                                                     attribute_key: 'data_source')&.attribute_values
    data_sources = Contact.pluck(:initial_channel_type).compact.uniq if data_sources.blank?

    data_sources = Kaminari.paginate_array(data_sources).page(params[:page]).per(RESULTS_PER_PAGE)

    data_sources.each_with_object([]).with_index do |(data_source, arr), index|
      base_relation =
        Contact.where("contacts.custom_attributes->>'data_source' = :value OR contacts.initial_channel_type = :value", value: data_source)
      arr << {
        id: index,
        name: data_source,
        metric: live_conversions(relation: base_relation)
      }
    end
  end

  def team
    return unless filter_by_team?

    @team ||= account.teams.find(params[:team_id])
  end

  def agent_conversion_metrics # rubocop:disable Metrics/AbcSize
    return [] if @won_stage.blank?

    account_users = if filter_by_team?
                      @account.account_users.joins(:team_members).where(team_members: { team_id: team.id }).page(params[:page]).per(RESULTS_PER_PAGE)
                    else
                      @account.account_users.page(params[:page]).per(RESULTS_PER_PAGE)
                    end

    account_users.each_with_object([]) do |account_user, arr|
      @user = account_user.user
      arr << {
        id: @user.id,
        name: @user.name,
        email: @user.email,
        thumbnail: @user.avatar_url,
        availability: account_user.availability_status,
        metric: live_conversions(relation: @user.assigned_contacts)
      }
    end
  end

  def inbox_conversion_metrics # rubocop:disable Metrics/AbcSize
    return [] if @won_stage.blank?

    inboxes = if filter_by_team?
                @account.inboxes.includes([:channel]).joins(:member_teams).where(team_id: team.id).distinct
                        .or(@account.inboxes.includes([:channel]).joins(:member_teams).where(member_teams: { id: team.id }).distinct)
              else
                @account.inboxes.page(params[:page]).per(RESULTS_PER_PAGE)
              end

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
      won_count: relation.joins(:first_contact_transaction).where(account_id: account.id, stage_id: @won_stage.id,
                                                                  first_contact_transaction: { created_at: range }).distinct.count.to_f,
      total_count: relation.where(account_id: account.id, created_at: range).distinct.count.to_f
    }
    metric[:ratio] = (metric[:total_count].zero? ? 0 : (metric[:won_count] / metric[:total_count] * 100)).round
    metric
  end

  def filter_by_team?
    @params[:team_id].present?
  end
end
