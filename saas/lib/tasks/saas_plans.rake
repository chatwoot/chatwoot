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

  desc 'Sync SaaS plans to Stripe (creates Products + Prices and stores IDs)'
  task sync_plans_to_stripe: :environment do
    require 'stripe'

    Saas::Plan.active.find_each do |plan|
      if plan.stripe_price_id.present?
        puts "  [skip] #{plan.name} already synced (price=#{plan.stripe_price_id})"
        next
      end

      if plan.free?
        puts "  [skip] #{plan.name} is free — no Stripe product needed"
        next
      end

      product = Stripe::Product.create(
        name: "AirysChat #{plan.name}",
        description: "#{plan.agent_limit} agents, #{plan.inbox_limit} inboxes, #{plan.ai_tokens_monthly.to_fs(:delimited)} AI tokens/mo",
        metadata: { plan_id: plan.id, plan_name: plan.name }
      )

      price = Stripe::Price.create(
        product: product.id,
        unit_amount: plan.price_cents,
        currency: 'brl',
        recurring: { interval: plan.interval }
      )

      plan.update!(stripe_product_id: product.id, stripe_price_id: price.id)
      puts "  [synced] #{plan.name}: product=#{product.id} price=#{price.id}"
    end

    puts "\nStripe sync complete."
  end
end
