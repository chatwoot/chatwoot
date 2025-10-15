<script setup>
import { ref } from 'vue';
import GroupedStackedChangelogCard from './GroupedStackedChangelogCard.vue';

const sampleCards = [
  {
    id: 'chatwoot-captain',
    title: 'Chatwoot Captain',
    slug: 'chatwoot-captain',
    description:
      'Watch how our latest feature can transform your workflow with powerful automation tools.',
    media: {
      type: 'image',
      src: 'https://www.chatwoot.com/images/captain/captain_thumbnail.jpg',
      alt: 'Chatwoot Captain demo image',
    },
  },
  {
    id: 'smart-routing',
    title: 'Smart Routing Forms',
    slug: 'smart-routing',
    description:
      'Screen bookers with intelligent forms and route them to the right team member.',
    media: {
      type: 'video',
      src: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      poster:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerFun.jpg',
      alt: 'Routing forms demo video',
    },
  },
  {
    id: 'instant-meetings',
    title: 'Instant Meetings',
    slug: 'instant-meetings',
    description: 'Start instant meetings directly from shared links.',
    media: {
      type: 'image',
      src: 'https://images.unsplash.com/photo-1587614382346-4ec70e388b28?w=600',
      alt: 'Instant meetings UI preview',
    },
  },
  {
    id: 'analytics',
    title: 'Advanced Analytics',
    slug: 'analytics',
    description:
      'Track meeting performance, conversion, and response rates in one place.',
    media: {
      type: 'video',
      src: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      poster:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg',
      alt: 'Analytics dashboard video preview',
    },
  },
  {
    id: 'team-collaboration',
    title: 'Team Collaboration',
    slug: 'team-collaboration',
    description:
      'Coordinate with your team seamlessly using shared availability.',
    media: {
      type: 'image',
      src: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=600',
      alt: 'Team collaboration meeting view',
    },
  },
];

const visibleCards = ref([...sampleCards]);
const currentIndex = ref(0);
const dismissingCards = ref([]);

const handlePrimaryAction = slug => {
  const card = visibleCards.value.find(c => c.slug === slug);
  console.log(`Primary action: ${card?.title}`);
};

const handleSecondaryAction = slug => {
  dismissingCards.value.push(slug);
  setTimeout(() => {
    const idx = visibleCards.value.findIndex(c => c.slug === slug);
    if (idx !== -1) visibleCards.value.splice(idx, 1);
    dismissingCards.value = dismissingCards.value.filter(s => s !== slug);
    if (currentIndex.value >= visibleCards.value.length) currentIndex.value = 0;
  }, 200);
};

const handleCardClick = index => {
  currentIndex.value = index;
  console.log(`Card clicked: ${visibleCards.value[index].title}`);
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
          :cards="visibleCards"
          :current-index="currentIndex"
          :dismissing-cards="dismissingCards"
          class="min-h-[200px]"
          @primary-action="handlePrimaryAction"
          @secondary-action="handleSecondaryAction"
          @card-click="handleCardClick"
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
