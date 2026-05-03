class Whatsapp::TemplateComponentsBuilder
  def build(params)
    components = []
    header = header_component(params)
    components << header if header.present?
    components << build_body_component(params[:body_text])
    components << build_footer_component(params[:footer_text]) if params[:footer_text].present?
    components << build_buttons_component(params[:buttons]) if params[:buttons].present? && params[:buttons].any?
    components
  end

  def inferred_parameter_format(params)
    return 'NAMED' if [params[:header_text], params[:body_text]].any? { |text| extract_variables(text.to_s).any? }

    nil
  end

  private

  def header_component(params)
    return build_media_header_component(params[:header_format], params[:header_handle]) if image_header?(params)
    return build_header_component(params[:header_text]) if params[:header_text].present?

    nil
  end

  def build_header_component(text)
    component = { type: 'HEADER', format: 'TEXT', text: text }
    variables = extract_variables(text)
    component[:example] = { header_text: variables.map { |v| example_for(v) } } if variables.any?
    component
  end

  def build_media_header_component(format, header_handle)
    {
      type: 'HEADER',
      format: format.to_s.upcase,
      example: { header_handle: [header_handle] }
    }
  end

  def build_body_component(text)
    component = { type: 'BODY', text: text }
    variables = extract_variables(text)
    component[:example] = build_named_body_examples(variables) if variables.any?
    component
  end

  def build_named_body_examples(variables)
    {
      body_text_named_params: variables.map do |variable|
        { param_name: variable, example: example_for(variable) }
      end
    }
  end

  def build_footer_component(text)
    { type: 'FOOTER', text: text }
  end

  def build_buttons_component(buttons)
    {
      type: 'BUTTONS',
      buttons: buttons.map { |btn| { type: btn[:type] || 'QUICK_REPLY', text: btn[:text] } }
    }
  end

  def image_header?(params)
    params[:header_format].to_s.upcase == 'IMAGE'
  end

  def extract_variables(text)
    text.scan(/\{\{([a-zA-Z_][a-zA-Z0-9_]*)\}\}/).flatten
  end

  def example_for(variable_name)
    Whatsapp::TemplateVariableExamples.fetch(variable_name) || "exemplo_#{variable_name}"
  end
end
