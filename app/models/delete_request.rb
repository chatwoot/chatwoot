# == Schema Information
#
# Table name: delete_requests
#
#  id                :bigint           not null, primary key
#  completed_at      :datetime
#  confirmation_code :string           not null
#  deleted_type      :string
#  status            :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint
#  deleted_id        :integer
#  fb_id             :string           not null
#
# Indexes
#
#  index_delete_requests_on_account_id         (account_id)
#  index_delete_requests_on_confirmation_code  (confirmation_code) UNIQUE
#
class DeleteRequest < ApplicationRecord
  belongs_to :account, optional: true
  enum :status, %w[pending complete].index_by(&:itself), default: :pending

  before_create :ensure_unqiue_confirmation_code

  private

  def ensure_unqiue_confirmation_code
    max_retries = 3
    retry_count = 0

    begin
      self.confirmation_code = generate_confirmation_code
      raise ActiveRecord::RecordNotUnique if self.class.exists?(confirmation_code: confirmation_code)
    rescue ActiveRecord::RecordNotUnique
      retry_count += 1
      if retry_count > max_retries
        # it's really really unlikely that we'll ever ever hit this case, but just in case
        self.confirmation_code = generate_confirmation_code + SecureRandom.alphanumeric(3)
      else
        retry
      end
    end
  end

  def generate_confirmation_code
    SecureRandom.uuid.delete('-')
  end
end
