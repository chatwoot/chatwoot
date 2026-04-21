<script setup>
import { defineProps, defineEmits } from 'vue';

defineProps({
  showingOriginal: Boolean,
});

defineEmits(['toggle']);
</script>

<template>
  <span>
    <span
      class="text-xs text-s-muted cursor-pointer hover:underline select-none"
      @click="$emit('toggle')"
    >
      {{
        showingOriginal
          ? $t('CONVERSATION.VIEW_TRANSLATED')
          : $t('CONVERSATION.VIEW_ORIGINAL')
      }}
    </span>
  </span>
</template>
