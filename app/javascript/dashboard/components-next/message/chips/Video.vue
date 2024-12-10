<script setup>
import Icon from 'next/icon/Icon.vue';
defineProps({
  attachment: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <div
    class="size-[72px] overflow-hidden contain-content rounded-xl cursor-pointer relative group"
  >
    <video
      :src="attachment.dataUrl"
      class="w-full h-full object-cover"
      muted
      playsInline
    />
    <div
      class="absolute w-full h-full inset-0 p-1 flex items-center justify-center"
    >
      <div
        class="size-7 bg-n-slate-1/60 backdrop-blur-sm rounded-full overflow-hidden shadow-[0_5px_15px_rgba(0,0,0,0.4)]"
      >
        <Icon
          icon="i-teenyicons-play-small-solid"
          class="size-7 text-n-slate-12/80 backdrop-blur"
        />
      </div>
    </div>
  </div>
</template>
