/**
 * Chatwoot Liquid variables available for WhatsApp campaign templates.
 * These variables are resolved at send time using contact/agent/inbox/account data.
 */

export interface ChatwootVariable {
  key: string;
  liquidSyntax: string;
  labelEn: string;
  labelPtBr: string;
  descriptionEn: string;
  descriptionPtBr: string;
  category: 'contact' | 'agent' | 'inbox' | 'account';
}

/**
 * All available Chatwoot variables for campaign templates.
 * Based on the Liquid drops: ContactDrop, UserDrop, InboxDrop, AccountDrop
 */
export const CHATWOOT_VARIABLES: ChatwootVariable[] = [
  // Contact variables
  {
    key: 'contact.name',
    liquidSyntax: '{{contact.name}}',
    labelEn: 'Contact Name',
    labelPtBr: 'Nome do Contato',
    descriptionEn: 'Full name of the contact',
    descriptionPtBr: 'Nome completo do contato',
    category: 'contact',
  },
  {
    key: 'contact.first_name',
    liquidSyntax: '{{contact.first_name}}',
    labelEn: 'First Name',
    labelPtBr: 'Primeiro Nome',
    descriptionEn: 'First name of the contact',
    descriptionPtBr: 'Primeiro nome do contato',
    category: 'contact',
  },
  {
    key: 'contact.last_name',
    liquidSyntax: '{{contact.last_name}}',
    labelEn: 'Last Name',
    labelPtBr: 'Último Nome',
    descriptionEn: 'Last name of the contact',
    descriptionPtBr: 'Último nome do contato',
    category: 'contact',
  },
  {
    key: 'contact.email',
    liquidSyntax: '{{contact.email}}',
    labelEn: 'Email',
    labelPtBr: 'E-mail',
    descriptionEn: 'Email address of the contact',
    descriptionPtBr: 'Endereço de e-mail do contato',
    category: 'contact',
  },
  {
    key: 'contact.phone_number',
    liquidSyntax: '{{contact.phone_number}}',
    labelEn: 'Phone Number',
    labelPtBr: 'Telefone',
    descriptionEn: 'Phone number of the contact',
    descriptionPtBr: 'Número de telefone do contato',
    category: 'contact',
  },

  // Agent variables (campaign sender)
  {
    key: 'agent.name',
    liquidSyntax: '{{agent.name}}',
    labelEn: 'Agent Name',
    labelPtBr: 'Nome do Agente',
    descriptionEn: 'Full name of the campaign sender',
    descriptionPtBr: 'Nome completo do remetente da campanha',
    category: 'agent',
  },
  {
    key: 'agent.first_name',
    liquidSyntax: '{{agent.first_name}}',
    labelEn: 'Agent First Name',
    labelPtBr: 'Primeiro Nome do Agente',
    descriptionEn: 'First name of the campaign sender',
    descriptionPtBr: 'Primeiro nome do remetente da campanha',
    category: 'agent',
  },
  {
    key: 'agent.available_name',
    liquidSyntax: '{{agent.available_name}}',
    labelEn: 'Agent Display Name',
    labelPtBr: 'Nome de Exibição do Agente',
    descriptionEn: 'Display name of the campaign sender',
    descriptionPtBr: 'Nome de exibição do remetente da campanha',
    category: 'agent',
  },

  // Inbox variables
  {
    key: 'inbox.name',
    liquidSyntax: '{{inbox.name}}',
    labelEn: 'Inbox Name',
    labelPtBr: 'Nome da Caixa de Entrada',
    descriptionEn: 'Name of the WhatsApp inbox',
    descriptionPtBr: 'Nome da caixa de entrada do WhatsApp',
    category: 'inbox',
  },

  // Account variables
  {
    key: 'account.name',
    liquidSyntax: '{{account.name}}',
    labelEn: 'Account Name',
    labelPtBr: 'Nome da Conta',
    descriptionEn: 'Name of your account (company)',
    descriptionPtBr: 'Nome da sua conta (empresa)',
    category: 'account',
  },
];

/**
 * Get variables by category
 */
export function getVariablesByCategory(
  category: ChatwootVariable['category']
): ChatwootVariable[] {
  return CHATWOOT_VARIABLES.filter(v => v.category === category);
}

/**
 * Get the most commonly used variables (contact-related)
 */
export function getCommonVariables(): ChatwootVariable[] {
  return CHATWOOT_VARIABLES.filter(v =>
    ['contact.first_name', 'contact.name', 'contact.phone_number'].includes(
      v.key
    )
  );
}

/**
 * Find a variable by its key
 */
export function findVariableByKey(key: string): ChatwootVariable | undefined {
  return CHATWOOT_VARIABLES.find(v => v.key === key);
}

/**
 * Check if a string is a Chatwoot variable
 */
export function isChatwootVariable(value: string): boolean {
  const trimmed = value.trim();
  return CHATWOOT_VARIABLES.some(v => v.liquidSyntax === trimmed);
}

/**
 * Extract the variable key from liquid syntax (e.g., "{{contact.first_name}}" -> "contact.first_name")
 */
export function extractVariableKey(liquidSyntax: string): string | null {
  const match = liquidSyntax.match(/\{\{([^}]+)\}\}/);
  return match ? match[1].trim() : null;
}

/**
 * Variable categories with labels
 */
export const VARIABLE_CATEGORIES = [
  {
    key: 'contact',
    labelEn: 'Contact',
    labelPtBr: 'Contato',
  },
  {
    key: 'agent',
    labelEn: 'Agent',
    labelPtBr: 'Agente',
  },
  {
    key: 'inbox',
    labelEn: 'Inbox',
    labelPtBr: 'Caixa de Entrada',
  },
  {
    key: 'account',
    labelEn: 'Account',
    labelPtBr: 'Conta',
  },
] as const;

