<script setup>
import BaseBubble from './Base.vue';
</script>

<template>
  <BaseBubble
    class="px-[var(--bubble-padding-x)] py-[var(--bubble-padding-y)] text-sm"
    data-bubble-name="unsupported"
  >
    {{ $t('CONVERSATION.UNSUPPORTED_MESSAGE') }}
  </BaseBubble>
</template>
