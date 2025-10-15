<script setup>
import { ref, computed, onMounted } from 'vue';
import GroupedStackedChangelogCard from 'dashboard/components-next/changelog-card/GroupedStackedChangelogCard.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import changelogAPI from 'dashboard/api/changelog';

const MAX_DISMISSED_SLUGS = 5;

const { uiSettings, updateUISettings } = useUISettings();
const posts = ref([]);
const currentIndex = ref(0);
const dismissingCards = ref([]);
const isLoading = ref(false);
const error = ref(null);

// Get current dismissed slugs from ui_settings
const dismissedSlugs = computed(() => {
  return uiSettings.value.changelog_dismissed_slugs || [];
});

// Get undismissed posts - pass them directly without transformation
const visibleCards = computed(() => {
  return posts.value.filter(post => !dismissedSlugs.value.includes(post.slug));
});

// Fetch changelog posts from API
const fetchChangelog = async () => {
  isLoading.value = true;
  error.value = null;

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
  } catch (err) {
    error.value = err;
    // eslint-disable-next-line no-console
    console.error('Failed to fetch changelog:', err);
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

const handlePrimaryAction = () => {
  const currentCard = visibleCards.value[currentIndex.value];
  if (currentCard?.url) {
    window.open(currentCard.url, '_blank');
  }
};

const handleSecondaryAction = slug => {
  dismissingCards.value.push(slug);
  setTimeout(() => {
    dismissPost(slug);
    dismissingCards.value = dismissingCards.value.filter(s => s !== slug);
    if (currentIndex.value >= visibleCards.value.length) currentIndex.value = 0;
  }, 200);
};

const handleCardClick = () => {
  const currentCard = visibleCards.value[currentIndex.value];
  if (currentCard?.url) {
    window.open(currentCard.url, '_blank');
  }
};

onMounted(() => {
  fetchChangelog();
});
</script>

<template>
  <div v-if="visibleCards.length > 0" class="px-2 pt-1">
    <GroupedStackedChangelogCard
      :cards="visibleCards"
      :current-index="currentIndex"
      :dismissing-cards="dismissingCards"
      class="min-h-[240px]"
      @primary-action="handlePrimaryAction"
      @secondary-action="handleSecondaryAction"
      @card-click="handleCardClick"
    />
  </div>
  <template v-else />
</template>
