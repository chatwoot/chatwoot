module Enterprise::Api::V2::Widget::BaseController
  private

  def ai_agent_active?
    inbox.captain_active?
  end
end
