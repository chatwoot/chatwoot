class Api::V1::Accounts::LeadFollowUpSequencesController < Api::V1::Accounts::BaseController
  before_action :set_inbox, only: [:index, :create, :available_templates]
  before_action :set_sequence, only: [:show, :update, :destroy, :activate, :deactivate, :enrolled_conversations, :cancel_follow_ups, :enrollment_timeline]

  def index
    @sequences = Current.account.lead_follow_up_sequences.includes(:inbox)
    @sequences = @sequences.where(inbox_id: @inbox.id) if @inbox
  end

  def show; end

  def create
    @sequence = Current.account.lead_follow_up_sequences.new(sequence_params)
    if @sequence.save
      render :show, status: :created
    else
      render json: { errors: @sequence.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @sequence.update!(sequence_params)
    render :show
  end

  def destroy
    @sequence.deactivate! if @sequence.active?
    @sequence.destroy!
    head :no_content
  end

  def activate
    @sequence.activate!
    render :show
  end

  def deactivate
    @sequence.deactivate!
    render :show
  end

  def available_templates
    inbox = Current.account.inboxes.find(params[:inbox_id])

    unless inbox.inbox_type == 'Whatsapp'
      return render json: { error: 'Inbox must be WhatsApp' }, status: :unprocessable_entity
    end

    templates = inbox.channel.message_templates || []

    render json: {
      templates: templates.map do |t|
        {
          name: t['name'],
          language: t['language'],
          status: t['status'],
          category: t['category'],
          components: t['components']
        }
      end
    }
  end

  def preview_eligible
    inbox_id = params[:inbox_id]
    sequence_id = params[:sequence_id]
    trigger_conditions = params[:trigger_conditions] || {}
    stop_on_contact_reply = params.dig(:settings, :stop_on_contact_reply) || false

    unless inbox_id
      return render json: { error: 'inbox_id is required' }, status: :unprocessable_entity
    end

    # Leer include_completed de trigger_conditions, default a true
    include_completed = trigger_conditions.dig('enrollment_filter', 'include_completed')
    include_completed = true if include_completed.nil?

    query = LeadRetargeting::EligibleConversationsQueryBuilder.call(
      account_id: Current.account.id,
      inbox_id: inbox_id,
      trigger_conditions: trigger_conditions,
      include_cancelled: true,
      include_completed: include_completed,
      stop_on_contact_reply: stop_on_contact_reply,
      sequence_id: sequence_id
    )

    total_count = query.count

    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || 20, 100].min
    conversations = query
                    .includes(:contact)
                    .order(created_at: :desc)
                    .limit(per_page)
                    .offset((page - 1) * per_page)

    render json: {
      total_count: total_count,
      conversations: conversations.map do |conv|
        {
          id: conv.id,
          display_id: conv.display_id,
          status: conv.status,
          created_at: conv.created_at,
          contact: {
            id: conv.contact&.id,
            name: conv.contact&.name,
            phone_number: conv.contact&.phone_number
          }
        }
      end,
      page: page,
      per_page: per_page,
      total_pages: (total_count / per_page.to_f).ceil
    }
  rescue StandardError => e
    Rails.logger.error "Error previewing eligible conversations: #{e.message}"
    render json: { error: 'Failed to preview eligible conversations' }, status: :internal_server_error
  end

  def cancel_follow_ups
    enrollment_ids = params[:follow_up_ids] || params[:enrollment_ids] || []

    if enrollment_ids.empty?
      return render json: { error: 'No enrollment IDs provided' }, status: :bad_request
    end

    enrollments = @sequence.sequence_enrollments.where(id: enrollment_ids)
    cancelled_count = 0

    enrollments.each do |enrollment|
      if enrollment.status == 'active'
        # Cancel the active follow_up job if exists
        follow_up = enrollment.active_follow_up
        if follow_up
          follow_up.cancel_job!
          follow_up.mark_as_cancelled!('Manually cancelled by user')
        end

        # Cancel the enrollment
        enrollment.cancel!('Manually cancelled by user')
        cancelled_count += 1
      end
    end

    # Update stats
    @sequence.update_stats!

    render json: {
      success: true,
      cancelled_count: cancelled_count,
      message: "Successfully cancelled #{cancelled_count} enrollment(s)"
    }
  rescue StandardError => e
    Rails.logger.error "Error cancelling enrollments: #{e.message}"
    render json: { error: 'Failed to cancel enrollments' }, status: :internal_server_error
  end

  def enrolled_conversations
    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || 50, 100].min
    status_filter = params[:status]

    # Use sequence_enrollments instead of conversation_follow_ups
    enrollments = @sequence.sequence_enrollments
                           .includes(conversation: :contact, active_follow_up: [])
                           .order(enrolled_at: :desc)

    enrollments = enrollments.where(status: status_filter) if status_filter.present?

    total_count = enrollments.count
    enrollments = enrollments.limit(per_page).offset((page - 1) * per_page)

    render json: {
      total_count: total_count,
      total_steps: @sequence.enabled_steps.size,
      enrolled_conversations: enrollments.map do |enrollment|
        # Skip enrollments with missing conversations
        next unless enrollment.conversation

        # El follow_up es la fuente de verdad del estado actual
        follow_up = enrollment.active_follow_up

        # Si el follow_up está en estado terminal, tiene prioridad sobre el enrollment
        terminal_statuses = %w[completed cancelled failed]
        effective_status = if follow_up && terminal_statuses.include?(follow_up.status)
                             follow_up.status
                           else
                             enrollment.status
                           end

        effective_step = follow_up&.current_step || enrollment.current_step
        effective_completion_reason = enrollment.completion_reason ||
                                      follow_up&.metadata&.dig('completion_reason') ||
                                      follow_up&.metadata&.dig('cancellation_reason')
        effective_completed_at = enrollment.completed_at || follow_up&.completed_at

        current_step_data = @sequence.enabled_steps[effective_step]

        {
          id: enrollment.id,
          enrollment_id: enrollment.id,
          conversation_id: enrollment.conversation.id,
          display_id: enrollment.conversation.display_id,
          status: effective_status,
          current_step: effective_step,
          current_step_type: current_step_data&.dig('type'),
          current_step_name: current_step_data&.dig('name'),
          next_action_at: follow_up&.next_action_at,
          enrolled_at: enrollment.enrolled_at,
          completed_at: effective_completed_at,
          completion_reason: effective_completion_reason,
          created_at: enrollment.created_at,
          updated_at: enrollment.updated_at,
          metadata: enrollment.metadata,
          contact: {
            id: enrollment.conversation.contact&.id,
            name: enrollment.conversation.contact&.name,
            phone_number: enrollment.conversation.contact&.phone_number
          },
          conversation_status: enrollment.conversation.status
        }
      end.compact,
      page: page,
      per_page: per_page,
      total_pages: (total_count / per_page.to_f).ceil,
      status_counts: {
        active: @sequence.sequence_enrollments.active.count,
        completed: @sequence.sequence_enrollments.completed.count,
        cancelled: @sequence.sequence_enrollments.cancelled.count,
        failed: @sequence.sequence_enrollments.failed.count
      }
    }
  rescue StandardError => e
    Rails.logger.error "Error fetching enrolled conversations: #{e.message}"
    render json: { error: 'Failed to fetch enrolled conversations' }, status: :internal_server_error
  end

  # Get timeline of events for a specific enrollment
  def enrollment_timeline
    enrollment = @sequence.sequence_enrollments.find(params[:enrollment_id])

    events = enrollment.enrollment_events
                      .order(occurred_at: :desc)
                      .map do |event|
      {
        id: event.id,
        event_type: event.event_type,
        step_id: event.step_id,
        step_index: event.step_index,
        step_name: event.metadata&.dig('step_name'),
        occurred_at: event.occurred_at,
        description: event.description,
        metadata: event.metadata,
        created_at: event.created_at
      }
    end

    render json: {
      enrollment_id: enrollment.id,
      conversation_id: enrollment.conversation_id,
      events: events
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Enrollment not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error "Error fetching enrollment timeline: #{e.message}"
    render json: { error: 'Failed to fetch enrollment timeline' }, status: :internal_server_error
  end

  private

  def set_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id]) if params[:inbox_id]
  end

  def set_sequence
    @sequence = Current.account.lead_follow_up_sequences.find(params[:id])
  end

  def sequence_params
    permitted = params.require(:lead_follow_up_sequence).permit(
      :name,
      :description,
      :active,
      :inbox_id,
      :source_type
    )

    # Extract complex nested structures using to_unsafe_h to bypass strong parameters
    raw_params = params[:lead_follow_up_sequence]
    permitted[:steps] = raw_params[:steps].map(&:to_unsafe_h) if raw_params[:steps].present?
    permitted[:trigger_conditions] = raw_params[:trigger_conditions].to_unsafe_h if raw_params[:trigger_conditions].present?
    permitted[:settings] = raw_params[:settings].to_unsafe_h if raw_params[:settings].present?
    permitted[:source_config] = raw_params[:source_config].to_unsafe_h if raw_params[:source_config].present?
    permitted[:first_contact_config] = raw_params[:first_contact_config].to_unsafe_h if raw_params[:first_contact_config].present?

    permitted
  end
end
