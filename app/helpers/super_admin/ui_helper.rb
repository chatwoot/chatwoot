# Tailwind classes for form controls. Rails builds those tags (`f.text_field`, `select_tag`, `check_box_tag` and so on),
# so the classes are passed to them; everything else is a partial. Tailwind scans this file: every class must be a literal here.
module SuperAdmin::UiHelper
  INPUT = %w[
    block min-h-9 w-full rounded-lg border border-n-slate-6 bg-n-solid-1 px-3 py-1.5 text-body-main text-n-slate-12 outline-none
    transition-colors placeholder:text-n-slate-10 hover:border-n-slate-8 focus:border-n-brand focus:ring-2 focus:ring-n-brand/25
    disabled:cursor-not-allowed disabled:bg-n-slate-3 disabled:text-n-slate-10 touch:min-h-11 touch:text-base
  ].join(' ').freeze

  CLASSES = {
    input: INPUT,
    select: "#{INPUT} appearance-none bg-chevron pe-9",
    checkbox: 'size-4 shrink-0 cursor-pointer accent-n-brand disabled:cursor-not-allowed touch:size-5'
  }.freeze

  def ui(name, extra = nil)
    class_names(CLASSES.fetch(name), extra)
  end
end
