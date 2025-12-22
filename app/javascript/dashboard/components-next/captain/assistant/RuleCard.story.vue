<script setup>
import RuleCard from './RuleCard.vue';

const sampleRules = [
  { id: 1, content: 'Block sensitive personal information', selectable: true },
  { id: 2, content: 'Reject offensive language', selectable: true },
  { id: 3, content: 'Deflect legal or medical advice', selectable: true },
];
</script>

<template>
  <Story
    title="Captain/Assistant/RuleCard"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Selectable List">
      <div class="flex flex-col gap-4 px-20 py-4 bg-n-background">
        <RuleCard
          v-for="rule in sampleRules"
          :id="rule.id"
          :key="rule.id"
          :content="rule.content"
          :selectable="rule.selectable"
          @select="id => console.log('Selected rule', id)"
          @edit="id => console.log('Edit', id)"
          @delete="id => console.log('Delete', id)"
        />
      </div>
    </Variant>

    <Variant title="Non-Selectable">
      <div class="flex flex-col gap-4 px-20 py-4 bg-n-background">
        <RuleCard id="4" content="Replies should be friendly and clear." />
      </div>
    </Variant>
  </Story>
</template>
