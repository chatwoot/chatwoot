class IndexController < ActionController::Base
  include SwitchLocale

  layout false

  def index
    render "index"
  end
end
