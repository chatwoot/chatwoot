# CUSTOMIZAÇÃO_SYNAPSEOS
# Completa o payload do relatório mensal com as 2 seções que só o Chatwoot sabe
# (o painel/data lake não tem): 1ª-msg-vs-follow-up e leads por estágio de pipeline.
# Chamado no create do relatório (o n8n manda o resto vindo do painel).
module Synapseos
  class MonthlyReportEnricher
    GAP = 2 * 3600 # 2h: colapsa a abertura multi-msg; follow-ups (dias) = toque novo

    def initialize(account, period)
      @account = account
      @period = period.to_s
    end

    # { efetividade: {resp_primeira, resp_apos}, pipeline_status: [{estagio, n}] }
    def call
      { efetividade: first_vs_followup, pipeline_status: pipeline_status }
    end

    private

    def month_range
      year, month = @period.split('-').map(&:to_i)
      zone = ActiveSupport::TimeZone['America/Sao_Paulo']
      start = zone.local(year, month, 1)
      [start, start.next_month]
    end

    def incoming?(type)
      type == 0 || type == 'incoming'
    end

    def first_vs_followup
      js, je = month_range
      first = 0
      after = 0
      @account.conversations.where(created_at: js...je).find_each do |conv|
        rows = conv.messages.where(message_type: %i[incoming outgoing template])
                            .order(:created_at).pluck(:message_type, :created_at)
        next if rows.empty?

        first_in = rows.find { |t, _| incoming?(t) }&.last
        next if first_in.nil?

        outs = rows.select { |t, at| !incoming?(t) && at < first_in }.map(&:last)
        next if outs.empty?

        touches = 1
        outs.each_cons(2) { |a, b| touches += 1 if (b - a) > GAP }
        touches <= 1 ? (first += 1) : (after += 1)
      end

      base = first + after
      { resp_primeira: pct(first, base), resp_apos: pct(after, base) }
    end

    def pipeline_status
      ::Synapseos::PipelineStage.where(account_id: @account.id).order(:position).map do |stage|
        { estagio: stage.name, n: stage.leads.count }
      end
    end

    # Percentual no formato brasileiro (ex.: "87,5"); "0" se base vazia.
    def pct(num, base)
      return '0' if base.to_i.zero?

      format('%.1f', (100.0 * num / base)).tr('.', ',')
    end
  end
end
