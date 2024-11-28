<script setup>
defineProps({
  attachment: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <div
    class="size-[72px] overflow-hidden contain-content rounded-xl cursor-pointer"
  >
    <img class="w-full h-full object-cover" :src="attachment.dataUrl" />
  </div>
</template>
