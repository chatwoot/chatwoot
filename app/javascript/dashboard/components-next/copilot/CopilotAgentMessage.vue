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
  <div class="flex flex-row gap-2">
    <Avatar
      :name="supportAgent.available_name"
      :src="supportAgent.avatar_url"
      :size="24"
      rounded-full
    />
    <div class="space-y-1 text-n-slate-12">
      <div class="font-medium">{{ $t('CAPTAIN.COPILOT.YOU') }}</div>
      <div class="break-words">
        {{ message.content }}
      </div>
    </div>
  </div>
</template>
