<script setup>
import { ref } from 'vue';
import GroupedStackedChangelogCard from './GroupedStackedChangelogCard.vue';

const sampleCards = [
  {
    id: 'chatwoot-captain',
    title: 'Chatwoot Captain',
    meta_title: 'Chatwoot Captain',
    meta_description:
      'Watch how our latest feature can transform your workflow with powerful automation tools.',
    slug: 'chatwoot-captain',
    feature_image:
      'https://www.chatwoot.com/images/captain/captain_thumbnail.jpg',
  },
  {
    id: 'smart-routing',
    title: 'Smart Routing Forms',
    meta_title: 'Smart Routing Forms',
    meta_description:
      'Screen bookers with intelligent forms and route them to the right team member.',
    slug: 'smart-routing',
    feature_image: 'https://www.chatwoot.com/images/dashboard-dark.webp',
  },
  {
    id: 'instant-meetings',
    title: 'Instant Meetings',
    meta_title: 'Instant Meetings',
    meta_description: 'Start instant meetings directly from shared links.',
    slug: 'instant-meetings',
    feature_image:
      'https://images.unsplash.com/photo-1587614382346-4ec70e388b28?w=600',
  },
  {
    id: 'analytics',
    title: 'Advanced Analytics',
    meta_title: 'Advanced Analytics',
    meta_description:
      'Track meeting performance, conversion, and response rates in one place.',
    slug: 'analytics',
    feature_image:
      'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=500',
  },
  {
    id: 'team-collaboration',
    title: 'Team Collaboration',
    meta_title: 'Team Collaboration',
    meta_description:
      'Coordinate with your team seamlessly using shared availability.',
    slug: 'team-collaboration',
    feature_image:
      'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=400',
  },
];

const visibleCards = ref([...sampleCards]);
const currentIndex = ref(0);
const dismissingCards = ref([]);

const handleReadMore = slug => {
  console.log(`Read more: ${slug}`);
};

const handleDismiss = slug => {
  dismissingCards.value.push(slug);
  setTimeout(() => {
    const idx = visibleCards.value.findIndex(c => c.slug === slug);
    if (idx !== -1) visibleCards.value.splice(idx, 1);
    dismissingCards.value = dismissingCards.value.filter(s => s !== slug);
    if (currentIndex.value >= visibleCards.value.length) currentIndex.value = 0;
  }, 200);
};

const handleImgClick = data => {
  currentIndex.value = data.index;
  console.log(`Card clicked: ${visibleCards.value[data.index].title}`);
};

const resetDemo = () => {
  visibleCards.value = [...sampleCards];
  currentIndex.value = 0;
  dismissingCards.value = [];
};
</script>

<template>
  <Story
    title="Components/ChangelogCard/GroupedStackedChangelogCard"
    :layout="{ type: 'grid', width: '320px' }"
  >
    <Variant title="Interactive Demo">
      <div class="p-4 bg-n-solid-2 rounded-md mx-auto w-64 h-[400px]">
        <GroupedStackedChangelogCard
          :posts="visibleCards"
          :current-index="currentIndex"
          :is-active="currentIndex === 0"
          :dismissing-slugs="dismissingCards"
          class="min-h-[270px]"
          @read-more="handleReadMore"
          @dismiss="handleDismiss"
          @img-click="handleImgClick"
        />

        <button
          class="mt-3 px-3 py-1 text-xs font-medium bg-n-brand text-white rounded hover:bg-n-brand/80 transition"
          @click="resetDemo"
        >
          <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
          {{ 'Reset Cards' }}
        </button>
      </div>
    </Variant>
  </Story>
</template>
