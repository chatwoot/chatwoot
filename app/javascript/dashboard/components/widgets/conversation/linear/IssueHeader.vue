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
    <div class="flex items-center gap-0.5">
      <woot-button
        variant="clear"
        color-scheme="secondary"
        class="h-[24px]"
        :is-loading="isUnlinking"
        @click="unlinkIssue"
      >
        <fluent-icon
          v-if="!isUnlinking"
          icon="unlink"
          size="12"
          type="outline"
          icon-lib="lucide"
        />
      </woot-button>
      <woot-button
        variant="clear"
        class="h-[24px]"
        color-scheme="secondary"
        @click="openIssue"
      >
        <fluent-icon icon="arrow-up-right" size="14" />
      </woot-button>
    </div>
  </div>
</template>

<script setup>
import { inject } from 'vue';
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

const isUnlinking = inject('isUnlinking');

const emit = defineEmits(['unlink-issue']);

const unlinkIssue = () => {
  emit('unlink-issue');
};

const openIssue = () => {
  window.open(props.issueUrl, '_blank');
};
</script>
