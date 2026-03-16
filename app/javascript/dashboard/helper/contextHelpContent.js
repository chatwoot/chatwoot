export const HELP_CONTENT = {
  dashboard: {
    title: 'Como acompanhar o dashboard',
    body: 'Monitore volume, tempo de resposta e produtividade para identificar gargalos e priorizar ações operacionais.',
  },
  inbox: {
    title: 'Como operar a inbox',
    body: 'Use filtros por status, prioridade e responsável para atender primeiro os casos críticos e evitar fila parada.',
  },
  conversations: {
    title: 'Como operar uma conversa',
    body: 'Responda, aplique etiquetas, registre notas internas e resolva a conversa apenas quando houver próximo passo claro.',
  },
  contacts: {
    title: 'Como gerenciar contatos',
    body: 'Mantenha telefone/e-mail atualizados, histórico organizado e etiquetas corretas para acelerar o atendimento.',
  },
  contacts_create: {
    title: 'Como cadastrar um contato',
    body: '1. Acesse Contatos\n2. Clique em Novo contato\n3. Preencha nome + telefone ou e-mail\n4. Adicione etiquetas\n5. Salve\n\nDepois disso, o contato já pode ser usado em conversas e automações.',
  },
  tags: {
    title: 'Como usar etiquetas',
    body: 'Padronize etiquetas por tema (ex.: financeiro, cancelamento, comercial) para facilitar busca, relatório e automação.',
  },
  internal_notes: {
    title: 'Como usar notas internas',
    body: 'Registre contexto de handoff, pendências e próximos passos. Notas internas não aparecem para o cliente.',
  },
  assign_conversation: {
    title: 'Como atribuir conversa',
    body: 'Atribua um responsável para evitar conflito entre agentes e garantir ownership até a resolução.',
  },
  automations: {
    title: 'Como usar automações',
    body: 'Configure gatilho + condição + ação. Sempre valide logs para garantir que a regra não está disparando em loop.',
  },
  integrations: {
    title: 'Como usar integrações',
    body: 'Conecte canais e sistemas externos para centralizar atendimento. Em falhas, confira autenticação e logs da integração.',
  },
  reports: {
    title: 'Como analisar relatórios',
    body: 'Compare períodos, filas e agentes para entender SLA, produtividade e gargalos operacionais.',
  },
  user_management: {
    title: 'Como gerenciar usuários e permissões',
    body: 'Defina função por perfil (operador, supervisor, admin) e revise permissões para evitar acesso indevido.',
  },
  search_filters: {
    title: 'Como usar busca e filtros',
    body: 'Combine filtros por contato, etiqueta, canal e data para achar rapidamente casos específicos.',
  },
  companies: {
    title: 'Como usar empresas',
    body: 'Relacione contatos à empresa para visualizar histórico consolidado e facilitar gestão B2B.',
  },
  campaigns: {
    title: 'Como usar campanhas',
    body: 'Escolha canal, público e objetivo da campanha. Valide amostra pequena antes de envio em massa.',
  },
  help_center: {
    title: 'Como usar a central de ajuda',
    body: 'Publique artigos e categorias para autoatendimento. Mantenha conteúdo atualizado para reduzir tickets repetitivos.',
  },
  settings: {
    title: 'Como usar configurações',
    body: 'Ajuste inboxes, equipes, automações, integrações e segurança. Faça mudanças críticas de forma controlada.',
  },
  captain: {
    title: 'Como usar o Captain',
    body: 'Organize base de conhecimento (FAQs, documentos e cenários) para melhorar respostas assistidas por IA.',
  },
};

export const getContextHelpByKey = key => HELP_CONTENT[key];

export const getAllContextHelp = () =>
  Object.entries(HELP_CONTENT).map(([key, value]) => ({
    key,
    ...value,
  }));
