class V2::Reports::AllConversationMetricsBuilder
  BATCH_SIZE = 500

  attr_reader :account, :params

  def initialize(account, params = {})
    @account = account
    @params = params
    @preloader = V2::Reports::ConversationDataPreloader.new(account, params)
    @row_builder = V2::Reports::ConversationRowBuilder.new(@preloader)
  end

  def build
    result = []

    conversations_scope
      .includes(:inbox, :contact, :team, :csat_survey_response)
      .find_in_batches(batch_size: BATCH_SIZE) do |batch|
        @preloader.preload_batch_data(batch.map(&:id))
        batch.each { |conversation| result << @row_builder.build_row(conversation) }
      end

    result
  end

  def build_streaming
    conversations_scope
      .includes(:inbox, :contact, :team, :csat_survey_response)
      .find_in_batches(batch_size: BATCH_SIZE) do |batch|
        @preloader.preload_batch_data(batch.map(&:id))
        batch.each { |conversation| yield @row_builder.build_row(conversation) }
      end
  end

  private

  def conversations_scope
    @conversations_scope ||= begin
      scope = account.conversations
                     .select(:id, :display_id, :created_at, :inbox_id, :team_id,
                             :contact_id, :custom_attributes, :cached_label_list)
      scope = apply_basic_filters(scope)
      scope = apply_time_filters(scope)
      apply_user_filter(scope)
    end
  end

  def apply_basic_filters(scope)
    scope = scope.where(inbox_id: params[:inbox_ids]) if params[:inbox_ids].present?
    scope = scope.where(team_id: params[:team_ids])   if params[:team_ids].present?
    scope
  end

  def apply_time_filters(scope)
    scope = scope.where('conversations.created_at >= ?', Time.zone.at(params[:since].to_i)) if params[:since].present?
    scope = scope.where('conversations.created_at <= ?', Time.zone.at(params[:until].to_i)) if params[:until].present?
    scope
  end

  def apply_user_filter(scope)
    return scope if params[:user_ids].blank?

    scope
      .joins(:conversation_participants)
      .where(conversation_participants: { user_id: params[:user_ids] })
      .distinct
  end
end
