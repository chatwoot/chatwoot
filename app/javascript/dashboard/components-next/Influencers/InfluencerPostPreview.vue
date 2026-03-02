<script setup>
import { computed } from 'vue';
import InfluencerProfilesAPI from 'dashboard/api/influencerProfiles';

const props = defineProps({
  post: { type: Object, required: true },
});

const thumbnailSrc = computed(() => {
  if (!props.post.thumbnail_url) return null;
  return InfluencerProfilesAPI.proxyImageUrl(props.post.thumbnail_url);
});

const formattedLikes = computed(() => {
  const likes = props.post.likes || 0;
  if (likes >= 1000000) return `${(likes / 1000000).toFixed(1)}M`;
  if (likes >= 1000) return `${(likes / 1000).toFixed(1)}K`;
  return likes;
});
</script>

<template>
  <a
    :href="post.url"
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
      <span class="i-lucide-image size-8" />
    </div>
    <div
      v-if="post.type === 'carousel_container'"
      class="absolute right-1.5 top-1.5"
    >
      <span class="i-lucide-layers size-4 text-white drop-shadow-lg" />
    </div>
    <div
      class="stats-overlay absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/60 to-transparent p-2 opacity-0 transition-opacity"
    >
      <div class="flex gap-2 text-xs text-white">
        <span v-if="post.likes" class="flex items-center gap-0.5">
          <span class="i-lucide-heart size-3" />
          {{ formattedLikes }}
        </span>
        <span v-if="post.comments" class="flex items-center gap-0.5">
          <span class="i-lucide-message-circle size-3" />
          {{ post.comments }}
        </span>
      </div>
    </div>
  </a>
</template>
