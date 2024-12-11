<script setup>
import Avatar from '../avatar/Avatar.vue';

defineProps({
  message: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <div class="flex flex-row gap-2">
    <Avatar
      name="Captain Copilot"
      icon-name="i-woot-captain"
      :size="24"
      rounded-full
    />
    <div class="flex flex-col gap-1 text-n-slate-12">
      <div class="font-medium">{{ $t('CAPTAIN.NAME') }}</div>
      <div class="break-words">
        {{ message.content }}
      </div>
    </div>
  </div>
</template>
