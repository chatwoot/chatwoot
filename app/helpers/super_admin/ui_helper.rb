# Tailwind class sets for the tags Rails helpers build (form fields, buttons, links) and for badges,
# so templates do not repeat them. Everything else is a partial or is written out in the template.
# Tailwind scans this file: every class must be a literal here.
module SuperAdmin::UiHelper
  BUTTON = %w[
    inline-flex h-9 shrink-0 cursor-pointer select-none items-center justify-center gap-1.5 whitespace-nowrap rounded-lg border px-3.5
    text-button transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2
    focus-visible:outline-n-brand disabled:cursor-not-allowed disabled:opacity-50 touch:h-11
  ].join(' ').freeze

  INPUT = %w[
    block min-h-9 w-full rounded-lg border border-n-slate-6 bg-n-solid-1 px-3 py-1.5 text-body-main text-n-slate-12 outline-none
    transition-colors placeholder:text-n-slate-10 hover:border-n-slate-8 focus:border-n-brand focus:ring-2 focus:ring-n-brand/25
    disabled:cursor-not-allowed disabled:bg-n-slate-3 disabled:text-n-slate-10 touch:min-h-11 touch:text-base
  ].join(' ').freeze

  BADGE = 'inline-flex h-5 items-center gap-1 whitespace-nowrap rounded-md border px-1.5 text-label-small'.freeze
  DOT = "before:size-1.5 before:rounded-full before:bg-current before:content-['']".freeze

  CLASSES = {
    button: "#{BUTTON} border-transparent bg-n-brand text-white hover:bg-n-blue-10",
    button_secondary: "#{BUTTON} border-n-slate-6 bg-n-solid-1 text-n-slate-12 hover:bg-n-slate-3",
    button_danger: "#{BUTTON} border-n-ruby-6 bg-n-solid-1 text-n-ruby-11 hover:bg-n-ruby-3",
    icon_button: 'grid size-8 shrink-0 place-items-center rounded-md text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12 touch:size-10',
    input: INPUT,
    select: "#{INPUT} appearance-none bg-chevron pe-9",
    checkbox: 'size-4 shrink-0 cursor-pointer accent-n-brand disabled:cursor-not-allowed touch:size-5',
    badge: "#{BADGE} border-n-slate-6 bg-n-slate-3 text-n-slate-11",
    badge_success: "#{BADGE} #{DOT} border-n-teal-6 bg-n-teal-3 text-n-teal-11",
    badge_danger: "#{BADGE} #{DOT} border-n-ruby-6 bg-n-ruby-3 text-n-ruby-11",
    badge_warning: "#{BADGE} #{DOT} border-n-amber-6 bg-n-amber-3 text-n-amber-11",
    badge_info: "#{BADGE} border-n-blue-6 bg-n-blue-3 text-n-blue-11",
    badge_accent: "#{BADGE} border-n-violet-6 bg-n-violet-3 text-n-violet-11"
  }.freeze

  # Badge tone for the values select fields store (account status, role, user type, banner type).
  VALUE_BADGES = {
    'active' => :badge_success, 'suspended' => :badge_danger, 'error' => :badge_danger, 'warning' => :badge_warning,
    'info' => :badge_info, 'administrator' => :badge_info, 'SuperAdmin' => :badge_accent, 'feature_announcement' => :badge_accent
  }.freeze

  def ui(name)
    CLASSES.fetch(name)
  end

  def ui_value_badge(value)
    ui(VALUE_BADGES.fetch(value.to_s, :badge))
  end
end
