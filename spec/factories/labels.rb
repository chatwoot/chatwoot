# frozen_string_literal: true

# == Schema Information
#
# Table name: labels
#
#  id                :bigint           not null, primary key
#  allow_auto_assign :boolean          default(FALSE)
#  color             :string           default("#1f93ff"), not null
#  description       :text
#  show_on_sidebar   :boolean
#  title             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint
#
# Indexes
#
#  index_labels_on_account_id            (account_id)
#  index_labels_on_allow_auto_assign     (allow_auto_assign)
#  index_labels_on_title_and_account_id  (title,account_id) UNIQUE
#
FactoryBot.define do
  factory :label do
    account
    sequence(:title) { |n| "Label_#{n}" }
  end
end
