<script setup>
import { computed } from 'vue';
import InfluencerProfilesAPI from 'dashboard/api/influencerProfiles';

const props = defineProps({
  reel: { type: Object, required: true },
});

const thumbnailSrc = computed(() => {
  if (!props.reel.thumbnail_url) return null;
  return InfluencerProfilesAPI.proxyImageUrl(props.reel.thumbnail_url);
});

const formattedViews = computed(() => {
  const views = props.reel.views || 0;
  if (views >= 1000000) return `${(views / 1000000).toFixed(1)}M`;
  if (views >= 1000) return `${(views / 1000).toFixed(1)}K`;
  return views;
});
</script>

<template>
  <a
    :href="reel.url"
    target="_blank"
    rel="noopener noreferrer"
    class="relative block aspect-square overflow-hidden rounded-lg bg-n-background [&:hover_.stats-overlay]:opacity-100"
  >
    <img
      v-if="thumbnailSrc"
      :src="thumbnailSrc"
      class="size-full object-cover"
      loading="lazy"
      @error="$event.target.style.display = 'none'"
    />
    <div
      v-else
      class="flex size-full items-center justify-center text-n-slate-9"
    >
      <span class="i-lucide-film size-8" />
    </div>
    <div
      class="stats-overlay absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/60 to-transparent p-2 opacity-0 transition-opacity"
    >
      <div class="flex gap-2 text-xs text-white">
        <span v-if="reel.views" class="flex items-center gap-0.5">
          <span class="i-lucide-play size-3" />
          {{ formattedViews }}
        </span>
        <span v-if="reel.likes" class="flex items-center gap-0.5">
          <span class="i-lucide-heart size-3" />
          {{ reel.likes }}
        </span>
      </div>
    </div>
  </a>
</template>
