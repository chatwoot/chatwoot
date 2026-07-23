# frozen_string_literal: true

class SeedDefaultSavedReportPanels < ActiveRecord::Migration[7.1]
  # Distinctive names so re-runs and accounts with custom panels stay idempotent.
  DEFAULT_NAMES = [
    'Resumen última semana',
    'Conversaciones por agente',
    'Rendimiento del mes'
  ].freeze

  def up
    return unless table_exists?(:saved_report_panels)

    Account.find_each do |account|
      creator = default_creator_for(account)
      next if creator.blank?

      seed_defaults_for(account, creator)
    end
  end

  def down
    return unless table_exists?(:saved_report_panels)

    SavedReportPanel.where(name: DEFAULT_NAMES).delete_all
  end

  private

  def default_creator_for(account)
    account.administrators.order(:id).first || account.users.order(:id).first
  end

  def seed_defaults_for(account, creator)
    existing = account.saved_report_panels.where(name: DEFAULT_NAMES).pluck(:name)

    default_panels.each do |attrs|
      next if existing.include?(attrs[:name])

      account.saved_report_panels.create!(
        attrs.merge(
          created_by: creator,
          filters: [],
          business_hours: false
        )
      )
    end
  end

  def default_panels
    [
      {
        name: 'Resumen última semana',
        description: 'Vista rápida de conversaciones, resoluciones y tiempos de respuesta.',
        date_preset: 'last_7_days',
        favorite: true,
        widgets: [
          metric_widget('w_default_week_conv', 'Conversaciones', 'conversations_count'),
          metric_widget('w_default_week_res', 'Resoluciones', 'resolutions_count'),
          metric_widget('w_default_week_frt', '1ª respuesta', 'avg_first_response_time'),
          chart_widget('w_default_week_chart', 'Conversaciones por día', 'conversations_count')
        ]
      },
      {
        name: 'Conversaciones por agente',
        description: 'Resumen de carga y rendimiento por agente en los últimos 7 días.',
        date_preset: 'last_7_days',
        favorite: false,
        widgets: [
          metric_widget('w_default_agent_conv', 'Conversaciones', 'conversations_count'),
          metric_widget('w_default_agent_res', 'Resoluciones', 'resolutions_count'),
          metric_widget('w_default_agent_frt', '1ª respuesta', 'avg_first_response_time'),
          metric_widget('w_default_agent_art', 'Resolución', 'avg_resolution_time'),
          table_widget('w_default_agent_table', 'Resumen de agentes', 'agent_summary')
        ]
      },
      {
        name: 'Rendimiento del mes',
        description: 'Métricas del último mes con desglose por bandeja.',
        date_preset: 'last_30_days',
        favorite: false,
        widgets: [
          metric_widget('w_default_month_conv', 'Conversaciones', 'conversations_count'),
          metric_widget('w_default_month_res', 'Resoluciones', 'resolutions_count'),
          metric_widget('w_default_month_art', 'Tiempo de resolución', 'avg_resolution_time'),
          chart_widget('w_default_month_chart', 'Resoluciones por día', 'resolutions_count'),
          table_widget('w_default_month_inbox', 'Resumen de bandejas', 'inbox_summary')
        ]
      }
    ]
  end

  def metric_widget(id, title, metric)
    {
      'id' => id,
      'type' => 'metric',
      'title' => title,
      'metric' => metric,
      'scope_type' => 'account',
      'scope_id' => nil
    }
  end

  def chart_widget(id, title, metric)
    {
      'id' => id,
      'type' => 'chart',
      'title' => title,
      'metric' => metric,
      'scope_type' => 'account',
      'scope_id' => nil,
      'chart_kind' => 'bar',
      'group_by' => 'day'
    }
  end

  def table_widget(id, title, table_kind)
    {
      'id' => id,
      'type' => 'table',
      'title' => title,
      'table_kind' => table_kind
    }
  end
end
