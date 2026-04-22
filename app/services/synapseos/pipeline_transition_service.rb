module Synapseos
  # Move um card de pipeline (Synapseos::Lead — guarda `pipeline_stage_id`) para o
  # stage com o slug informado. Dispara webhooks para o orquestrador (N8N) e
  # emite um evento wisper `deal.stage_changed` para listeners em cadeia.
  #
  # NB: O contrato externo se refere a "deal"; no schema atual o
  # `pipeline_stage_id` vive em `Synapseos::Lead`. Mantemos `deal:` como
  # parâmetro público por compatibilidade com o contrato.
  class PipelineTransitionService
    def self.move(deal:, to_slug:, reason: nil)
      new(deal, to_slug, reason).call
    end

    def initialize(deal, to_slug, reason)
      @deal = deal
      @to_slug = to_slug.to_s
      @reason = reason
    end

    def call
      target = ::Synapseos::PipelineStage.find_by!(account_id: @deal.account_id, slug: @to_slug)
      previous = @deal.pipeline_stage
      return target if previous&.id == target.id

      @deal.update!(pipeline_stage_id: target.id)

      dispatch_webhook(target)
      broadcast_stage_changed(previous, target)
      target
    end

    private

    def dispatch_webhook(target)
      case target.slug
      when 'fechado_ganho' then dispatch_won
      when 'perdido' then dispatch_lost
      end
    end

    def dispatch_won
      deal_record = latest_deal
      ::Synapseos::WebhookDeliveryJob.perform_later(
        ENV.fetch('N8N_WEBHOOK_ANGELA_URL', nil),
        {
          account_id: @deal.account_id,
          conversation_id: @deal.conversation_id,
          contact_id: @deal.contact_id,
          deal_id: deal_record&.id,
          amount_cents: amount_cents(deal_record),
          event: 'deal_won'
        }
      )
    end

    def dispatch_lost
      deal_record = latest_deal
      ::Synapseos::WebhookDeliveryJob.perform_later(
        ENV.fetch('N8N_WEBHOOK_FERNANDA_URL', nil),
        {
          account_id: @deal.account_id,
          conversation_id: @deal.conversation_id,
          contact_id: @deal.contact_id,
          deal_id: deal_record&.id,
          event: 'deal_lost',
          reason: @reason
        }
      )
    end

    def latest_deal
      @deal.deals.order(:created_at).last
    end

    def amount_cents(deal_record)
      return 0 if deal_record.nil?

      (deal_record.amount * 100).to_i
    end

    def broadcast_stage_changed(previous, target)
      Rails.configuration.dispatcher.dispatch(
        'deal.stage_changed',
        Time.zone.now,
        deal: @deal,
        previous_stage: previous,
        current_stage: target,
        reason: @reason
      )
    end
  end
end
