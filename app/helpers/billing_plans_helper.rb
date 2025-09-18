module BillingPlansHelper
  def progress_bar_class(percentage)
    case percentage
    when 0..69
      'bg-[rgb(var(--teal-9))]'
    when 70..89
      'bg-[rgb(var(--amber-9))]'
    else
      'bg-[rgb(var(--ruby-9))]'
    end
  end

  def plan_badge_class(plan_name)
    case plan_name
    when 'free'
      'bg-slate-100 text-slate-800'
    when 'starter'
      'bg-blue-100 text-blue-800'
    when 'professional'
      'bg-purple-100 text-purple-800'
    when 'enterprise'
      'bg-amber-100 text-amber-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end
end
