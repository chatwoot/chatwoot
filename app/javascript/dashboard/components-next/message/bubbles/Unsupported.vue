<script setup>
import BaseBubble from './Base.vue';
</script>

<template>
  <BaseBubble class="px-4 py-3 text-sm" data-bubble-name="unsupported">
    {{ $t('CONVERSATION.UNSUPPORTED_MESSAGE') }}
  </BaseBubble>
</template>
