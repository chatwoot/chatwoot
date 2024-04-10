class RemoveDuplicateAccessTokensForExistingUsers < ActiveRecord::Migration[6.0]
  def up
    # find all models and group them on owner
    grouped_tokens = AccessToken.all.group_by(&:owner)
    grouped_tokens.each_value do |duplicates|
      # we want to keep the latest token as it is being used in all requests
      duplicates.pop
      # Remaining ones are duplicates, delete them all
      duplicates.each { |duplicate| AccessToken.find_by(id: duplicate).destroy }
    end
  end
end
