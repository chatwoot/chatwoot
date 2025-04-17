# == Schema Information
#
# Table name: subscription_usage
#
#  id                           :bigint           not null, primary key
#  additional_ai_response_count :integer          default(0), not null
#  additional_mau_count         :integer          default(0), not null
#  ai_responses_count           :integer          default(0)
#  last_reset_at                :datetime
#  mau_count                    :integer          default(0)
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  subscription_id              :bigint           not null
#
# Indexes
#
#  index_subscription_usage_on_subscription_id  (subscription_id)
#
# Foreign Keys
#
#  fk_rails_...  (subscription_id => subscriptions.id)
#
class SubscriptionUsage < ApplicationRecord
  self.table_name = 'subscription_usage'
  
  belongs_to :subscription
  
  # Method untuk mereset penggunaan AI response setiap bulan
  def reset_ai_responses
    update(ai_responses_count: 0, last_reset_at: Time.now)
  end
  
  # Method untuk menambah penggunaan MAU
  def increment_mau
    update(mau_count: mau_count + 1)
  end
  
  # Method untuk menambah penggunaan AI response
  def increment_ai_responses(count = 1)
    update(ai_responses_count: ai_responses_count + count)
  end
  
  # Method untuk menambah additional_mau_count
  def increment_additional_mau(count = 1)
    update(additional_mau_count: additional_mau_count + count)
  end
  
  # Method untuk menambah additional_ai_response_count
  def increment_additional_ai_response(count = 1)
    update(additional_ai_response_count: additional_ai_response_count + count)
  end
  
  # Method untuk reset additional count
  def reset_additional_counts
    update(
      additional_mau_count: 0,
      additional_ai_response_count: 0
    )
  end
  
  # Method untuk mendapatkan total batas MAU (termasuk additional)
  def total_max_mau
    max_mau = subscription.max_mau || 0
    additional_mau = subscription.additional_mau || 0
    max_mau + additional_mau
  end
  
  # Method untuk mendapatkan total batas AI Response (termasuk additional)
  def total_max_ai_responses
    max_ai_responses = subscription.max_ai_responses || 0
    additional_ai_responses = subscription.additional_ai_responses || 0
    max_ai_responses + additional_ai_responses
  end
  
  # Method untuk mengecek apakah telah melebihi batas
  def exceeded_limits?
    return false if total_max_mau == 0 # Unlimited
    
    mau_exceeded = total_max_mau > 0 && (mau_count - additional_mau_count) > total_max_mau
    ai_responses_exceeded = total_max_ai_responses > 0 && (ai_responses_count - additional_ai_response_count) >= total_max_ai_responses
    
    mau_exceeded || ai_responses_exceeded
  end
  
  # Method untuk mendapatkan sisa kuota MAU
  def remaining_mau
    return nil if total_max_mau == 0 # Unlimited
    [total_max_mau - (mau_count - additional_mau_count), 0].max
  end
  
  # Method untuk mendapatkan sisa kuota AI Response
  def remaining_ai_responses
    return nil if total_max_ai_responses == 0 # Unlimited
    [total_max_ai_responses - (ai_responses_count - additional_ai_response_count), 0].max
  end
end