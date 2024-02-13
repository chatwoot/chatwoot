class FixSurveys < ActiveRecord::Migration[7.0]
  def change
    Migration::FixCsatOnReplies.perform_later
  end
end
