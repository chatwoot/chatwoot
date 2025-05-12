<script setup>
defineProps({
  message: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <div class="flex flex-row gap-2">
    <div class="space-y-1">
      <div class="font-medium text-n-slate-12">
        {{ $t('CAPTAIN.COPILOT.YOU') }}
      </div>
      <div class="break-words text-n-slate-11">
        {{ message.content }}
      </div>
    </div>
  </div>
</template>
