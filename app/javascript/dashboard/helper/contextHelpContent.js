export const HELP_CONTENT = {
  dashboard: {
    title: 'Como acompanhar o dashboard',
    body: 'Acompanhe volume de conversas, tempo de resposta e produtividade para identificar gargalos rapidamente.',
  },
  inbox: {
    title: 'Como operar a inbox',
    body: 'Use filtros de status e prioridade para organizar sua fila e responder primeiro os atendimentos mais críticos.',
  },
  conversations: {
    title: 'Como operar uma conversa',
    body: 'Use etiquetas, atribua atendentes e registre notas internas durante o atendimento.',
  },
  contacts: {
    title: 'Como gerenciar contatos',
    body: 'Centralize dados de perfil, histórico e etiquetas para acelerar o atendimento e personalizar respostas.',
  },
  contacts_create: {
    title: 'Como cadastrar um contato',
    body: '1. Acesse o menu Contatos\n2. Clique em Novo contato\n3. Preencha nome, telefone ou e-mail\n4. Adicione etiquetas se necessário\n5. Salve o cadastro\n\nApós salvar, o contato aparecerá na busca e poderá ser usado nas conversas.',
  },
  tags: {
    title: 'Como usar etiquetas',
    body: 'Crie etiquetas padronizadas para classificar assuntos e facilitar filtros, automações e relatórios.',
  },
  internal_notes: {
    title: 'Como usar notas internas',
    body: 'Registre contexto interno e próximos passos sem expor o conteúdo para o cliente.',
  },
  assign_conversation: {
    title: 'Como atribuir uma conversa',
    body: 'Atribua a conversa para um responsável para garantir ownership e evitar atendimentos duplicados.',
  },
  automations: {
    title: 'Como usar automações',
    body: 'Configure regras com gatilhos e ações para reduzir trabalho manual e manter consistência operacional.',
  },
  integrations: {
    title: 'Como usar integrações',
    body: 'Conecte canais e ferramentas externas para centralizar dados e ampliar o fluxo de atendimento.',
  },
  reports: {
    title: 'Como analisar relatórios',
    body: 'Compare métricas por período, equipe e canal para descobrir padrões e melhorar resultados.',
  },
  user_management: {
    title: 'Como gerenciar usuários',
    body: 'Organize permissões por função e mantenha acessos atualizados para segurança e governança.',
  },
  search_filters: {
    title: 'Como usar filtros de busca',
    body: 'Combine filtros por contato, etiqueta, canal e data para localizar conversas específicas com rapidez.',
  },
};

export const getContextHelpByKey = key => HELP_CONTENT[key];
