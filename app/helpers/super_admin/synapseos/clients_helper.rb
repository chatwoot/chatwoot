# frozen_string_literal: true

module SuperAdmin::Synapseos::ClientsHelper
  STATUS_PILL_BASE = 'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium'
  ACTION_CHIP_BASE = 'inline-flex items-center px-2 py-0.5 rounded text-xs font-medium'

  STATUS_COLORS = {
    'deployed' => 'bg-green-100 text-green-700',
    'success' => 'bg-green-100 text-green-700',
    'not_deployed' => 'bg-slate-100 text-slate-700',
    'partial' => 'bg-yellow-100 text-yellow-700',
    'error' => 'bg-red-100 text-red-700',
    'failure' => 'bg-red-100 text-red-700',
    'available' => 'bg-cyan-100 text-cyan-800',
    'planned' => 'bg-slate-100 text-slate-600'
  }.freeze

  ACTION_COLORS = {
    'deploy' => 'bg-green-50 text-green-700',
    'undeploy' => 'bg-orange-50 text-orange-700',
    'build' => 'bg-cyan-50 text-cyan-700',
    'restore_snapshot' => 'bg-purple-50 text-purple-700',
    'create' => 'bg-blue-50 text-blue-700',
    'delete' => 'bg-red-50 text-red-700'
  }.freeze

  def synapseos_status_pill(status)
    color = STATUS_COLORS[status.to_s] || 'bg-slate-100 text-slate-700'
    "#{STATUS_PILL_BASE} #{color}"
  end

  def synapseos_action_chip(action)
    color = ACTION_COLORS[action.to_s] || 'bg-slate-100 text-slate-700'
    "#{ACTION_CHIP_BASE} #{color}"
  end

  def synapseos_format_snapshot_size(bytes)
    return '—' if bytes.blank?

    units = %w[B KB MB GB]
    size = bytes.to_f
    unit_index = 0
    while size >= 1024 && unit_index < units.length - 1
      size /= 1024
      unit_index += 1
    end
    format('%<size>.1f %<unit>s', size: size, unit: units[unit_index])
  end

  def synapseos_format_snapshot_ts(timestamp)
    return '—' if timestamp.blank?

    Time.zone.parse(timestamp.to_s).utc.strftime('%Y-%m-%d %H:%M:%S UTC')
  rescue ArgumentError, TypeError
    timestamp.to_s
  end
end
