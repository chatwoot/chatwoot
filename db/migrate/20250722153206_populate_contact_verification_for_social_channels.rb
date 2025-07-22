class PopulateContactVerificationForSocialChannels < ActiveRecord::Migration[7.0]
  def change
    Migration::PopulateContactVerificationJob.perform_later
  end
end
