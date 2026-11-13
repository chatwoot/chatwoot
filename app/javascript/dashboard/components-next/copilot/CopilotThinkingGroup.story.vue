<script setup>
import CopilotThinkingGroup from './CopilotThinkingGroup.vue';

const step = (id, content) => ({ id, message: { content, run_id: 1 } });
const messages = [
  step(1, 'Finding matching records'),
  step(2, 'Reading a conversation'),
  step(3, 'Finding matching records'),
];
</script>

<template>
  <Story title="Captain/Copilot/CopilotThinkingGroup" group="components">
    <Variant title="Working">
      <CopilotThinkingGroup :messages="messages" is-active />
    </Variant>

    <Variant title="Done">
      <CopilotThinkingGroup :messages="messages" />
    </Variant>
  </Story>
</template>
