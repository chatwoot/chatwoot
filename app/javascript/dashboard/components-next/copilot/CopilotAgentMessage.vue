<script setup>
defineProps({
  message: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <div class="space-y-1 text-on-surface">
    <div
      class="text-xs font-semibold uppercase tracking-wider text-on-surface-variant"
    >
      {{ $t('CAPTAIN.COPILOT.YOU') }}
    </div>
    <div
      class="rounded-xl rounded-tr-sm border border-outline-variant/15 bg-secondary/15 px-3 py-2 text-sm break-words text-on-surface"
    >
      {{ message.content }}
    </div>
  </div>
</template>
