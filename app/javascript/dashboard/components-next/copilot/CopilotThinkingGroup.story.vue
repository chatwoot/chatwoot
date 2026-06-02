<script setup>
import CopilotThinkingGroup from './CopilotThinkingGroup.vue';

const messages = [
  {
    id: 1,
    content: 'Analyzing the user query',
    reasoning: 'Breaking down the request into actionable steps',
  },
  {
    id: 2,
    content: 'Searching codebase',
    reasoning: 'Looking for relevant files and functions',
  },
  {
    id: 3,
    content: 'Generating response',
    reasoning: 'Composing a helpful and accurate answer',
  },
];
</script>

<template>
  <Story title="Captain/Copilot/CopilotThinkingGroup" group="components">
    <Variant title="Default">
      <CopilotThinkingGroup :messages="messages" />
    </Variant>

    <Variant title="With Default Collapsed">
      <!-- eslint-disable-next-line -->
      <CopilotThinkingGroup :messages="messages" :default-collapsed="true" />
    </Variant>
  </Story>
</template>
