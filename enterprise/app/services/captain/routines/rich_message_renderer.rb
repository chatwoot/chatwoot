class Captain::Routines::RichMessageRenderer
  def self.render(content)
    return content unless content.is_a?(Hash) && content['type'] == 'rich_message'

    mentions = content.fetch('mentions')
    content.fetch('segments').map do |segment|
      segment.fetch('type') == 'text' ? segment.fetch('text') : render_mention(mentions.fetch(segment.fetch('mention')))
    end.join
  end

  def self.render_mention(agent)
    id = agent.fetch('id')
    name = agent.fetch('name')
    "[@#{name}](mention://user/#{id}/#{ERB::Util.url_encode(name)})"
  end
  private_class_method :render_mention
end
