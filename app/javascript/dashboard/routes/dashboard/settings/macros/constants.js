export const MACRO_ACTION_TYPES = [
  {
    key: 'assign_team',
    label: 'Atribuir a uma Equipe',
    inputType: 'search_select',
  },
  {
    key: 'assign_agent',
    label: 'Atribuir a um Agente',
    inputType: 'search_select',
  },
  {
    key: 'add_label',
    label: 'Adicionar um Rotulo',
    inputType: 'multi_select',
  },
  {
    key: 'remove_label',
    label: 'Remover um Rotulo',
    inputType: 'multi_select',
  },
  {
    key: 'remove_assigned_team',
    label: 'Remover a Equipe Atribuida',
    inputType: null,
  },
  {
    key: 'send_email_transcript',
    label: 'Enviar uma Conversa por Email',
    inputType: 'email',
  },
  {
    key: 'mute_conversation',
    label: 'Mutar Conversa',
    inputType: null,
  },
  {
    key: 'snooze_conversation',
    label: 'Adiar Conversa',
    inputType: null,
  },
  {
    key: 'resolve_conversation',
    label: 'Resolver Conversa',
    inputType: null,
  },
  {
    key: 'send_attachment',
    label: 'Enviar Anexo: Audio, Imagem, Video ou Contato',
    inputType: 'attachment',
  },
  {
    key: 'send_message',
    label: 'Enviar Mensagem em Texto',
    inputType: 'textarea',
  },
  {
    key: 'add_private_note',
    label: 'Adicionar uma Nota Privada',
    inputType: 'textarea',
  },
  {
    key: 'change_priority',
    label: 'Alterar Prioridade',
    inputType: 'search_select',
  },
];
