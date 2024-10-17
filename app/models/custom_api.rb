# == Schema Information
#
# Table name: custom_apis
#
#  id                 :bigint           not null, primary key
#  api_key            :string           not null
#  base_url           :string           not null
#  name               :string           not null
#  orders_last_update :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :integer
#  user_id            :integer
#
class CustomApi < ApplicationRecord
  belongs_to :user
  belongs_to :account

  validates :name, presence: true
  validates :base_url, presence: true
  validates :api_key, presence: true

  after_create :import_service_later, :enable_orders_view
  after_destroy :delete_associated_orders

  def import_service
    Integrations::CustomApi::ImportOrderService.new(custom_api: self)
  end

  def import_service_later
    Integrations::CustomApi::ImportOrdersJob.perform_later(id)
  end

  def enable_orders_view
    account.enable_features('integrations_view')
    account.save
  end

  delegate :import_orders, to: :import_service

  private

  def delete_associated_orders
    Order.where(platform: name).destroy_all
  end
end
