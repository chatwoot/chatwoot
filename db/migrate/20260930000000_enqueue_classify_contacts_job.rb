class EnqueueClassifyContactsJob < ActiveRecord::Migration[7.2]
  def up
    # The delay lets every worker move to the release that has the job before it runs
    Migration::ClassifyContactsJob.set(wait: 10.minutes).perform_later
  end

  def down; end
end
