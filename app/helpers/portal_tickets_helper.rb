module PortalTicketsHelper
  STATUS_CATEGORY_CLASSES = {
    'triage' => 'bg-amber-100 text-amber-800 dark:bg-amber-500/20 dark:text-amber-200',
    'in_progress' => 'bg-blue-100 text-blue-800 dark:bg-blue-500/20 dark:text-blue-200',
    'waiting' => 'bg-indigo-100 text-indigo-800 dark:bg-indigo-500/20 dark:text-indigo-200',
    'done' => 'bg-teal-100 text-teal-800 dark:bg-teal-500/20 dark:text-teal-200',
    'closed' => 'bg-slate-100 text-slate-700 dark:bg-slate-700 dark:text-slate-200'
  }.freeze

  # The customer facing ticket entry needs a widget inbox to land submissions in,
  # so a portal without one hides the entry altogether.
  def portal_tickets_enabled?(portal)
    portal.channel_web_widget&.inbox.present? && portal.account.feature_enabled?('tickets')
  end

  def ticket_status_category_classes(status_category)
    STATUS_CATEGORY_CLASSES.fetch(status_category)
  end
end
