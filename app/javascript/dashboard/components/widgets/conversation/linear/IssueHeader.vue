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
      class="flex items-center divide-x divide-n-border-weak justify-center gap-2 h-[28px] px-2 align-center border rounded-lg border-n-strong"
    >
      <div class="flex items-center gap-1">
        <fluent-icon
          icon="linear"
          size="19"
          class="text-[#5E6AD2]"
          view-box="0 0 19 19"
        />
        <span class="text-xs font-medium text-n-slate-12">
          {{ identifier }}
        </span>
      </div>

      <span class="w-px h-3 text-n-weak bg-n-border-weak" />

      <Button
        link
        xs
        slate
        icon="i-lucide-arrow-up-right"
        class="!size-4"
        @click="openIssue"
      />
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
    </div>
  </div>
</template>
