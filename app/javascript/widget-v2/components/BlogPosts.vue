<script setup>
import { computed } from 'vue';
import { isWebUrl } from 'widget-v2/helpers/urlHelpers';
import HomeSection from 'widget-v2/components/HomeSection.vue';

const props = defineProps({
  posts: { type: Array, required: true },
});

const validPosts = computed(() =>
  props.posts.filter(post => post.title && isWebUrl(post.url)).slice(0, 4)
);
</script>

<template>
  <HomeSection v-if="validPosts.length" :label="$t('HOME.LATEST_POSTS')">
    <a
      v-for="post in validPosts"
      :key="post.url"
      :href="post.url"
      target="_blank"
      rel="noreferrer noopener"
      class="group flex items-center gap-3 row-pad rounded-token-sm transition-colors hover:bg-cw-surface outline-none focus-visible:ring-[3px] focus-visible:ring-inset focus-visible:ring-cw-ring"
    >
      <img
        v-if="isWebUrl(post.image)"
        :src="post.image"
        alt=""
        class="w-10 h-10 shrink-0 rounded-token-sm object-cover bg-cw-muted"
      />
      <span
        v-else
        class="flex items-center justify-center w-10 h-10 shrink-0 rounded-token-sm bg-cw-muted text-cw-text-muted"
      >
        <span class="i-ph-newspaper text-sm" />
      </span>
      <span class="flex-1 min-w-0">
        <span class="block text-sm font-520 text-cw-text truncate">
          {{ post.title }}
        </span>
        <span
          v-if="post.description"
          class="block mt-0.5 text-xs text-cw-text-muted truncate"
        >
          {{ post.description }}
        </span>
      </span>
      <span
        class="i-ph-arrow-square-out shrink-0 text-cw-text-faint transition-transform group-hover:translate-x-0.5"
      />
    </a>
  </HomeSection>
</template>
