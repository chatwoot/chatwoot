module BillingPlansHelper
  def progress_bar_class(percentage)
    case percentage
    when 0..60
      'bg-success'
    when 61..80
      'bg-warning'
    else
      'bg-danger'
    end
  end

  def plan_badge_class(plan_name)
    case plan_name
    when 'free'
      'free'
    when 'starter'
      'starter'
    when 'professional'
      'professional'
    when 'enterprise'
      'enterprise'
    else
      'secondary'
    end
  end
end
