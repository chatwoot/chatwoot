module Synapseos
  class DashboardSummaryService
    def initialize(account, period_days: 30)
      @account = account
      @period_days = period_days
      @range = period_days.days.ago.beginning_of_day..Time.current
    end

    def call
      {
        period_days: @period_days,
        period_start: @range.first,
        period_end: @range.last,
        kpis: kpis,
        daily: daily_breakdown,
        recent_events: recent_events,
      }
    end

    def recent_events
      # ATIVIDADE RECENTE — somente alertas APROVADOS no Slack
      # (sales_alert_approved), criados pelo webhook de aprovação. Deduplica
      # por conversa (1 por conversa, o mais recente). O NOME vem do
      # metadata['nome'] capturado no momento da aprovação — NÃO da associação
      # conversation (que resolve por id interno e colide com display_id).
      ::Synapseos::CrmEvent
        .where(account_id: @account.id, event_type: 'sales_alert_approved', created_at: @range)
        .order(created_at: :desc)
        .limit(50)
        .group_by { |e| e.conversation_id || "ev-#{e.id}" }
        .map { |_cid, evs| evs.first }
        .sort_by { |e| -e.created_at.to_i }
        .first(10)
        .map do |e|
          meta = e.metadata.is_a?(Hash) ? e.metadata : {}
          {
            id: e.id,
            event_type: e.event_type,
            conversation_id: e.conversation_id,
            contact_name: meta['nome'].presence || '—',
            modelo_interesse: meta['modelo_interesse'] || 'a definir',
            tipo: meta['tipo'],
            metadata: e.metadata,
            created_at: e.created_at,
          }
        end
    end

    private

    def kpis
      # Alertas de venda únicos (conversas distintas) — fonte primária dos
      # KPIs "negócios ganhos" e "receita potencial". Cada conversa que
      # gerou sales_alert_dispatched conta uma vez, mesmo se múltiplos
      # alertas foram disparados.
      sales_alert_events = events_of('sales_alert_dispatched')
      unique_alert_convs = sales_alert_events.distinct.count('conversation_id')

      {
        leads: leads_scope.count,
        # Negócios ganhos = alertas únicos de venda no período. Cada alerta
        # = oportunidade qualificada passada ao time. Cliente quer ver isso
        # como métrica principal (não o legacy `won_deals.count`).
        # Negócios ganhos = leads na coluna "ganho" da pipeline (stage_type
        # 'won', ex: 'venda'). Fonte de verdade do consultor, não os alertas.
        deals_won: won_stage_leads_count,
        # Negócios perdidos = leads que bloquearam contato (recusa explícita).
        # n8n handler cria event lead_blocked quando audi_block_lead dispara.
        deals_lost: events_of('lead_blocked').distinct.count('conversation_id'),
        # Receita potencial = somatório de preco_brl_a_partir armazenado no
        # metadata do sales_alert_dispatched. n8n handler busca preço via
        # audi_knowledge_query e grava no event metadata.
        revenue: sales_alert_revenue(sales_alert_events),
        messages_received: messages.where(message_type: :incoming).count,
        # CUSTOMIZAÇÃO_SYNAPSEOS: "mensagens disparadas" no domínio Synapseos
        # significa "contatos distintos que receberam pelo menos uma outgoing
        # no período" — não a soma bruta de outgoing.
        messages_sent: outgoing_distinct_contacts(@range),
        # DISPAROS NO PERÍODO selecionado (1 por contato distinto que
        # recebeu primeira outgoing). Métrica primária do dashboard.
        # `shoots_month` mantido por backcompat (acumulativo do mês corrente).
        shoots_period: outgoing_distinct_contacts(@range),
        shoots_month: shoots_month_count,
        # ELISA → ATENDIMENTO HUMANO: conversas distintas onde Elisa
        # transferiu pra consultor humano (= alertas únicos disparados).
        # Mesma fonte que `deals_won` (sales_alert_dispatched) e que a lista
        # de "Últimos alertas" — invariante: lista com items ⇒ KPI > 0.
        bot_takeovers: unique_alert_convs,
        # human_rescues mantido por backcompat; frontend não exibe mais.
        human_rescues: events_of('human_rescue').count,
        ai_responses: messages.where(sender_type: 'AgentBot').count,
        appointments: events_of('appointment_confirmed').count,
        conversion_rate: conversion_rate,
      }
    end

    # Soma preco_brl_a_partir do metadata dos sales_alert_dispatched.
    # Pega 1 alerta por conversa (o mais recente) pra evitar dupla contagem.
    # Defensivo contra metadata mal formado (não-numérico, ausente).
    def sales_alert_revenue(scope)
      # Exclui eventos órfãos (conversation_id nulo): não são atribuíveis a
      # uma conversa e o DISTINCT ON colapsaria todos num único grupo nulo,
      # contando 1 preço fantasma. Alinha com `deals_won`/`bot_takeovers`,
      # que usam COUNT(DISTINCT conversation_id) — o qual já ignora nulos.
      latest_per_conv = scope.where.not(conversation_id: nil)
                             .select('DISTINCT ON (conversation_id) conversation_id, metadata, created_at')
                             .order('conversation_id, created_at DESC')
      latest_per_conv.sum do |ev|
        meta = ev.metadata.is_a?(Hash) ? ev.metadata : {}
        price = meta['preco_brl_a_partir'] || meta[:preco_brl_a_partir]
        price.to_f
      end
    rescue StandardError => e
      Rails.logger.warn("[DashboardSummaryService] revenue calc failed: #{e.message}")
      0.0
    end

    def daily_breakdown
      days = (0...@period_days).map { |offset| (@period_days - 1 - offset).days.ago.to_date }
      msgs_in = messages.where(message_type: :incoming).reorder(nil).group("DATE(created_at)").count
      msgs_out_distinct = outgoing_distinct_contacts_by_day
      # Daily takeovers = alertas de venda únicos por dia (mesma fonte do KPI).
      # group por DATE + conversation_id distinto evita dupla contagem se a
      # mesma conv gerou 2 alertas no mesmo dia.
      takeovers = events_of('sales_alert_dispatched')
                    .where.not(conversation_id: nil)
                    .reorder(nil)
                    .group("DATE(created_at)")
                    .distinct
                    .count('conversation_id')
      ai_resp = messages.where(sender_type: 'AgentBot').reorder(nil).group("DATE(created_at)").count

      days.map do |day|
        {
          date: day.iso8601,
          messages_received: msgs_in[day].to_i,
          messages_sent: msgs_out_distinct[day].to_i,
          bot_takeovers: takeovers[day].to_i,
          ai_responses: ai_resp[day].to_i,
        }
      end
    end

    # CUSTOMIZAÇÃO_SYNAPSEOS: count of distinct contacts that received at
    # least one outgoing message inside ``range``. Uses conversation.contact_id
    # because outgoing messages always belong to a conversation.
    def outgoing_distinct_contacts(range)
      ::Message
        .where(account_id: @account.id, created_at: range, message_type: :outgoing)
        .joins(:conversation)
        .distinct
        .count('conversations.contact_id')
    end

    # Daily version — returns { Date => count } using PostgreSQL
    # DATE(messages.created_at) grouping with distinct contact_id per day.
    def outgoing_distinct_contacts_by_day
      ::Message
        .where(account_id: @account.id, created_at: @range, message_type: :outgoing)
        .joins(:conversation)
        .reorder(nil)
        .group(Arel.sql('DATE(messages.created_at)'))
        .distinct
        .count('conversations.contact_id')
    end

    def leads_scope
      ::Synapseos::Lead.where(account_id: @account.id, created_at: @range)
    end

    # Negócios ganhos = leads atualmente em qualquer stage do tipo 'won'
    # (coluna "ganho" da pipeline). Contagem corrente (não filtra período),
    # pois o pipeline é fonte de verdade do estado atual.
    def won_stage_leads_count
      won_ids = ::Synapseos::PipelineStage.where(account_id: @account.id, stage_type: 'won').pluck(:id)
      return 0 if won_ids.empty?

      ::Synapseos::Lead.where(account_id: @account.id, pipeline_stage_id: won_ids).count
    end

    def shoots_month_count
      month_range = Time.current.beginning_of_month..Time.current
      ::Synapseos::Lead.where(account_id: @account.id, created_at: month_range).count
    end

    def deals_scope
      ::Synapseos::Deal.where(account_id: @account.id)
    end

    def won_deals
      deals_scope.where(status: ::Synapseos::Deal.statuses[:won], closed_at: @range)
    end

    def lost_deals
      deals_scope.where(status: ::Synapseos::Deal.statuses[:lost], closed_at: @range)
    end

    def messages
      ::Message.where(account_id: @account.id, created_at: @range)
    end

    def events_of(type)
      ::Synapseos::CrmEvent.where(account_id: @account.id, event_type: type, created_at: @range)
    end

    def conversion_rate
      # Taxa de conversão = alertas únicos / disparos no período. Mede
      # quantos disparos viraram alerta de venda qualificado (handoff
      # pra humano). Diferente da legacy (won_deals/leads) que dependia
      # de pipeline manual que ninguém preenchia.
      total_shoots = outgoing_distinct_contacts(@range)
      return 0.0 if total_shoots.zero?

      unique_alert_convs = events_of('sales_alert_dispatched')
                             .distinct.count('conversation_id')
      ((unique_alert_convs.to_f / total_shoots) * 100).round(2)
    end
  end
end
