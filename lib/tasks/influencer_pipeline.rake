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
end
