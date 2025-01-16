<script setup>
import ResponseCard from './ResponseCard.vue';

const responses = [
  {
    account_id: 1,
    answer:
      'Messenger may be deactivated because you are on a free plan or the limit for inboxes might have been reached.',
    created_at: 1736283330,
    id: 87,
    question: 'Why is my Messenger in Chatwoot deactivated?',
    status: 'pending',
    assistant: {
      account_id: 1,
      config: {
        product_name: 'Chatwoot',
      },
      created_at: 1736033280,
      description: 'This is a description of the assistant 2',
      id: 1,
      name: 'Assistant 2',
    },
  },
  {
    account_id: 2,
    answer:
      'You can integrate your WhatsApp account by navigating to the Integrations section and selecting the WhatsApp integration option.',
    created_at: 1736283340,
    id: 88,
    question: 'How do I integrate WhatsApp with Chatwoot?',
    assistant: {
      account_id: 2,
      config: {
        product_name: 'Chatwoot',
      },
      created_at: 1736033281,
      description: 'Handles integration queries',
      id: 2,
      name: 'Assistant 3',
    },
  },
  {
    account_id: 3,
    answer:
      "To reset your password, go to the login page and click on 'Forgot Password', then follow the instructions sent to your email.",
    created_at: 1736283350,
    id: 89,
    question: 'How can I reset my password in Chatwoot?',
    assistant: {
      account_id: 3,
      config: {
        product_name: 'Chatwoot',
      },
      created_at: 1736033282,
      description: 'Handles account management support',
      id: 3,
      name: 'Assistant 4',
    },
  },
  {
    account_id: 4,
    answer:
      "You can enable the dark mode in settings by navigating to 'Appearance' and selecting 'Dark Mode'.",
    created_at: 1736283360,
    id: 90,
    question: 'How do I enable dark mode in Chatwoot?',
    assistant: {
      account_id: 4,
      config: {
        product_name: 'Chatwoot',
      },
      created_at: 1736033283,
      description: 'Helps with UI customization',
      id: 4,
      name: 'Assistant 5',
    },
  },
  {
    account_id: 5,
    answer:
      "To add a new team member, navigate to 'Settings', then 'Team', and click on 'Add Team Member'.",
    created_at: 1736283370,
    id: 91,
    question: 'How do I add a new team member in Chatwoot?',
    assistant: {
      account_id: 5,
      config: {
        product_name: 'Chatwoot',
      },
      created_at: 1736033284,
      description: 'Handles team management queries',
      id: 5,
      name: 'Assistant 6',
    },
  },
  {
    account_id: 6,
    answer:
      "Campaigns in Chatwoot allow you to send targeted messages to specific user segments. You can create them in the 'Campaigns' section.",
    created_at: 1736283380,
    id: 92,
    question: 'What are campaigns in Chatwoot?',
    assistant: {
      account_id: 6,
      config: {
        product_name: 'Chatwoot',
      },
      created_at: 1736033285,
      description: 'Focuses on campaign and marketing queries',
      id: 6,
      name: 'Assistant 7',
    },
  },
  {
    account_id: 7,
    answer:
      "To track an agent's performance, use the Analytics dashboard under 'Reports'.",
    created_at: 1736283390,
    id: 93,
    question: "How can I track an agent's performance in Chatwoot?",
    assistant: {
      account_id: 7,
      config: {
        product_name: 'Chatwoot',
      },
      created_at: 1736033286,
      description: 'Analytics and reporting assistant',
      id: 7,
      name: 'Assistant 8',
    },
  },
];
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story
    title="Captain/Assistant/ResponseCard"
    :layout="{ type: 'grid', width: '700px' }"
  >
    <Variant title="Article Card">
      <div
        v-for="(response, index) in responses"
        :key="index"
        class="px-20 py-4 bg-white dark:bg-slate-900"
      >
        <ResponseCard
          :id="response.id"
          :question="response.question"
          :answer="response.answer"
          :status="response.status"
          :assistant="response.assistant"
          :created-at="response.created_at"
        />
      </div>
    </Variant>
  </Story>
</template>
