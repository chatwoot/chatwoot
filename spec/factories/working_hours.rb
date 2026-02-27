# frozen_string_literal: true

# == Schema Information
#
# Table name: working_hours
#
#  id             :bigint           not null, primary key
#  close_hour     :integer
#  close_minutes  :integer
#  closed_all_day :boolean          default(FALSE)
#  day_of_week    :integer          not null
#  open_all_day   :boolean          default(FALSE)
#  open_hour      :integer
#  open_minutes   :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint
#  inbox_id       :bigint
#
# Indexes
#
#  index_working_hours_on_account_id  (account_id)
#  index_working_hours_on_inbox_id    (inbox_id)
#
FactoryBot.define do
  factory :working_hour do
    inbox
    day_of_week   { 1 }
    open_hour     { 9 }
    open_minutes  { 0 }
    close_hour    { 17 }
    close_minutes { 0 }
  end
end
