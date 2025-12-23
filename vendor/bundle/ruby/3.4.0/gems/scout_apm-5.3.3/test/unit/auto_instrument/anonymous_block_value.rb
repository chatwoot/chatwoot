class TestController < ApplicationController
  def index
    quests = policy_scope(Quest.open)
    quests.each { _1.current_user = current_user }
    respond_with_proto quests
  end
end