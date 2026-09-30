module Enterprise::Api::V1::Accounts::Captain::PreferencesController
  def update
    return super unless params.key?(:copilot_assistant_id)

    assistant_id = params[:copilot_assistant_id]
    unless valid_copilot_assistant_id?(assistant_id)
      return render json: { error: 'Copilot assistant ID must be an integer or null' }, status: :unprocessable_content
    end

    @current_account.captain_assistants.find(assistant_id) if assistant_id
    @current_account.copilot_assistant_id = assistant_id&.to_i

    return super if captain_params.any?

    # Older model overrides must not block an unrelated Copilot choice.
    # rubocop:disable Rails/SkipsModelValidations
    @current_account.update_columns(settings: @current_account.settings, updated_at: Time.current)
    # rubocop:enable Rails/SkipsModelValidations
    render json: preferences_payload
  end

  private

  def valid_copilot_assistant_id?(assistant_id)
    assistant_id.nil? || assistant_id.is_a?(Integer) || assistant_id.to_s.match?(/\A\d+\z/)
  end

  def preferences_payload
    super.merge(
      copilot_assistant_id: Current.account.copilot_assistant_id,
      copilot_tools: copilot_tools
    )
  end

  def copilot_tools
    assistant = Current.account.captain_assistants.find_by(id: Current.account.copilot_assistant_id) ||
                Current.account.captain_assistants.first
    return [] unless assistant

    Captain::Copilot::ChatService.tool_inventory(assistant: assistant, user: Current.user).map do |tool|
      { name: tool.class.name.demodulize.underscore, available: tool.active? }
    end
  end
end
