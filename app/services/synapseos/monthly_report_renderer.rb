# CUSTOMIZAÇÃO_SYNAPSEOS
# Renderiza o HTML do relatório mensal a partir do payload (`report.data`) e do
# template ERB versionado em lib/synapseos/monthly_report_template.html.erb.
# O template consome um hash `r` com chaves-símbolo (ver contrato no controller).
require 'erb'

module Synapseos
  class MonthlyReportRenderer
    TEMPLATE_PATH = Rails.root.join('lib', 'synapseos', 'monthly_report_template.html.erb')

    def self.render(report)
      new(report).render
    end

    def initialize(report)
      @report = report
    end

    def render
      template = File.read(TEMPLATE_PATH)
      # trim_mode '<>' é exigido pelo template (linhas de loop `<% %>` não emitem
      # linha em branco) — mantém o HTML byte-idêntico ao design original.
      ERB.new(template, trim_mode: '<>').result_with_hash(r: symbolize(@report.data || {}))
    end

    private

    # Chaves-símbolo em profundidade (o payload chega com chaves-string do JSON).
    def symbolize(obj)
      case obj
      when Hash then obj.each_with_object({}) { |(k, v), h| h[k.to_sym] = symbolize(v) }
      when Array then obj.map { |v| symbolize(v) }
      else obj
      end
    end
  end
end
