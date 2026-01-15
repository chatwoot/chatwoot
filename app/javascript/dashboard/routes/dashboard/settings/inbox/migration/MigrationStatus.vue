<script setup>
import { computed } from 'vue';

const props = defineProps({
  migration: {
    type: Object,
    required: true,
  },
});

const progressPercentage = computed(() => {
  return props.migration.progress?.percentage || 0;
});

const statusColor = computed(() => {
  switch (props.migration.status) {
    case 'completed':
      return 'jade';
    case 'failed':
      return 'ruby';
    case 'running':
      return 'blue';
    case 'queued':
      return 'slate';
    case 'cancelled':
      return 'amber';
    default:
      return 'slate';
  }
});

const statusIcon = computed(() => {
  switch (props.migration.status) {
    case 'completed':
      return '✓';
    case 'failed':
      return '✕';
    case 'running':
      return '⟳';
    case 'queued':
      return '⏳';
    case 'cancelled':
      return '⊘';
    default:
      return '•';
  }
});
</script>

<template>
  <div
    class="p-4 rounded-lg border"
    :class="{
      'bg-n-jade-2 border-n-jade-6': statusColor === 'jade',
      'bg-n-ruby-2 border-n-ruby-6': statusColor === 'ruby',
      'bg-n-blue-2 border-n-blue-6': statusColor === 'blue',
      'bg-n-slate-2 border-n-slate-6': statusColor === 'slate',
      'bg-n-amber-2 border-n-amber-6': statusColor === 'amber',
    }"
  >
    <!-- Header -->
    <div class="flex items-center justify-between mb-3">
      <div class="flex items-center gap-2">
        <span class="text-lg">{{ statusIcon }}</span>
        <h3
          class="text-sm font-semibold"
          :class="{
            'text-n-jade-11': statusColor === 'jade',
            'text-n-ruby-11': statusColor === 'ruby',
            'text-n-blue-11': statusColor === 'blue',
            'text-n-slate-11': statusColor === 'slate',
            'text-n-amber-11': statusColor === 'amber',
          }"
        >
          {{
            $t(`INBOX_MGMT.MIGRATION.STATUS.${migration.status.toUpperCase()}`)
          }}
        </h3>
      </div>
      <!-- eslint-disable-next-line vue/no-bare-strings-in-template -->
      <span
        class="text-xs"
        :class="{
          'text-n-jade-11': statusColor === 'jade',
          'text-n-ruby-11': statusColor === 'ruby',
          'text-n-blue-11': statusColor === 'blue',
          'text-n-slate-11': statusColor === 'slate',
          'text-n-amber-11': statusColor === 'amber',
        }"
      >
        {{ progressPercentage }}%
      </span>
    </div>

    <!-- Progress Bar -->
    <div
      v-if="migration.status === 'running' || migration.status === 'queued'"
      class="mb-3"
    >
      <div class="h-2 rounded-full bg-n-alpha-3">
        <div
          class="h-full rounded-full transition-all duration-500"
          :class="{
            'bg-n-blue-9': statusColor === 'blue',
            'bg-n-slate-9': statusColor === 'slate',
          }"
          :style="{ width: `${progressPercentage}%` }"
        />
      </div>
    </div>

    <!-- Details -->
    <div class="text-xs space-y-1">
      <!-- eslint-disable vue/no-bare-strings-in-template -->
      <p class="text-n-slate-11">
        {{ migration.source_inbox.name }} →
        {{ migration.destination_inbox.name }}
      </p>
      <!-- eslint-enable vue/no-bare-strings-in-template -->
      <p v-if="migration.progress" class="text-n-slate-11">
        {{
          $t('INBOX_MGMT.MIGRATION.STATUS.PROGRESS_DETAIL', {
            conversations: migration.progress.conversations.moved,
            totalConversations: migration.progress.conversations.total,
            messages: migration.progress.messages.moved,
            totalMessages: migration.progress.messages.total,
          })
        }}
      </p>
      <p
        v-if="
          migration.timing.duration_seconds && migration.status === 'completed'
        "
        class="text-n-slate-11"
      >
        {{
          $t('INBOX_MGMT.MIGRATION.STATUS.DURATION', {
            seconds: migration.timing.duration_seconds,
          })
        }}
      </p>
      <p v-if="migration.error" class="text-n-ruby-11">
        {{ migration.error }}
      </p>
    </div>
  </div>
</template>
