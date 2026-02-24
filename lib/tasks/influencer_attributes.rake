namespace :influencer_attributes do
  desc 'Seed custom attribute definitions for influencer metrics'
  task seed: :environment do
    attributes = [
      { attribute_key: 'followers', attribute_display_name: 'Followers', attribute_display_type: 'number' },
      { attribute_key: 'engagement_rate', attribute_display_name: 'Engagement Rate', attribute_display_type: 'number' },
      { attribute_key: 'posts_count', attribute_display_name: 'Number of Posts', attribute_display_type: 'number' },
      { attribute_key: 'posts_per_month', attribute_display_name: 'Posts per Month', attribute_display_type: 'number' },
      { attribute_key: 'avg_views', attribute_display_name: 'Average Views', attribute_display_type: 'number' },
      { attribute_key: 'avg_reel_likes', attribute_display_name: 'Average Reel Likes', attribute_display_type: 'number' },
      { attribute_key: 'avg_likes', attribute_display_name: 'Average Likes', attribute_display_type: 'number' },
      { attribute_key: 'avg_comments', attribute_display_name: 'Average Comments', attribute_display_type: 'number' }
    ]

    Account.find_each do |account|
      attributes.each do |attr|
        CustomAttributeDefinition.find_or_create_by!(
          account: account,
          attribute_model: 'contact_attribute',
          attribute_key: attr[:attribute_key]
        ) do |definition|
          definition.attribute_display_name = attr[:attribute_display_name]
          definition.attribute_display_type = attr[:attribute_display_type]
        end
      end
      puts "Seeded influencer attributes for account ##{account.id}"
    end
  end
end
