module SuperAdmin::DebugCenterHelper
  def entry_badge_class(entry)
    case entry[:kind]
    when 'llm' then 'bg-purple-100 text-purple-700'
    else 'bg-slate-100 text-slate-600'
    end
  end

  def health_status_class(status)
    case status
    when 'ok' then 'text-emerald-600 font-medium'
    when 'failed' then 'text-red-600 font-medium'
    when 'missing' then 'text-amber-600 font-medium'
    else 'text-slate-600'
    end
  end
end
