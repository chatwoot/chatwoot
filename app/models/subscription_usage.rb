# == Schema Information
#
# Table name: subscription_usage
#
#  id                 :bigint           not null, primary key
#  ai_responses_count :integer          default(0)
#  last_reset_at      :datetime
#  mau_count          :integer          default(0)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  subscription_id    :bigint           not null
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
    
    # Method untuk mengecek apakah telah melebihi batas
    def exceeded_limits?
      subscription = self.subscription
      return false if subscription.max_mau == 0 # Unlimited
      
      mau_count > subscription.max_mau || (subscription.max_ai_responses > 0 && ai_responses_count >= subscription.max_ai_responses)
    end
end
