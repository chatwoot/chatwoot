// Default workflow templates for quick-start agent creation.
// Each template is a complete workflow JSON that can be loaded into the editor.

export const WORKFLOW_TEMPLATES = {
  simple_qa: {
    name: 'Simple Q&A',
    description:
      'Basic question-answering flow with system prompt and LLM call.',
    icon: 'i-lucide-message-circle',
    schema_version: 'v2',
    nodes: [
      {
        id: 'trigger_1',
        type: 'trigger',
        position: { x: 50, y: 200 },
        data: { label: 'Message Received', trigger_type: 'message_received' },
      },
      {
        id: 'system_prompt_1',
        type: 'system_prompt',
        position: { x: 300, y: 200 },
        data: {
          label: 'System Prompt',
          prompt_template:
            'You are a helpful customer support assistant. Answer questions clearly and concisely.',
          append_context: false,
        },
      },
      {
        id: 'llm_call_1',
        type: 'llm_call',
        position: { x: 550, y: 200 },
        data: {
          label: 'Generate Reply',
          temperature: 0.7,
          tools_enabled: false,
        },
      },
      {
        id: 'reply_1',
        type: 'reply',
        position: { x: 800, y: 200 },
        data: {
          label: 'Send Reply',
          message_type: 'text',
        },
      },
    ],
    edges: [
      {
        id: 'e1',
        source: 'trigger_1',
        target: 'system_prompt_1',
        source_handle: 'flow_out',
        target_handle: 'flow_in',
      },
      {
        id: 'e2',
        source: 'system_prompt_1',
        target: 'llm_call_1',
        source_handle: 'flow_out',
        target_handle: 'flow_in',
      },
      {
        id: 'e3',
        source: 'llm_call_1',
        target: 'reply_1',
        source_handle: 'flow_out',
        target_handle: 'flow_in',
      },
    ],
  },

  rag_agent: {
    name: 'RAG Agent',
    description: 'Retrieves knowledge base context before generating a reply.',
    icon: 'i-lucide-book-open',
    schema_version: 'v2',
    nodes: [
      {
        id: 'trigger_1',
        type: 'trigger',
        position: { x: 50, y: 200 },
        data: { label: 'Message Received', trigger_type: 'message_received' },
      },
      {
        id: 'system_prompt_1',
        type: 'system_prompt',
        position: { x: 300, y: 200 },
        data: {
          label: 'System Prompt',
          prompt_template:
            'You are a knowledgeable support agent. Use the provided context to answer accurately. If you cannot find the answer in the context, say so.',
          append_context: true,
        },
      },
      {
        id: 'knowledge_1',
        type: 'knowledge_retrieval',
        position: { x: 550, y: 200 },
        data: {
          label: 'Search Knowledge',
          top_k: 5,
          knowledge_base_ids: [],
        },
      },
      {
        id: 'llm_call_1',
        type: 'llm_call',
        position: { x: 800, y: 200 },
        data: {
          label: 'Generate Reply',
          temperature: 0.3,
          tools_enabled: false,
        },
      },
      {
        id: 'reply_1',
        type: 'reply',
        position: { x: 1050, y: 200 },
        data: { label: 'Send Reply', message_type: 'text' },
      },
    ],
    edges: [
      {
        id: 'e1',
        source: 'trigger_1',
        target: 'system_prompt_1',
        source_handle: 'flow_out',
        target_handle: 'flow_in',
      },
      {
        id: 'e2',
        source: 'system_prompt_1',
        target: 'knowledge_1',
        source_handle: 'flow_out',
        target_handle: 'flow_in',
      },
      {
        id: 'e3',
        source: 'knowledge_1',
        target: 'llm_call_1',
        source_handle: 'flow_out',
        target_handle: 'flow_in',
      },
      {
        id: 'e4',
        source: 'llm_call_1',
        target: 'reply_1',
        source_handle: 'flow_out',
        target_handle: 'flow_in',
      },
    ],
  },

  tool_calling_agent: {
    name: 'Tool-Calling Agent',
    description:
      'Agent with tool access that can escalate to humans when needed.',
    icon: 'i-lucide-wrench',
    schema_version: 'v2',
    nodes: [
      {
        id: 'trigger_1',
        type: 'trigger',
        position: { x: 50, y: 250 },
        data: { label: 'Message Received', trigger_type: 'message_received' },
      },
      {
        id: 'system_prompt_1',
        type: 'system_prompt',
        position: { x: 300, y: 250 },
        data: {
          label: 'System Prompt',
          prompt_template:
            'You are a support agent with access to tools. Use them when needed. If a question is beyond your capability, hand off to a human.',
          append_context: true,
        },
      },
      {
        id: 'llm_call_1',
        type: 'llm_call',
        position: { x: 550, y: 250 },
        data: {
          label: 'LLM + Tools',
          temperature: 0.5,
          tools_enabled: true,
          tool_choice: 'auto',
        },
      },
      {
        id: 'condition_1',
        type: 'condition',
        position: { x: 800, y: 250 },
        data: {
          label: 'Needs Handoff?',
          rules: [
            {
              field: 'llm_reply',
              operator: 'contains',
              value: 'hand off',
            },
          ],
          logic: 'or',
        },
      },
      {
        id: 'reply_1',
        type: 'reply',
        position: { x: 1050, y: 150 },
        data: { label: 'Send Reply', message_type: 'text' },
      },
      {
        id: 'handoff_1',
        type: 'handoff',
        position: { x: 1050, y: 350 },
        data: {
          label: 'Hand Off',
          reason_template: 'Customer requested human assistance',
        },
      },
    ],
    edges: [
      {
        id: 'e1',
        source: 'trigger_1',
        target: 'system_prompt_1',
        source_handle: 'flow_out',
        target_handle: 'flow_in',
      },
      {
        id: 'e2',
        source: 'system_prompt_1',
        target: 'llm_call_1',
        source_handle: 'flow_out',
        target_handle: 'flow_in',
      },
      {
        id: 'e3',
        source: 'llm_call_1',
        target: 'condition_1',
        source_handle: 'flow_out',
        target_handle: 'flow_in',
      },
      {
        id: 'e4',
        source: 'condition_1',
        target: 'reply_1',
        source_handle: 'flow_false',
        target_handle: 'flow_in',
      },
      {
        id: 'e5',
        source: 'condition_1',
        target: 'handoff_1',
        source_handle: 'flow_true',
        target_handle: 'flow_in',
      },
    ],
  },
};

export const TEMPLATE_LIST = Object.entries(WORKFLOW_TEMPLATES).map(
  ([key, template]) => ({
    key,
    name: template.name,
    description: template.description,
    icon: template.icon,
  })
);
