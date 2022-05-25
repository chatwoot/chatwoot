# == Schema Information
#
# Table name: dashboard_apps
#
#  id         :bigint           not null, primary key
#  content    :jsonb
#  title      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  user_id    :bigint
#
# Indexes
#
#  index_dashboard_apps_on_account_id  (account_id)
#  index_dashboard_apps_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#
class DashboardApp < ApplicationRecord
  belongs_to :user
  belongs_to :account
end
