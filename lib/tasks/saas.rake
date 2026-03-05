# frozen_string_literal: true

namespace :saas do
  desc 'Sync SaaS plans with Stripe — creates Products and Prices for plans missing stripe_product_id or stripe_price_id'
  task sync_stripe_plans: :environment do
    require 'stripe'
    abort('STRIPE_SECRET_KEY not set') unless ENV['STRIPE_SECRET_KEY'].present?

    Saas::Plan.active.find_each do |plan|
      puts "Processing: #{plan.name} (#{plan.interval})..."

      # Create Stripe Product if missing
      if plan.stripe_product_id.blank?
        product = Stripe::Product.create(
          name: "AirysChat — #{plan.name}",
          metadata: { plan_id: plan.id, interval: plan.interval }
        )
        plan.update_column(:stripe_product_id, product.id)
        puts "  Created Product: #{product.id}"
      end

      # Create Stripe Price if missing
      if plan.stripe_price_id.blank?
        price = Stripe::Price.create(
          product: plan.stripe_product_id,
          unit_amount: plan.price_cents,
          currency: 'brl',
          recurring: { interval: plan.interval == 'year' ? 'year' : 'month' },
          metadata: { plan_id: plan.id }
        )
        plan.update_column(:stripe_price_id, price.id)
        puts "  Created Price: #{price.id}"
      end

      puts "  Done. product=#{plan.stripe_product_id} price=#{plan.stripe_price_id}"
    end

    puts "\nAll plans synced."
  end

  desc 'Seed the default SaaS plans (idempotent — skips existing plans by name+interval)'
  task seed_plans: :environment do
    plans = [
      { name: 'Essencial', interval: 'month', price_cents: 38_990, agent_limit: 5, inbox_limit: 5, ai_tokens_monthly: 100_000,
        features: { ai_agents: true, ai_agents_limit: 1, workflows: false, help_center: true, help_center_portals: 1 } },
      { name: 'Essencial Anual', interval: 'year', price_cents: 374_304, agent_limit: 5, inbox_limit: 5, ai_tokens_monthly: 100_000,
        features: { ai_agents: true, ai_agents_limit: 1, workflows: false, help_center: true, help_center_portals: 1 } },
      { name: 'Profissional', interval: 'month', price_cents: 78_990, agent_limit: 15, inbox_limit: 20, ai_tokens_monthly: 500_000,
        features: { ai_agents: true, ai_agents_limit: 3, workflows: true, help_center: true, help_center_portals: 3, sla: true } },
      { name: 'Profissional Anual', interval: 'year', price_cents: 758_304, agent_limit: 15, inbox_limit: 20, ai_tokens_monthly: 500_000,
        features: { ai_agents: true, ai_agents_limit: 3, workflows: true, help_center: true, help_center_portals: 3, sla: true } },
      { name: 'Business', interval: 'month', price_cents: 128_990, agent_limit: 40, inbox_limit: 60, ai_tokens_monthly: 2_000_000,
        features: { ai_agents: true, ai_agents_limit: 5, voice_agents: true, voice_minutes: 500, workflows: true,
                    help_center: true, help_center_portals: 5, sla: true, audit_logs: true } },
      { name: 'Business Anual', interval: 'year', price_cents: 1_238_304, agent_limit: 40, inbox_limit: 60, ai_tokens_monthly: 2_000_000,
        features: { ai_agents: true, ai_agents_limit: 5, voice_agents: true, voice_minutes: 500, workflows: true,
                    help_center: true, help_center_portals: 5, sla: true, audit_logs: true } },
      { name: 'Enterprise', interval: 'month', price_cents: 248_990, agent_limit: 100, inbox_limit: 200, ai_tokens_monthly: 10_000_000,
        features: { ai_agents: true, ai_agents_limit: -1, voice_agents: true, voice_minutes: 2000, workflows: true,
                    help_center: true, help_center_portals: -1, sla: true, audit_logs: true,
                    white_label: true, saml_sso: true, custom_roles: true } },
      { name: 'Enterprise Anual', interval: 'year', price_cents: 2_390_304, agent_limit: 100, inbox_limit: 200, ai_tokens_monthly: 10_000_000,
        features: { ai_agents: true, ai_agents_limit: -1, voice_agents: true, voice_minutes: 2000, workflows: true,
                    help_center: true, help_center_portals: -1, sla: true, audit_logs: true,
                    white_label: true, saml_sso: true, custom_roles: true } }
    ]

    plans.each do |attrs|
      plan = Saas::Plan.find_or_initialize_by(name: attrs[:name], interval: attrs[:interval])
      if plan.new_record?
        plan.assign_attributes(attrs)
        plan.save!
        puts "Created: #{plan.name} (#{plan.interval})"
      else
        puts "Skipped (exists): #{plan.name} (#{plan.interval})"
      end
    end

    puts "\nDone. #{Saas::Plan.active.count} active plans."
  end
end
