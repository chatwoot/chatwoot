<script setup>
import CopilotHeader from './CopilotHeader.vue';
</script>

<template>
  <Story
    title="Captain/Copilot/CopilotHeader"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <!-- Default State -->
    <Variant title="Default State">
      <CopilotHeader />
    </Variant>

    <!-- With New Conversation Button -->
    <Variant title="With New Conversation Button">
      <!-- eslint-disable-next-line vue/prefer-true-attribute-shorthand -->
      <CopilotHeader :has-messages="true" />
    </Variant>
  </Story>
</template>
