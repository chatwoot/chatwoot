# rubocop:disable Metrics/BlockLength
namespace :influencers do
  desc 'Create influencer label and pipeline stages for an account'
  task :setup_pipeline, [:account_id] => :environment do |_t, args|
    account = Account.find(args[:account_id])
    label = account.labels.find_or_create_by!(title: 'influencer') do |l|
      l.color = '#8B5CF6'
      l.description = 'Influencer pipeline'
      l.show_on_sidebar = true
    end

    stages = %w[Qualified Outreach Negotiation Contracted Active Completed]
    stages.each_with_index do |title, idx|
      label.pipeline_stages.find_or_create_by!(title: title) do |s|
        s.position = idx
      end
    end

    puts "Created influencer label (id=#{label.id}) with #{stages.size} pipeline stages for account #{account.id}"
  end

  desc 'Export influencer profiles, contacts and searches to db/fixtures/influencer_profiles.json'
  task :export_fixture, [:account_id] => :environment do |_t, args|
    abort 'Usage: rake influencers:export_fixture[ACCOUNT_ID]' if args[:account_id].blank?

    account = Account.find(args[:account_id])
    columns = InfluencerProfile.column_names - %w[id contact_id account_id created_at updated_at lock_version]

    profiles_data = account.influencer_profiles.includes(:contact).order(:id).map do |profile|
      contact = profile.contact
      entry = {
        'contact' => {
          'identifier' => contact.identifier,
          'name' => contact.name,
          'contact_type' => contact.contact_type,
          'custom_attributes' => contact.custom_attributes,
          'additional_attributes' => contact.additional_attributes
        }
      }
      columns.each { |col| entry[col] = profile.read_attribute(col) }
      entry
    end

    searches_data = account.influencer_searches.order(:id).map do |search|
      { 'query_params' => search.query_params, 'query_signature' => search.query_signature,
        'page_size' => search.page_size, 'results_count' => search.results_count,
        'credits_used' => search.credits_used, 'created_at' => search.created_at }
    end

    fixture = { 'exported_at' => Time.current.iso8601, 'source_account_id' => account.id,
                'profiles' => profiles_data, 'searches' => searches_data }

    output_path = Rails.root.join('db/fixtures/influencer_profiles.json')
    FileUtils.mkdir_p(File.dirname(output_path))
    File.write(output_path, JSON.pretty_generate(fixture))

    puts "Exported #{profiles_data.size} profiles and #{searches_data.size} searches to #{output_path}"
    puts "File size: #{(File.size(output_path) / 1024.0 / 1024.0).round(2)} MB"
  end

  desc 'Import influencer profiles from db/fixtures/influencer_profiles.json into the given account'
  task :import_fixture, [:account_id] => :environment do |_t, args|
    abort 'Usage: rake influencers:import_fixture[ACCOUNT_ID]' if args[:account_id].blank?

    account = Account.find(args[:account_id])
    fixture_path = Rails.root.join('db/fixtures/influencer_profiles.json')
    abort "Fixture file not found at #{fixture_path}" unless File.exist?(fixture_path)

    fixture = JSON.parse(File.read(fixture_path))
    profiles_data = fixture['profiles'] || []
    searches_data = fixture['searches'] || []
    columns = InfluencerProfile.column_names - %w[id contact_id account_id created_at updated_at lock_version]

    imported = 0
    skipped = 0

    ActiveRecord::Base.transaction do
      profiles_data.each do |data|
        contact_data = data['contact']

        contact = account.contacts.find_or_initialize_by(identifier: contact_data['identifier'])
        if contact.new_record?
          contact.assign_attributes(name: contact_data['name'], contact_type: contact_data['contact_type'],
                                    custom_attributes: contact_data['custom_attributes'] || {},
                                    additional_attributes: contact_data['additional_attributes'] || {})
          contact.save!
        end

        profile = account.influencer_profiles.find_or_initialize_by(username: data['username'], platform: data['platform'])
        if profile.persisted?
          skipped += 1
          puts "  Skipped (exists): #{data['username']}"
          next
        end

        profile.contact = contact
        columns.each do |col|
          value = data[col]
          value = Time.zone.parse(value) if value.is_a?(String) && col.end_with?('_at')
          profile.write_attribute(col, value)
        end
        # Reset rejected profiles to enriched for fresh review on production
        profile.status = :enriched if profile.rejected?
        profile.save!
        imported += 1
        puts "  Imported: #{data['username']} (status: #{profile.status})"
      end

      searches_data.each do |s|
        sig = s['query_signature']
        next if sig.present? && account.influencer_searches.exists?(query_signature: sig)

        account.influencer_searches.create!(query_params: s['query_params'], query_signature: s['query_signature'],
                                            page_size: s['page_size'] || 5, results: [], results_count: s['results_count'],
                                            credits_used: s['credits_used'], created_at: s['created_at'])
      end
    end

    puts "\nDone. Imported: #{imported}, Skipped: #{skipped}, Searches: #{searches_data.size}"
  end
end
# rubocop:enable Metrics/BlockLength
