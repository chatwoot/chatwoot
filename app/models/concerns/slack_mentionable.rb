# frozen_string_literal: true

module SlackMentionable
  extend ActiveSupport::Concern
  PREFIX_MAPPING = {
    'User' => '',
    'Team' => 'team-',
  }

  def slack_mention
    self.slack_mention_code ? "<@#{self.slack_mention_code}>" : self.name
  end

  def markdown_link
    "[@#{self.name}](mention://user/#{PREFIX_MAPPING[self.model_name.name]}#{self.id}/#{self.name})"
  end
end
