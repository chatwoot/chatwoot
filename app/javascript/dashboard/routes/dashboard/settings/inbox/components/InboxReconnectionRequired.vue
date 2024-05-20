<script setup>
defineProps({
  actionUrl: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div
    class="flex items-center gap-2 px-4 py-3 text-sm text-white bg-red-500 rounded-md dark:bg-red-800/30 dark:text-red-50 min-h-10"
  >
    <fluent-icon icon="error-circle" class="text-white dark:text-red-50" />
    <slot>
      <span v-html="$t('INBOX_MGMT.RECONNECTION_REQUIRED', { actionUrl })" />
    </slot>
  </div>
</template>
