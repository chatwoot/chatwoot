<script setup>
defineProps({
  src: {
    type: String,
    required: true,
  },
  poster: {
    type: String,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <figure class="overflow-hidden rounded-xl border border-n-weak">
    <video
      class="block w-full bg-n-solid-1"
      controls
      muted
      playsinline
      preload="metadata"
      :poster="poster"
      :aria-label="title"
    >
      <source :src="src" type="video/mp4" />
    </video>
    <figcaption class="border-t border-n-weak bg-n-slate-1 px-4 py-3">
      <p class="text-sm font-medium text-n-slate-12">{{ title }}</p>
      <p class="mt-1 text-xs text-n-slate-11">{{ description }}</p>
    </figcaption>
  </figure>
</template>
