namespace :labels do
  desc 'Sync ActsAsTaggableOn::Tags with existing labels'
  task sync_tags: :environment do
    puts 'Starting label tags synchronization...'
    puts ''

    total_labels = Label.count
    created_count = 0
    existing_count = 0

    puts "Found #{total_labels} labels to process"
    puts ''

    Label.find_each.with_index do |label, index|
      tag = ActsAsTaggableOn::Tag.find_or_create_by!(name: label.title)

      if tag.previously_new_record?
        created_count += 1
        puts "✓ Created tag '#{label.title}'"
      else
        existing_count += 1
      end

      print "\rProgress: #{index + 1}/#{total_labels}" if (index + 1) % 10 == 0
    end

    puts "\n"
    puts 'Synchronization complete!'
    puts "Created: #{created_count} tags"
    puts "Already existed: #{existing_count} tags"
    puts "Total processed: #{total_labels} labels"
  end
end
