namespace :saas do
  desc 'Seed default SaaS plans (monthly + annual with 20% off)'
  task seed_plans: :environment do
    # Deactivate old plans that no longer exist
    old_names = %w[Free Starter Pro]
    Saas::Plan.where(name: old_names).update_all(active: false)
    puts "Deactivated legacy plans: #{old_names.join(', ')}"

    monthly_plans = [
      {
        name: 'Essencial',
        price_cents: 38_990,
        interval: 'month',
        agent_limit: 5,
        inbox_limit: 5,
        ai_tokens_monthly: 100_000,
        features: {
          basic_reports: true,
          editor_ai: true,
          audio_transcription: true,
          label_suggestion: true,
          webhooks: 1,
          automations: 5,
          macros: 10
        },
        active: true
      },
      {
        name: 'Profissional',
        price_cents: 78_990,
        interval: 'month',
        agent_limit: 15,
        inbox_limit: 20,
        ai_tokens_monthly: 500_000,
        features: {
          basic_reports: true, advanced_reports: true,
          editor_ai: true, copilot: true, assistant: true,
          summary: true, follow_up: true,
          audio_transcription: true, label_suggestion: true,
          ai_agents: true, ai_agents_limit: 1,
          knowledge_bases: 1, knowledge_docs: 50,
          agent_tools: 3,
          help_center: true, help_center_portals: 1, help_center_articles: 50,
          automations: 25, macros: 50, agent_bots: 2,
          campaigns: true, csv_export: true,
          webhooks: 5, ip_lookup: true,
          assignment_policies: true
        },
        active: true
      },
      {
        name: 'Business',
        price_cents: 128_990,
        interval: 'month',
        agent_limit: 40,
        inbox_limit: 60,
        ai_tokens_monthly: 2_000_000,
        features: {
          basic_reports: true, advanced_reports: true, full_reports: true,
          editor_ai: true, copilot: true, assistant: true,
          summary: true, follow_up: true, csat_analysis: true, captain_tasks: true,
          audio_transcription: true, label_suggestion: true,
          ai_agents: true, ai_agents_limit: 5,
          voice_agents: true, voice_agents_limit: 2, voice_minutes: 60,
          knowledge_bases: 10, knowledge_docs: 500,
          agent_tools: 20, workflows: true,
          help_center: true, help_center_portals: 3, help_center_articles: 500,
          help_center_embedding_search: true,
          automations: 100, macros: 200, agent_bots: 10,
          campaigns: true, whatsapp_campaigns: true, csv_export: true,
          sla: true, sla_policies: 3, audit_logs: true,
          custom_reply_email: true,
          webhooks: 20, ip_lookup: true,
          assignment_policies: true, advanced_assignment: true,
          advanced_search: true
        },
        active: true
      },
      {
        name: 'Enterprise',
        price_cents: 248_990,
        interval: 'month',
        agent_limit: 100,
        inbox_limit: 200,
        ai_tokens_monthly: 10_000_000,
        features: {
          basic_reports: true, advanced_reports: true, full_reports: true,
          editor_ai: true, copilot: true, assistant: true,
          summary: true, follow_up: true, csat_analysis: true, captain_tasks: true,
          audio_transcription: true, label_suggestion: true,
          ai_agents: true, ai_agents_limit: -1,
          voice_agents: true, voice_agents_limit: -1, voice_minutes: 300,
          knowledge_bases: -1, knowledge_docs: -1,
          agent_tools: -1, workflows: true,
          help_center: true, help_center_portals: -1, help_center_articles: -1,
          help_center_embedding_search: true,
          automations: -1, macros: -1, agent_bots: -1,
          campaigns: true, whatsapp_campaigns: true, csv_export: true,
          sla: true, sla_policies: -1, audit_logs: true,
          custom_reply_email: true, custom_reply_domain: true,
          disable_branding: true, white_label: true,
          saml_sso: true, custom_roles: true, companies: true,
          webhooks: -1, ip_lookup: true,
          assignment_policies: true, advanced_assignment: true,
          advanced_search: true,
          platform_api: true
        },
        active: true
      }
    ]

    # Seed monthly plans
    monthly_plans.each do |plan_attrs|
      plan = Saas::Plan.find_or_initialize_by(name: plan_attrs[:name], interval: 'month')
      plan.assign_attributes(plan_attrs)
      plan.save!
      puts "  -> #{plan.name}: R$#{(plan.price_cents / 100.0).round(2)}/mês " \
           "(#{plan.agent_limit} agentes, #{plan.inbox_limit} inboxes, " \
           "#{plan.ai_tokens_monthly.to_fs(:delimited)} tokens IA/mês)"
    end

    # Seed annual plans (20% discount)
    monthly_plans.each do |plan_attrs|
      annual_price = (plan_attrs[:price_cents] * 12 * 0.80).round
      annual_attrs = plan_attrs.merge(
        name: "#{plan_attrs[:name]} Anual",
        price_cents: annual_price,
        interval: 'year'
      )

      plan = Saas::Plan.find_or_initialize_by(name: annual_attrs[:name], interval: 'year')
      plan.assign_attributes(annual_attrs)
      plan.save!
      monthly_equivalent = (annual_price / 12.0 / 100.0).round(2)
      puts "  -> #{plan.name}: R$#{(plan.price_cents / 100.0).round(2)}/ano " \
           "(~R$#{monthly_equivalent}/mês, 20% off)"
    end

    puts "\nSeeded #{monthly_plans.size * 2} plans (#{monthly_plans.size} monthly + #{monthly_plans.size} annual)."
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

      # Group monthly and annual under the same Stripe product
      base_name = plan.name.delete_suffix(' Anual')
      existing_product = Saas::Plan.active.find_by(name: base_name, interval: 'month')
      product_id = existing_product&.stripe_product_id

      if product_id.blank?
        product = Stripe::Product.create(
          name: "AirysChat #{base_name}",
          description: "#{plan.agent_limit} agentes, #{plan.inbox_limit} inboxes, " \
                       "#{plan.ai_tokens_monthly.to_fs(:delimited)} tokens IA/mês",
          metadata: { plan_name: base_name }
        )
        product_id = product.id
      end

      price = Stripe::Price.create(
        product: product_id,
        unit_amount: plan.price_cents,
        currency: 'brl',
        recurring: { interval: plan.interval }
      )

      plan.update!(stripe_product_id: product_id, stripe_price_id: price.id)
      puts "  [synced] #{plan.name} (#{plan.interval}): product=#{product_id} price=#{price.id}"
    end

    puts "\nStripe sync complete."
  end
end
