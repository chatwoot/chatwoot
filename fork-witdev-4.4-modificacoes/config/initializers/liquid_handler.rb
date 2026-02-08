require Rails.root.join('lib/action_view/template/handlers/liquid')

ActionView::Template.register_template_handler :liquid, ActionView::Template::Handlers::Liquid
