<script setup>
import { inject } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  identifier: {
    type: String,
    required: true,
  },
  issueUrl: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['unlinkIssue']);

const isUnlinking = inject('isUnlinking');

const unlinkIssue = () => {
  emit('unlinkIssue');
};

const openIssue = () => {
  window.open(props.issueUrl, '_blank');
};
</script>

<template>
  <div class="flex flex-row justify-between">
    <div
      class="flex items-center justify-center gap-1 h-[24px] px-2 py-1 border rounded-lg border-ash-200"
    >
      <fluent-icon
        icon="linear"
        size="19"
        class="text-[#5E6AD2]"
        view-box="0 0 19 19"
      />
      <span class="text-xs font-medium text-ash-900">{{ identifier }}</span>
    </div>
    <div class="flex items-center gap-1">
      <Button
        ghost
        xs
        slate
        icon="i-lucide-unlink"
        class="!transition-none"
        :is-loading="isUnlinking"
        @click="unlinkIssue"
      />
      <Button
        ghost
        xs
        slate
        class="!transition-none"
        icon="i-lucide-arrow-up-right"
        @click="openIssue"
      />
    </div>
  </div>
</template>
