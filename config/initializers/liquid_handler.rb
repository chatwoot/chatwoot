require Rails.root.join('lib/action_view/template/handlers/liquid')
require Rails.root.join('lib/liquid_i18n')

ActionView::Template.register_template_handler :liquid, ActionView::Template::Handlers::Liquid
Liquid::Template.register_filter LiquidI18n
