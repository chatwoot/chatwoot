/**
 * Node types registry — maps type strings to component metadata.
 * This is imported by both the composable (for validation/defaults)
 * and the canvas (for rendering custom node components).
 */

export const NODE_CATEGORIES = {
  trigger: {
    label: 'Trigger',
    color: 'bg-emerald-500',
    borderColor: 'border-emerald-500',
    lightBg: 'bg-emerald-50 dark:bg-emerald-900/20',
    icon: 'i-lucide-zap',
  },
  ai: {
    label: 'AI',
    color: 'bg-violet-500',
    borderColor: 'border-violet-500',
    lightBg: 'bg-violet-50 dark:bg-violet-900/20',
    icon: 'i-lucide-brain',
  },
  logic: {
    label: 'Logic',
    color: 'bg-amber-500',
    borderColor: 'border-amber-500',
    lightBg: 'bg-amber-50 dark:bg-amber-900/20',
    icon: 'i-lucide-git-branch',
  },
  actions: {
    label: 'Actions',
    color: 'bg-blue-500',
    borderColor: 'border-blue-500',
    lightBg: 'bg-blue-50 dark:bg-blue-900/20',
    icon: 'i-lucide-play',
  },
};

export const NODE_TYPES_META = {
  // --- Trigger ---
  trigger: {
    category: 'trigger',
    defaultLabel: 'Message Received',
    description: 'Starts the workflow when a message arrives',
    icon: 'i-lucide-zap',
    inputs: [],
    outputs: [
      { id: 'out', type: 'flow', label: '' },
      { id: 'message', type: 'data', label: 'message' },
    ],
    defaultData: {
      trigger_type: 'message_received',
      inbox_ids: [],
    },
    configFields: [
      {
        key: 'trigger_type',
        label: 'Trigger Type',
        type: 'select',
        options: [
          { value: 'message_received', label: 'Message Received' },
          { value: 'phone_call', label: 'Phone Call' },
          { value: 'webhook', label: 'Webhook' },
        ],
      },
    ],
  },

  // --- AI ---
  system_prompt: {
    category: 'ai',
    defaultLabel: 'System Prompt',
    description: 'Define the AI personality and instructions',
    icon: 'i-lucide-message-square-text',
    inputs: [
      { id: 'in', type: 'flow', label: '' },
      { id: 'context', type: 'data', label: 'context' },
    ],
    outputs: [
      { id: 'out', type: 'flow', label: '' },
      { id: 'messages', type: 'messages', label: 'messages' },
    ],
    defaultData: {
      prompt_template: 'You are a helpful assistant.',
      append_context: true,
    },
    configFields: [
      { key: 'prompt_template', label: 'Prompt Template', type: 'textarea' },
      { key: 'append_context', label: 'Append Context', type: 'toggle' },
    ],
  },

  knowledge_retrieval: {
    category: 'ai',
    defaultLabel: 'Knowledge Search',
    description: 'Search knowledge bases for relevant context',
    icon: 'i-lucide-database',
    inputs: [
      { id: 'in', type: 'flow', label: '' },
      { id: 'query', type: 'data', label: 'query' },
    ],
    outputs: [
      { id: 'out', type: 'flow', label: '' },
      { id: 'context', type: 'data', label: 'context' },
    ],
    defaultData: {
      knowledge_base_ids: [],
      top_k: 5,
    },
    configFields: [
      {
        key: 'knowledge_base_ids',
        label: 'Knowledge Bases',
        type: 'multi-select',
      },
      { key: 'top_k', label: 'Top K Results', type: 'number', min: 1, max: 20 },
    ],
  },

  llm_call: {
    category: 'ai',
    defaultLabel: 'LLM Call',
    description: 'Call the language model to generate a response',
    icon: 'i-lucide-brain',
    inputs: [
      { id: 'in', type: 'flow', label: '' },
      { id: 'messages', type: 'messages', label: 'messages' },
    ],
    outputs: [
      { id: 'out', type: 'flow', label: '' },
      { id: 'response', type: 'data', label: 'response' },
      { id: 'tool_calls', type: 'data', label: 'tool_calls' },
      { id: 'messages', type: 'messages', label: 'messages' },
    ],
    defaultData: {
      model: null,
      temperature: 0.7,
      max_tokens: 4096,
      tools_enabled: false,
      tool_choice: 'auto',
      response_format: 'text',
    },
    configFields: [
      {
        key: 'model',
        label: 'Model Override',
        type: 'text',
        placeholder: 'Uses agent default',
      },
      {
        key: 'temperature',
        label: 'Temperature',
        type: 'slider',
        min: 0,
        max: 2,
        step: 0.1,
      },
      {
        key: 'max_tokens',
        label: 'Max Tokens',
        type: 'number',
        min: 1,
        max: 128000,
      },
      { key: 'tools_enabled', label: 'Enable Tools', type: 'toggle' },
      {
        key: 'tool_choice',
        label: 'Tool Choice',
        type: 'select',
        options: [
          { value: 'auto', label: 'Auto' },
          { value: 'required', label: 'Required' },
          { value: 'none', label: 'None' },
        ],
      },
    ],
  },

  // --- Logic ---
  condition: {
    category: 'logic',
    defaultLabel: 'Condition',
    description: 'Branch the workflow based on a condition',
    icon: 'i-lucide-git-branch',
    inputs: [
      { id: 'in', type: 'flow', label: '' },
      { id: 'value', type: 'data', label: 'value' },
    ],
    outputs: [
      { id: 'true', type: 'flow', label: 'true' },
      { id: 'false', type: 'flow', label: 'false' },
    ],
    defaultData: {
      rules: [{ field: '', operator: 'equals', value: '' }],
      logic: 'and',
    },
    configFields: [
      { key: 'rules', label: 'Rules', type: 'condition-rules' },
      {
        key: 'logic',
        label: 'Logic',
        type: 'select',
        options: [
          { value: 'and', label: 'AND — all must match' },
          { value: 'or', label: 'OR — any must match' },
        ],
      },
    ],
  },

  loop: {
    category: 'logic',
    defaultLabel: 'Loop',
    description: 'Iterate over a list of items',
    icon: 'i-lucide-repeat',
    inputs: [
      { id: 'in', type: 'flow', label: '' },
      { id: 'items', type: 'data', label: 'items' },
    ],
    outputs: [
      { id: 'each', type: 'flow', label: 'each' },
      { id: 'item', type: 'data', label: 'item' },
      { id: 'done', type: 'flow', label: 'done' },
    ],
    defaultData: {
      max_iterations: 10,
    },
    configFields: [
      {
        key: 'max_iterations',
        label: 'Max Iterations',
        type: 'number',
        min: 1,
        max: 100,
      },
    ],
  },

  set_variable: {
    category: 'logic',
    defaultLabel: 'Set Variable',
    description: 'Store a value in a workflow variable',
    icon: 'i-lucide-variable',
    inputs: [
      { id: 'in', type: 'flow', label: '' },
      { id: 'value', type: 'data', label: 'value' },
    ],
    outputs: [{ id: 'out', type: 'flow', label: '' }],
    defaultData: {
      variable_name: '',
      expression: '',
    },
    configFields: [
      { key: 'variable_name', label: 'Variable Name', type: 'text' },
      { key: 'expression', label: 'Expression (Liquid)', type: 'textarea' },
    ],
  },

  delay: {
    category: 'logic',
    defaultLabel: 'Delay',
    description: 'Wait before continuing the workflow',
    icon: 'i-lucide-timer',
    inputs: [{ id: 'in', type: 'flow', label: '' }],
    outputs: [{ id: 'out', type: 'flow', label: '' }],
    defaultData: {
      seconds: 5,
    },
    configFields: [
      {
        key: 'seconds',
        label: 'Delay (seconds)',
        type: 'number',
        min: 1,
        max: 3600,
      },
    ],
  },

  // --- Actions ---
  http_request: {
    category: 'actions',
    defaultLabel: 'HTTP Request',
    description: 'Make an HTTP request to an external API',
    icon: 'i-lucide-globe',
    inputs: [
      { id: 'in', type: 'flow', label: '' },
      { id: 'body_data', type: 'data', label: 'body' },
    ],
    outputs: [
      { id: 'out', type: 'flow', label: '' },
      { id: 'response', type: 'data', label: 'response' },
      { id: 'status_code', type: 'data', label: 'status' },
    ],
    defaultData: {
      method: 'GET',
      url_template: '',
      headers_template: {},
      body_template: '',
      timeout_seconds: 15,
    },
    configFields: [
      {
        key: 'method',
        label: 'Method',
        type: 'select',
        options: [
          { value: 'GET', label: 'GET' },
          { value: 'POST', label: 'POST' },
          { value: 'PUT', label: 'PUT' },
          { value: 'PATCH', label: 'PATCH' },
          { value: 'DELETE', label: 'DELETE' },
        ],
      },
      { key: 'url_template', label: 'URL Template', type: 'text' },
      { key: 'headers_template', label: 'Headers (JSON)', type: 'textarea' },
      { key: 'body_template', label: 'Body Template', type: 'textarea' },
      {
        key: 'timeout_seconds',
        label: 'Timeout (s)',
        type: 'number',
        min: 1,
        max: 120,
      },
    ],
  },

  handoff: {
    category: 'actions',
    defaultLabel: 'Handoff to Human',
    description: 'Transfer the conversation to a human agent',
    icon: 'i-lucide-user-check',
    inputs: [{ id: 'in', type: 'flow', label: '' }],
    outputs: [],
    defaultData: {
      reason_template: 'AI agent could not resolve the issue.',
    },
    configFields: [
      { key: 'reason_template', label: 'Reason (Liquid)', type: 'textarea' },
    ],
  },

  reply: {
    category: 'actions',
    defaultLabel: 'Send Reply',
    description: 'Send a message back to the user',
    icon: 'i-lucide-message-circle',
    inputs: [
      { id: 'in', type: 'flow', label: '' },
      { id: 'content', type: 'data', label: 'content' },
    ],
    outputs: [{ id: 'out', type: 'flow', label: '' }],
    defaultData: {
      message_type: 'text',
      content_template: null,
      content_attributes: { ai_generated: true },
    },
    configFields: [
      {
        key: 'message_type',
        label: 'Message Type',
        type: 'select',
        options: [
          { value: 'text', label: 'Text' },
          { value: 'template', label: 'Template' },
        ],
      },
      {
        key: 'content_template',
        label: 'Content Template (Liquid)',
        type: 'textarea',
        placeholder: 'Leave empty to use input content',
      },
    ],
  },

  // --- Code (sandbox) ---
  code: {
    category: 'logic',
    defaultLabel: 'Code',
    description: 'Run a custom expression',
    icon: 'i-lucide-code',
    inputs: [
      { id: 'in', type: 'flow', label: '' },
      { id: 'input', type: 'data', label: 'input' },
    ],
    outputs: [
      { id: 'out', type: 'flow', label: '' },
      { id: 'result', type: 'data', label: 'result' },
    ],
    defaultData: {
      language: 'liquid',
      code: '',
    },
    configFields: [
      {
        key: 'language',
        label: 'Language',
        type: 'select',
        options: [{ value: 'liquid', label: 'Liquid' }],
      },
      { key: 'code', label: 'Code', type: 'code' },
    ],
  },
};

// Derive the palette items grouped by category
export const NODE_PALETTE_ITEMS = Object.entries(NODE_CATEGORIES).map(
  ([categoryKey, categoryMeta]) => ({
    ...categoryMeta,
    key: categoryKey,
    nodes: Object.entries(NODE_TYPES_META)
      .filter(([, meta]) => meta.category === categoryKey)
      .map(([type, meta]) => ({
        type,
        label: meta.defaultLabel,
        description: meta.description,
        icon: meta.icon,
      })),
  })
);

// Handle type colors for edge rendering
export const HANDLE_COLORS = {
  flow: 'bg-n-slate-8 dark:bg-n-slate-4',
  data: 'bg-blue-500',
  messages: 'bg-violet-500',
};
