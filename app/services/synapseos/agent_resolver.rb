module Synapseos
  # Resolves between AgentBot records (native Chatwoot) and canonical SynapseOS
  # agent slugs used across the C-Level dashboard KPIs. Alice & Iza share the
  # same card (`alice_iza`).
  class AgentResolver
    NAME_TO_SLUG = {
      'Alice' => 'alice_iza',
      'Iza' => 'alice_iza',
      'Otto' => 'otto',
      'Luís' => 'luis',
      'Luis' => 'luis',
      'Fernanda' => 'fernanda',
      'Ângela' => 'angela',
      'Angela' => 'angela',
      'Vitor' => 'vitor'
    }.freeze

    DISPLAY_NAMES = {
      'alice_iza' => 'Alice & Iza',
      'otto' => 'Otto',
      'luis' => 'Luís',
      'fernanda' => 'Fernanda',
      'angela' => 'Ângela',
      'vitor' => 'Vitor'
    }.freeze

    SLUGS = DISPLAY_NAMES.keys.freeze

    def self.slug_for(agent_bot)
      return nil if agent_bot.nil?

      NAME_TO_SLUG[agent_bot.name]
    end

    def self.display_name(slug)
      DISPLAY_NAMES[slug.to_s]
    end

    def self.bots_for_slug(account, slug)
      names = NAME_TO_SLUG.select { |_, s| s == slug.to_s }.keys
      AgentBot.where(account_id: [nil, account.id], name: names)
    end

    def self.all_bots(account)
      AgentBot.where(account_id: [nil, account.id], name: NAME_TO_SLUG.keys)
    end
  end
end
