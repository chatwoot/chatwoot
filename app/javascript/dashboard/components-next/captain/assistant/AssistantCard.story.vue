<script setup>
import AssistantCard from './AssistantCard.vue';

const assistantList = [
  {
    account_id: 2,
    config: { product_name: 'HelpDesk Pro' },
    created_at: 1736033561,
    description: 'An advanced assistant for customer support solutions',
    id: 4,
    name: 'Support Genie',
  },
  {
    account_id: 3,
    config: { product_name: 'CRM Tools' },
    created_at: 1736033562,
    description: 'Assists in managing customer relationships efficiently',
    id: 5,
    name: 'CRM Assistant',
  },
  {
    account_id: 4,
    config: { product_name: 'SalesFlow' },
    created_at: 1736033563,
    description: 'Optimizes sales pipeline tracking and forecasting',
    id: 6,
    name: 'SalesBot',
  },
  {
    account_id: 5,
    config: { product_name: 'TicketMaster AI' },
    created_at: 1736033564,
    description: 'Automates ticket assignment and customer query responses',
    id: 7,
    name: 'TicketBot',
  },
  {
    account_id: 6,
    config: { product_name: 'FinanceAssist' },
    created_at: 1736033565,
    description: 'Provides financial analytics and reporting',
    id: 8,
    name: 'Finance Wizard',
  },
  {
    account_id: 7,
    config: { product_name: 'MarketingMate' },
    created_at: 1736033566,
    description: 'Automates marketing tasks and generates campaign insights',
    id: 9,
    name: 'Marketing Guru',
  },
  {
    account_id: 8,
    config: { product_name: 'HR Assistant' },
    created_at: 1736033567,
    description: 'Streamlines HR operations and employee management',
    id: 10,
    name: 'HR Helper',
  },
];
</script>

<template>
  <Story
    title="Captain/Assistant/AssistantCard"
    :layout="{ type: 'grid', width: '700px' }"
  >
    <Variant title="Assistant Card">
      <div
        v-for="(assistant, index) in assistantList"
        :key="index"
        class="px-20 py-4 bg-white dark:bg-slate-900"
      >
        <AssistantCard
          :id="assistant.id"
          :name="assistant.name"
          :description="assistant.description"
          :updated-at="assistant.updated_at || assistant.created_at"
          :created-at="assistant.created_at"
        />
      </div>
    </Variant>
  </Story>
</template>
