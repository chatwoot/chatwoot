module MessageTemplates::Template::ContentParser
  def parse_message_content(content)
    if content.present? && content.match?(/.*{{.*}}.*/)
      template = Liquid::Template.parse(content)
      template_values = parse_template_variable(template, content)
      content = template.render(template_values)
    end

    content
  end

  def parse_template_variable(template, _content)
    template_values = {}
    template.root.body.nodelist.each do |node|
      next if node.try(:name).blank?

      #  liquid node looks like this @name=#<Liquid::VariableLookup:0x0000000116df6be8 @lookups=["name"], @name="contact">,
      association = node.name.name
      attribute = node.name.lookups[0]
      template_values[association] = { attribute => parse_tempalte_variable_values(association, attribute) }
    end
    template_values
  end

  def parse_tempalte_variable_values(association, attribute)
    return if association.blank? || attribute.blank?

    record = conversation.send(association)
    record.try(attribute)
  end
end
