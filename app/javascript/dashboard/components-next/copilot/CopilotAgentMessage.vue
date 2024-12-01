<script setup>
import Avatar from '../avatar/Avatar.vue';

defineProps({
  message: {
    type: Object,
    required: true,
  },
  supportAgent: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <div class="flex flex-row gap-3">
    <Avatar
      :name="supportAgent.name"
      :src="supportAgent.thumbnail"
      :size="28"
      rounded-full
    />
    <div class="space-y-2">
      <div class="font-medium">{{ $t('CAPTAIN.COPILOT.YOU') }}</div>
      <div class="break-words">
        {{ message.content }}
      </div>
    </div>
  </div>
</template>
