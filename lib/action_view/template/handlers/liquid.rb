# Code inspired by
# http://royvandermeij.com/blog/2011/09/21/create-a-liquid-handler-for-rails-3-dot-1/
# https://github.com/chamnap/liquid-rails/blob/master/lib/liquid-rails/template_handler.rb

class ActionView::Template::Handlers::Liquid
  def self.call(template, _source)
    "ActionView::Template::Handlers::Liquid.new(self).render(#{template.source.inspect}, local_assigns)"
  end

  def initialize(view)
    @view       = view
    @controller = @view.controller
    @helper     = ActionController::Base.helpers
  end

  def render(template, local_assigns = {})
    assigns = drops
    assigns['content_for_layout'] = @view.content_for(:layout) if @view.content_for?(:layout)
    assigns.merge!(local_assigns)
    assigns.merge!(locals)

    liquid = Liquid::Template.parse(template)
    liquid.send(render_method, assigns.stringify_keys, filters: filters, registers: registers.stringify_keys)
  end

  def locals
    if @controller.respond_to?(:liquid_locals, true)
      @controller.send(:liquid_locals)
    else
      {}
    end
  end

  def drops
    droppables = @controller.send(:liquid_droppables) if @controller.respond_to?(:liquid_droppables, true)
    droppables.update(droppables) { |_, obj| obj.try(:to_drop) || nil }
  end

  def filters
    if @controller.respond_to?(:liquid_filters, true)
      @controller.send(:liquid_filters)
    else
      []
    end
  end

  def registers
    if @controller.respond_to?(:liquid_registers, true)
      @controller.send(:liquid_registers)
    else
      {}
    end
  end

  def compilable?
    false
  end

  def render_method
    ::Rails.env.development? || ::Rails.env.test? ? :render! : :render
  end
end
