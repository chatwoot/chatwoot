<script setup>
import ScenariosCard from './ScenariosCard.vue';

const sampleScenarios = [
  {
    id: 1,
    title: 'Refund Order',
    description: 'User requests a refund for a recent purchase.',
    instruction:
      'Gather order details and reason for refund. Use [Order Search](tool://order_search) then submit with [Refund Payment](tool://refund_payment).',
    tools: ['order_search', 'refund_payment'],
  },
  {
    id: 2,
    title: 'Bug Report',
    description: 'Customer reports a bug in the mobile app.',
    instruction:
      'Ask for reproduction steps and environment. Check [Known Issues](tool://known_issues) then create ticket with [Create Bug Report](tool://bug_report_create).',
    tools: ['known_issues', 'bug_report_create'],
  },
];
</script>

<template>
  <Story
    title="Captain/Assistant/ScenariosCard"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Default">
      <div
        v-for="scenario in sampleScenarios"
        :key="scenario.id"
        class="px-4 py-4 bg-n-background"
      >
        <ScenariosCard
          :id="scenario.id"
          :title="scenario.title"
          :description="scenario.description"
          :instruction="scenario.instruction"
          :tools="scenario.tools"
        />
      </div>
    </Variant>
  </Story>
</template>
