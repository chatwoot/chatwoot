<script setup>
import Avatar from 'next/avatar/Avatar.vue';
import MobileBackButton from './MobileBackButton.vue';

defineProps({
  name: {
    type: String,
    default: '',
  },
  avatar: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['back']);
</script>

<template>
  <header
    class="flex items-center gap-2 px-2 py-2 flex-shrink-0 bg-white dark:bg-n-background border-b border-n-weak pt-[env(safe-area-inset-top)]"
  >
    <MobileBackButton @click="emit('back')" />
    <Avatar
      :src="avatar"
      :name="name"
      :size="32"
      class="flex-shrink-0"
    />
    <h2 class="text-sm font-semibold text-n-slate-12 truncate">
      {{ name }}
    </h2>
  </header>
</template>
