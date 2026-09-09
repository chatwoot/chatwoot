# frozen_string_literal: true

namespace :priority_groups do
  desc 'Create a priority group for an account: rake "priority_groups:create[ACCOUNT_ID,Group name]"'
  task :create, [:account_id, :name] => :environment do |_task, args|
    account = Account.find(args[:account_id])
    group = account.priority_groups.find_or_create_by!(name: args[:name].presence || 'VIP Manager')

    puts "Priority group ##{group.id} '#{group.name}' is available in account ##{account.id}"
  end
end
