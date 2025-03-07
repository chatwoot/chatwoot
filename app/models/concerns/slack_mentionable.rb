# frozen_string_literal: true

module SlackMentionable
  extend ActiveSupport::Concern
  PREFIX_MAPPING = {
    'User' => '',
    'Team' => 'team-'
  }.freeze

  def slack_mention
    code = slack_mention_code
    if code.to_s.start_with?('U', 'W')
      "<@#{code}>"
    elsif code.to_s.start_with?('S')
      "<!subteam^#{code}>"
    else
      "@#{name}"
    end
  end

  def markdown_link
    "[@#{name}](mention://user/#{PREFIX_MAPPING[model_name.name]}#{id}/#{name})"
  end
end
