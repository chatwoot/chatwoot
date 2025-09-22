<script setup>
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

const unlinkIssue = () => {
  emit('unlinkIssue');
};

const openIssue = () => {
  window.open(props.issueUrl, '_blank');
};
</script>

<template>
  <div class="flex items-center justify-between">
    <div
      class="flex items-center gap-2 px-2 py-1.5 border rounded-lg border-n-strong"
    >
      <div class="flex items-center gap-1">
        <fluent-icon
          icon="linear"
          size="16"
          class="text-[#5E6AD2]"
          view-box="0 0 19 19"
        />
        <span class="text-xs font-medium text-n-slate-12">
          {{ identifier }}
        </span>
      </div>
      <span class="w-px h-3 text-n-weak bg-n-weak" />

      <Button
        link
        xs
        slate
        icon="i-lucide-arrow-up-right"
        class="!size-4"
        @click="openIssue"
      />
    </div>

    <Button ghost xs slate icon="i-lucide-unlink" @click="unlinkIssue" />
  </div>
</template>
