# frozen_string_literal: true

namespace :portal do # rubocop:disable Metrics/BlockLength
  desc 'Move a help center portal (with categories, folders, and articles) to another account.'
  task :move, %i[portal_id target_account_id] => :environment do |_task, args| # rubocop:disable Metrics/BlockLength
    portal_id = args[:portal_id]
    target_account_id = args[:target_account_id]

    if portal_id.blank? || target_account_id.blank?
      puts 'Usage: rails portal:move[<portal_id>,<target_account_id>]'
      next
    end

    portal = Portal.find_by(id: portal_id)
    unless portal
      puts "ERROR: Portal with ID #{portal_id} not found."
      next
    end

    target_account = Account.find_by(id: target_account_id)
    unless target_account
      puts "ERROR: Account with ID #{target_account_id} not found."
      next
    end

    if portal.account_id == target_account.id
      puts 'ERROR: Portal already belongs to the target account.'
      next
    end

    fallback_author = target_account.administrators.first || target_account.agents.first
    unless fallback_author
      puts "ERROR: Target account #{target_account.id} has no administrators or agents to assign as fallback author."
      next
    end

    # Build a map of source user emails to target account users for author matching
    source_author_ids = portal.articles.distinct.pluck(:author_id)
    source_authors = User.where(id: source_author_ids).index_by(&:id)
    target_users_by_email = target_account.users.index_by(&:email)

    author_map = {}
    source_authors.each do |id, user|
      match = target_users_by_email[user.email]
      author_map[id] = match ? match.id : fallback_author.id
    end

    matched = author_map.count { |_old, new_id| new_id != fallback_author.id }
    puts "Author mapping: #{matched}/#{author_map.size} authors matched by email, rest assigned to #{fallback_author.name} (ID: #{fallback_author.id})" # rubocop:disable Layout/LineLength
    puts "Moving portal '#{portal.name}' (ID: #{portal.id}) from account #{portal.account_id} to account #{target_account.id}..."

    ActiveRecord::Base.transaction do
      portal.articles.find_each do |article|
        new_author_id = author_map[article.author_id] || fallback_author.id
        article.update_columns(account_id: target_account.id, author_id: new_author_id) # rubocop:disable Rails/SkipsModelValidations
      end

      portal.categories.update_all(account_id: target_account.id) # rubocop:disable Rails/SkipsModelValidations
      portal.update!(account_id: target_account.id, custom_domain: nil, channel_web_widget_id: nil)
      portal.inboxes.update_all(portal_id: nil) # rubocop:disable Rails/SkipsModelValidations

      puts "\nMove complete!"
      puts "Portal '#{portal.name}' (ID: #{portal.id}) now belongs to account #{target_account.id}"
      puts "Summary: #{portal.categories.count} categories, #{portal.folders.count} folders, #{portal.articles.count} articles moved"
    end
  rescue ActiveRecord::RecordInvalid => e
    puts "ERROR: Failed to move portal. Validation error: #{e.message}"
  end
end
