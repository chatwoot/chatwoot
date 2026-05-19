<script setup>
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

// Renders a portal's logo consistently across the help center — the layout
// header, the portal switcher, and portal settings — so the icon fallback
// and shape stay in one place instead of being copied per call site.
defineProps({
  src: { type: String, default: '' },
  name: { type: String, default: '' },
  size: { type: Number, default: 24 },
  allowUpload: { type: Boolean, default: false },
});

const emit = defineEmits(['upload', 'delete']);
</script>

<template>
  <Avatar
    :src="src"
    :name="name"
    :size="size"
    :allow-upload="allowUpload"
    icon-name="i-lucide-building-2"
    @upload="emit('upload', $event)"
    @delete="emit('delete')"
  />
</template>
