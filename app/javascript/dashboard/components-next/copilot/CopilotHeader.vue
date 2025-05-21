<script setup>
import Button from '../button/Button.vue';
defineProps({
  hasMessages: {
    type: Boolean,
    default: false,
  },
});
defineEmits(['reset', 'close']);
</script>

<template>
  <div
    class="flex items-center justify-between px-5 py-2 border-b border-n-weak h-12"
  >
    <div class="flex items-center justify-between gap-2 flex-1">
      <span class="font-medium text-sm text-n-slate-12">
        {{ $t('CAPTAIN.COPILOT.TITLE') }}
      </span>
      <div class="flex items-center">
        <Button
          v-if="hasMessages"
          icon="i-lucide-plus"
          ghost
          sm
          @click="$emit('reset')"
        />
        <Button icon="i-lucide-x" ghost sm @click="$emit('close')" />
      </div>
    </div>
  </div>
</template>
