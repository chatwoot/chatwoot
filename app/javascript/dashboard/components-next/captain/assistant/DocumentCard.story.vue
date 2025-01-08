<script setup>
import DocumentCard from './DocumentCard.vue';

const documents = [
  {
    account_id: 1,
    assistant: {
      id: 1,
      name: 'Helper Pro',
    },
    content: 'Guide content for using conversation filters.',
    created_at: 1736143272,
    external_link:
      'https://www.chatwoot.com/hc/user-guide/articles/1677688192-how-to-use-conversation-filters',
    id: 3059,
    name: 'How to use Conversation Filters? | User Guide | Chatwoot',
    status: 'available',
  },
  {
    account_id: 2,
    assistant: {
      id: 2,
      name: 'Support Genie',
    },
    content: 'Guide on automating ticket assignments in Chatwoot.',
    created_at: 1736143273,
    external_link:
      'https://www.chatwoot.com/hc/user-guide/articles/1677688200-automating-ticket-assignments',
    id: 3060,
    name: 'Automating Ticket Assignments | User Guide | Chatwoot',
    status: 'available',
  },
  {
    account_id: 3,
    assistant: {
      id: 3,
      name: 'CRM Assistant',
    },
    content: 'Learn how to manage customer profiles efficiently.',
    created_at: 1736143274,
    external_link:
      'https://www.chatwoot.com/hc/user-guide/articles/1677688210-managing-customer-profiles',
    id: 3061,
    name: 'Managing Customer Profiles | User Guide | Chatwoot',
    status: 'available',
  },
  {
    account_id: 4,
    assistant: {
      id: 4,
      name: 'SalesBot',
    },
    content: 'Optimize sales tracking with advanced features.',
    created_at: 1736143275,
    external_link:
      'https://www.chatwoot.com/hc/user-guide/articles/1677688220-sales-tracking-guide',
    id: 3062,
    name: 'Sales Tracking Guide | User Guide | Chatwoot',
    status: 'available',
  },
  {
    account_id: 5,
    assistant: {
      id: 5,
      name: 'TicketBot',
    },
    content: 'Learn how to create and manage tickets in Chatwoot.',
    created_at: 1736143276,
    external_link:
      'https://www.chatwoot.com/hc/user-guide/articles/1677688230-managing-tickets',
    id: 3063,
    name: 'Managing Tickets | User Guide | Chatwoot',
    status: 'available',
  },
  {
    account_id: 6,
    assistant: {
      id: 6,
      name: 'Finance Wizard',
    },
    content: 'Guide on using financial reporting features.',
    created_at: 1736143277,
    external_link:
      'https://www.chatwoot.com/hc/user-guide/articles/1677688240-financial-reporting',
    id: 3064,
    name: 'Financial Reporting | User Guide | Chatwoot',
    status: 'available',
  },
  {
    account_id: 7,
    assistant: {
      id: 7,
      name: 'Marketing Guru',
    },
    content: 'Learn about campaign automation in Chatwoot.',
    created_at: 1736143278,
    external_link:
      'https://www.chatwoot.com/hc/user-guide/articles/1677688250-campaign-automation',
    id: 3065,
    name: 'Campaign Automation | User Guide | Chatwoot',
    status: 'available',
  },
  {
    account_id: 8,
    assistant: {
      id: 8,
      name: 'HR Helper',
    },
    content: 'How to manage employee profiles effectively.',
    created_at: 1736143279,
    external_link:
      'https://www.chatwoot.com/hc/user-guide/articles/1677688260-employee-profile-management',
    id: 3066,
    name: 'Employee Profile Management | User Guide | Chatwoot',
    status: 'available',
  },
  {
    account_id: 9,
    assistant: {
      id: 9,
      name: 'ProjectBot',
    },
    content: 'Guide to project management features in Chatwoot.',
    created_at: 1736143280,
    external_link:
      'https://www.chatwoot.com/hc/user-guide/articles/1677688270-project-management',
    id: 3067,
    name: 'Project Management | User Guide | Chatwoot',
    status: 'available',
  },
  {
    account_id: 10,
    assistant: {
      id: 10,
      name: 'ShopBot',
    },
    content: 'E-commerce optimization with Chatwoot features.',
    created_at: 1736143281,
    external_link:
      'https://www.chatwoot.com/hc/user-guide/articles/1677688280-ecommerce-optimization',
    id: 3068,
    name: 'E-commerce Optimization | User Guide | Chatwoot',
    status: 'available',
  },
];
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story
    title="Captain/Assistant/DocumentCard"
    :layout="{ type: 'grid', width: '700px' }"
  >
    <Variant title="Document Card">
      <div
        v-for="(doc, index) in documents"
        :key="index"
        class="px-20 py-4 bg-white dark:bg-slate-900"
      >
        <DocumentCard
          :id="doc.id"
          :name="doc.name"
          :external-link="doc.external_link"
          :assistant="doc.assistant"
          :created-at="doc.created_at"
        />
      </div>
    </Variant>
  </Story>
</template>
