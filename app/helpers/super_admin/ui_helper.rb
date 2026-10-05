# Tailwind class sets shared by the super admin views, so templates stay on utilities
# without repeating them. Tailwind scans this file: every class must be a literal here.
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
  FLASH = 'rounded-lg border px-3.5 py-2.5 text-body-main [&_a]:underline'.freeze

  CLASSES = {
    container: 'mx-auto w-full max-w-[120rem] px-[clamp(1rem,3vw,3rem)]',
    title: 'font-interDisplay text-[1.75rem] font-semibold leading-9 tracking-tight text-n-slate-12',
    overline: 'text-overline text-n-slate-10',
    card: 'rounded-xl border border-n-weak bg-n-solid-1',
    button: "#{BUTTON} border-transparent bg-n-brand text-white hover:bg-n-blue-10",
    button_secondary: "#{BUTTON} border-n-slate-6 bg-n-solid-1 text-n-slate-12 hover:bg-n-slate-3",
    button_danger: "#{BUTTON} border-n-ruby-6 bg-n-solid-1 text-n-ruby-11 hover:bg-n-ruby-3",
    icon_button: 'grid size-8 shrink-0 place-items-center rounded-md text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12 touch:size-10',
    input: INPUT,
    select: "#{INPUT} appearance-none bg-chevron pe-9",
    checkbox: 'size-4 shrink-0 cursor-pointer accent-n-brand disabled:cursor-not-allowed touch:size-5',
    chip: %w[
      inline-flex h-8 shrink-0 cursor-pointer items-center gap-1.5 rounded-full border border-n-weak px-3 text-body-main text-n-slate-11
      hover:bg-n-alpha-2 hover:text-n-slate-12 aria-[current=true]:border-n-blue-7 aria-[current=true]:bg-n-blue-3
      aria-[current=true]:text-n-blue-11 aria-pressed:border-n-blue-7 aria-pressed:bg-n-blue-3 aria-pressed:text-n-blue-11 touch:h-10
    ].join(' '),
    nav_item: %w[
      flex min-h-9 items-center gap-2.5 rounded-lg px-2.5 text-body-main text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12
      aria-[current=page]:bg-n-alpha-2 aria-[current=page]:font-medium aria-[current=page]:text-n-slate-12 touch:min-h-11
    ].join(' '),
    icon_tile: 'grid size-9 shrink-0 place-items-center rounded-lg',
    logo_tile: 'grid size-9 shrink-0 place-items-center rounded-lg border border-n-weak bg-white text-n-brand dark:bg-n-solid-3 dark:text-n-blue-11',
    table: %w[
      w-full border-collapse text-start text-body-main text-n-slate-12
      [&_th]:whitespace-nowrap [&_th]:border-b [&_th]:border-n-weak [&_th]:bg-n-slate-2 [&_th]:px-3 [&_th]:py-2.5 [&_th]:text-start
      [&_th]:text-overline [&_th]:text-n-slate-10 dark:[&_th]:bg-n-solid-3 [&_th:first-child]:ps-4 [&_th:last-child]:pe-4
      [&_td]:border-b [&_td]:border-n-weak [&_td]:px-3 [&_td]:py-3 touch:[&_td]:py-3.5 [&_td:first-child]:ps-4 [&_td:last-child]:pe-4
      [&_tbody_tr:last-child_td]:border-b-0 [&_td_a:not([class])]:text-n-blue-11 hover:[&_td_a:not([class])]:underline
    ].join(' '),
    badge: "#{BADGE} border-n-slate-6 bg-n-slate-3 text-n-slate-11",
    badge_success: "#{BADGE} #{DOT} border-n-teal-6 bg-n-teal-3 text-n-teal-11",
    badge_danger: "#{BADGE} #{DOT} border-n-ruby-6 bg-n-ruby-3 text-n-ruby-11",
    badge_warning: "#{BADGE} #{DOT} border-n-amber-6 bg-n-amber-3 text-n-amber-11",
    badge_info: "#{BADGE} border-n-blue-6 bg-n-blue-3 text-n-blue-11",
    badge_accent: "#{BADGE} border-n-violet-6 bg-n-violet-3 text-n-violet-11",
    flash_notice: "#{FLASH} border-n-blue-6 bg-n-blue-2 text-n-blue-12",
    flash_success: "#{FLASH} border-n-teal-6 bg-n-teal-2 text-n-teal-12",
    flash_alert: "#{FLASH} border-n-amber-6 bg-n-amber-2 text-n-amber-12",
    flash_error: "#{FLASH} border-n-ruby-6 bg-n-ruby-2 text-n-ruby-12"
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

  def ui_flash(type)
    CLASSES.fetch(:"flash_#{type}", CLASSES[:flash_notice])
  end
end
