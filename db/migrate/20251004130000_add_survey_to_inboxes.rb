class AddSurveyToInboxes < ActiveRecord::Migration[7.1]
  def change
    add_reference :inboxes, :survey, foreign_key: true, index: true
  end
end
