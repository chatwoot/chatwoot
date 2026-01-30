<script setup>
import { ref, computed, onMounted } from 'vue';
import GroupedStackedChangelogCard from 'dashboard/components-next/changelog-card/GroupedStackedChangelogCard.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import changelogAPI from 'dashboard/api/changelog';

defineOptions({
  inheritAttrs: false,
});

const MAX_DISMISSED_SLUGS = 5;

const { uiSettings, updateUISettings } = useUISettings();
const posts = ref([]);
const currentIndex = ref(0);
const dismissingCards = ref([]);
const isLoading = ref(false);

// Get current dismissed slugs from ui_settings
const dismissedSlugs = computed(() => {
  return uiSettings.value.changelog_dismissed_slugs || [];
});

// Get un dismissed posts - these are the changelog posts that should be shown
const unDismissedPosts = computed(() => {
  return posts.value.filter(post => !dismissedSlugs.value.includes(post.slug));
});

// Fetch changelog posts from API
const fetchChangelog = async () => {
  isLoading.value = true;

  try {
    const response = await changelogAPI.fetchFromHub();
    posts.value = response.data.posts || [];

    // Clean up dismissed slugs - remove any that are no longer in the current feed
    const currentSlugs = posts.value.map(post => post.slug);
    const cleanedDismissedSlugs = dismissedSlugs.value.filter(slug =>
      currentSlugs.includes(slug)
    );

    // Update ui_settings if cleanup occurred
    if (cleanedDismissedSlugs.length !== dismissedSlugs.value.length) {
      updateUISettings({
        changelog_dismissed_slugs: cleanedDismissedSlugs,
      });
    }
    // eslint-disable-next-line no-empty
  } catch (err) {
  } finally {
    isLoading.value = false;
  }
};

// Dismiss a changelog post
const dismissPost = slug => {
  const currentDismissed = [...dismissedSlugs.value];

  // Add new slug if not already present
  if (!currentDismissed.includes(slug)) {
    currentDismissed.push(slug);

    // Keep only the most recent MAX_DISMISSED_SLUGS entries
    if (currentDismissed.length > MAX_DISMISSED_SLUGS) {
      currentDismissed.shift(); // Remove oldest entry
    }

    updateUISettings({
      changelog_dismissed_slugs: currentDismissed,
    });
  }
};

const handleDismiss = slug => {
  dismissingCards.value.push(slug);
  setTimeout(() => {
    dismissPost(slug);
    dismissingCards.value = dismissingCards.value.filter(s => s !== slug);
    if (currentIndex.value >= unDismissedPosts.value.length)
      currentIndex.value = 0;
  }, 200);
};

const handleReadMore = () => {
  const currentPost = unDismissedPosts.value[currentIndex.value];
  if (currentPost?.slug) {
    window.open(`https://www.chatwoot.com/blog/${currentPost.slug}`, '_blank');
  }
};

const handleImgClick = ({ index }) => {
  currentIndex.value = index;
  handleReadMore();
};

defineExpose({
  isLoading,
  unDismissedPosts,
});

onMounted(() => {
  fetchChangelog();
});
</script>

<template>
  <GroupedStackedChangelogCard
    v-if="unDismissedPosts.length > 0"
    v-bind="$attrs"
    :posts="unDismissedPosts"
    :current-index="currentIndex"
    :dismissing-slugs="dismissingCards"
    class="min-h-[240px] z-10"
    @read-more="handleReadMore"
    @dismiss="handleDismiss"
    @img-click="handleImgClick"
  />
  <template v-else />
</template>
