<script setup>
import { computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  pendingAction: {
    type: Object,
    required: true,
  },
  isProcessing: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['confirm', 'reject']);

const summary = computed(() => props.pendingAction.summary);
</script>

<template>
  <div
    class="rounded-lg border border-n-amber-6 bg-n-amber-2 p-3 flex flex-col gap-3"
  >
    <div class="flex flex-col gap-1">
      <span class="text-xs font-medium text-n-amber-11 uppercase tracking-wide">
        {{ $t('CAPTAIN.COPILOT.ADMIN_ACTION.TITLE') }}
      </span>
      <p class="text-sm text-n-slate-12">
        {{ summary }}
      </p>
      <p class="text-xs text-n-slate-11">
        {{ $t('CAPTAIN.COPILOT.ADMIN_ACTION.DESCRIPTION') }}
      </p>
    </div>
    <div class="flex gap-2">
      <Button
        :label="$t('CAPTAIN.COPILOT.ADMIN_ACTION.CONFIRM')"
        sm
        :disabled="isProcessing"
        @click="emit('confirm', pendingAction.id)"
      />
      <Button
        :label="$t('CAPTAIN.COPILOT.ADMIN_ACTION.REJECT')"
        sm
        faded
        slate
        :disabled="isProcessing"
        @click="emit('reject', pendingAction.id)"
      />
    </div>
  </div>
</template>
