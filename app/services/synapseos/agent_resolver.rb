# Resolves between AgentBot records (Chatwoot core) and canonical SynapseOS
# agent slugs used by the C-Level dashboard.
#
# Priority: AgentBot#squadron_role (explicit classification) → fallback by
# name (legacy bots created before the field). Alice e Iza são papéis
# separados (Prospecção/BDR outbound vs Recepção/SDR inbound).
class Synapseos::AgentResolver
  # Papel -> label curto (1 palavra) exibido como tag no painel.
  # Natália é o template SDR base do ecossistema (Royal Enfield + Audi rodam
  # nele); aparece como 8º slug no AgentMetrics pra mostrar bots de vendas
  # consultivas que não se encaixam nos 7 papéis especializados.
  DISPLAY_NAMES = {
    'natalia' => 'Natália',
    'alice' => 'Alice',
    'iza' => 'Iza',
    'luis' => 'Luís',
    'otto' => 'Otto',
    'fernanda' => 'Fernanda',
    'angela' => 'Ângela',
    'vitor' => 'Vitor'
  }.freeze

  ROLE_LABELS = {
    'natalia' => 'Vendas',
    'alice' => 'Prospecção',
    'iza' => 'Recepção',
    'luis' => 'Especialista',
    'otto' => 'Auditoria',
    'fernanda' => 'Resgate',
    'angela' => 'Farming',
    'vitor' => 'Recuperação'
  }.freeze

  SLUGS = DISPLAY_NAMES.keys.freeze

  # Fallback: mapeia nomes que bots legados usam (sem squadron_role) pro slug
  # canônico. 'Alice & Iza' legado mapeia pra 'iza' (recepção inbound, caso
  # mais comum em base de dados existente); se o cliente usava o nome
  # combinado, ele reclassifica explicitamente depois.
  NAME_TO_SLUG = {
    'Natália' => 'natalia',
    'Natalia' => 'natalia',
    'Alice' => 'alice',
    'Iza' => 'iza',
    'Alice & Iza' => 'iza',
    'Luís' => 'luis',
    'Luis' => 'luis',
    'Otto' => 'otto',
    'Fernanda' => 'fernanda',
    'Ângela' => 'angela',
    'Angela' => 'angela',
    'Vitor' => 'vitor'
  }.freeze

  def self.slug_for(agent_bot)
    return nil if agent_bot.nil?

    agent_bot.squadron_role.presence || NAME_TO_SLUG[agent_bot.name]
  end

  def self.display_name(slug)
    DISPLAY_NAMES[slug.to_s]
  end

  def self.role_label(slug)
    ROLE_LABELS[slug.to_s]
  end

  def self.bots_for_slug(account, slug)
    slug = slug.to_s
    legacy_names = NAME_TO_SLUG.select { |_, s| s == slug }.keys

    AgentBot.where(account_id: [nil, account.id]).where(
      'squadron_role = :slug OR (squadron_role IS NULL AND name IN (:names))',
      slug: slug, names: legacy_names
    )
  end

  def self.all_bots(account)
    AgentBot.where(account_id: [nil, account.id])
            .where('squadron_role IS NOT NULL OR name IN (:names)', names: NAME_TO_SLUG.keys)
  end
end
