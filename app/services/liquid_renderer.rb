class LiquidRenderer
  def initialize(content, context = {})
    @content = content
    @context = context
  end

  def render
    template = Liquid::Template.parse(modified_content)
    template.render(context)
  rescue Liquid::Error => e
    Rails.logger.error("Liquid error: #{e.message}")
    @content # Fallback to original content
  end

  private

  def modified_content
    # Protect content inside backticks from being processed
    @content.gsub(/`(.*?)`/m, '{% raw %}`\1`{% endraw %}')
  end

  attr_reader :context
end
