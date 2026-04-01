<script setup>
import SuggestedRules from './SuggestedRules.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const guidelinesExample = [
  {
    content:
      'Block queries that share or request sensitive personal information (e.g. phone numbers, passwords).',
  },
  {
    content:
      'Reject queries that include offensive, discriminatory, or threatening language.',
  },
  {
    content:
      'Deflect when the assistant is asked for legal or medical diagnosis or treatment.',
  },
];
</script>

<template>
  <Story
    title="Captain/Assistant/SuggestedRules"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Suggested Rules List">
      <div class="bg-surface px-20 py-4">
        <SuggestedRules
          title="Example response guidelines"
          :items="guidelinesExample"
        >
          <template #default="{ item }">
            <span class="text-sm text-on-surface">{{ item.content }}</span>
            <Button
              label="Add this"
              ghost
              xs
              slate
              class="!text-sm flex-shrink-0 text-on-surface-variant"
            />
          </template>
        </SuggestedRules>
      </div>
    </Variant>
  </Story>
</template>
