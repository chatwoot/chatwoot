module Enterprise::Api::V1::Accounts::InboxesController
  def inbox_attributes
    super + ee_inbox_attributes
  end

  def ee_inbox_attributes
    [auto_assignment_config: [:max_assignment_limit]]
  end

  private

  def allowed_channel_types
    super + ['voice']
  end

  def channel_type_from_params
    case permitted_params[:channel][:type]
    when 'voice'
      Channel::Voice
    else
      super
    end
  end

  def account_channels_method
    case permitted_params[:channel][:type]
    when 'voice'
      Current.account.voice_channels
    else
      super
    end
  end
end
