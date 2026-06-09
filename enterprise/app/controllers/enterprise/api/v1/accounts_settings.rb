module Enterprise::Api::V1::AccountsSettings
  private

  def permitted_settings_attributes
    super + [{ conversation_required_attributes: [] }]
  end
end
