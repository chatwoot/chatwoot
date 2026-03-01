namespace :saas do
  desc 'Seed default SaaS plans'
  task seed_plans: :environment do
    plans = [
      {
        name: 'Free',
        price_cents: 0,
        interval: 'month',
        agent_limit: 2,
        inbox_limit: 2,
        ai_tokens_monthly: 10_000,
        features: { basic_reports: true },
        active: true
      },
      {
        name: 'Starter',
        price_cents: 2900,
        interval: 'month',
        agent_limit: 5,
        inbox_limit: 10,
        ai_tokens_monthly: 100_000,
        features: { basic_reports: true, advanced_reports: true, automations: true },
        active: true
      },
      {
        name: 'Pro',
        price_cents: 9900,
        interval: 'month',
        agent_limit: 25,
        inbox_limit: 50,
        ai_tokens_monthly: 500_000,
        features: { basic_reports: true, advanced_reports: true, automations: true, ai_agents: true, voice: true },
        active: true
      },
      {
        name: 'Enterprise',
        price_cents: 29_900,
        interval: 'month',
        agent_limit: 100,
        inbox_limit: 200,
        ai_tokens_monthly: 2_000_000,
        features: { basic_reports: true, advanced_reports: true, automations: true, ai_agents: true, voice: true, sla: true,
                    custom_branding: true },
        active: true
      }
    ]

    plans.each do |plan_attrs|
      plan = Saas::Plan.find_or_initialize_by(name: plan_attrs[:name])
      plan.assign_attributes(plan_attrs)
      plan.save!
      puts "  -> #{plan.name}: $#{(plan.price_cents / 100.0).round(2)}/#{plan.interval} (#{plan.agent_limit} agents, #{plan.inbox_limit} inboxes)"
    end

    puts "\nSeeded #{plans.size} plans successfully."
  end
end
