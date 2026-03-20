# frozen_string_literal: true

namespace :portal do # rubocop:disable Metrics/BlockLength
  desc 'Clone a help center portal with all its categories, folders, and articles. Optionally clone to another account.'
  task :clone, %i[portal_id target_account_id] => :environment do |_task, args| # rubocop:disable Metrics/BlockLength
    portal_id = args[:portal_id]
    target_account_id = args[:target_account_id]

    if portal_id.blank?
      puts 'Usage: rails portal:clone[<portal_id>] or rails portal:clone[<portal_id>,<target_account_id>]'
      next
    end

    source_portal = Portal.find_by(id: portal_id)
    unless source_portal
      puts "ERROR: Portal with ID #{portal_id} not found."
      next
    end

    target_account = if target_account_id.present?
                       Account.find_by(id: target_account_id).tap do |account|
                         unless account
                           puts "ERROR: Account with ID #{target_account_id} not found."
                           next
                         end
                       end
                     else
                       source_portal.account
                     end
    next unless target_account

    cross_account = target_account.id != source_portal.account_id
    if cross_account
      default_author = target_account.administrators.first || target_account.agents.first
      unless default_author
        puts "ERROR: Target account #{target_account.id} has no administrators or agents to assign as article author."
        next
      end
      puts "Cross-account clone: articles will be authored by #{default_author.name} (ID: #{default_author.id})"
    end

    puts "Cloning portal '#{source_portal.name}' (ID: #{source_portal.id}) to account #{target_account.id}..."

    old_to_new_category = {}
    old_to_new_folder = {}
    old_to_new_article = {}

    ActiveRecord::Base.transaction do # rubocop:disable Metrics/BlockLength
      # 1. Clone the portal
      new_slug = "#{source_portal.slug}-copy-#{Time.now.utc.to_i}"
      new_portal = source_portal.dup
      new_portal.slug = new_slug
      new_portal.custom_domain = nil
      new_portal.channel_web_widget_id = nil
      new_portal.account_id = target_account.id
      new_portal.name = "#{source_portal.name} (Copy)"
      new_portal.save!
      puts "Created portal '#{new_portal.name}' (ID: #{new_portal.id}, slug: #{new_portal.slug})"

      # Copy logo if present
      if source_portal.logo.attached?
        new_portal.logo.attach(source_portal.logo.blob)
        puts 'Copied portal logo.'
      end

      # 2. Clone categories (without self-referential FKs first)
      puts 'Cloning categories...'
      source_portal.categories.find_each do |category|
        new_category = category.dup
        new_category.portal_id = new_portal.id
        new_category.parent_category_id = nil
        new_category.associated_category_id = nil
        new_category.save!
        old_to_new_category[category.id] = new_category.id
      end
      puts "Cloned #{old_to_new_category.count} categories."

      # 3. Remap category self-referential relationships
      source_portal.categories.where.not(parent_category_id: nil).find_each do |category|
        new_parent_id = old_to_new_category[category.parent_category_id]
        next unless new_parent_id

        new_category = Category.find(old_to_new_category[category.id])
        new_category.update!(parent_category_id: new_parent_id)
      end

      source_portal.categories.where.not(associated_category_id: nil).find_each do |category|
        new_assoc_id = old_to_new_category[category.associated_category_id]
        next unless new_assoc_id

        new_category = Category.find(old_to_new_category[category.id])
        new_category.update!(associated_category_id: new_assoc_id)
      end

      # 4. Clone related categories (junction table)
      related_count = 0
      source_portal.categories.find_each do |category|
        category.category_related_categories.find_each do |rc|
          new_category_id = old_to_new_category[rc.category_id]
          new_related_id = old_to_new_category[rc.related_category_id]
          next unless new_category_id && new_related_id

          RelatedCategory.create!(category_id: new_category_id, related_category_id: new_related_id)
          related_count += 1
        end
      end
      puts "Cloned #{related_count} related category links." if related_count.positive?

      # 5. Clone folders
      puts 'Cloning folders...'
      source_portal.folders.find_each do |folder|
        new_folder = folder.dup
        new_folder.category_id = old_to_new_category[folder.category_id]
        new_folder.save!
        old_to_new_folder[folder.id] = new_folder.id
      end
      puts "Cloned #{old_to_new_folder.count} folders."

      # 6. Clone articles (without associated_article_id first)
      puts 'Cloning articles...'
      source_portal.articles.find_each do |article|
        new_article = article.dup
        new_article.portal_id = new_portal.id
        new_article.category_id = old_to_new_category[article.category_id] if article.category_id
        new_article.folder_id = old_to_new_folder[article.folder_id] if article.folder_id
        new_article.author_id = default_author.id if cross_account
        new_article.associated_article_id = nil
        new_article.slug = "#{Time.now.utc.to_i}-#{SecureRandom.hex(4)}-#{article.slug.last(100)}"
        new_article.views = 0
        new_article.save!
        old_to_new_article[article.id] = new_article.id
      end
      puts "Cloned #{old_to_new_article.count} articles."

      # 7. Remap article self-referential relationships
      source_portal.articles.where.not(associated_article_id: nil).find_each do |article|
        new_assoc_id = old_to_new_article[article.associated_article_id]
        next unless new_assoc_id

        new_article = Article.find(old_to_new_article[article.id])
        new_article.update!(associated_article_id: new_assoc_id)
      end

      puts "\nCloning complete!"
      puts "New portal ID: #{new_portal.id}"
      puts "New portal slug: #{new_portal.slug}"
      puts "Summary: #{old_to_new_category.count} categories, #{old_to_new_folder.count} folders, #{old_to_new_article.count} articles"
    end
  rescue ActiveRecord::RecordNotFound
    puts "ERROR: Portal with ID #{portal_id} not found."
  rescue ActiveRecord::RecordInvalid => e
    puts "ERROR: Failed to clone portal. Validation error: #{e.message}"
  end
end
