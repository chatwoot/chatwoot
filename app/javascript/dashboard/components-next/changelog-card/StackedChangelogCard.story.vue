<script setup>
import StackedChangelogCard from './StackedChangelogCard.vue';

const imageCards = {
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
};

const videoCards = {
  id: 'chatwoot-captain-preview',
  title: 'Chatwoot Captain Preview',
  slug: 'chatwoot-captain-preview',
  description:
    'Watch how our latest feature can transform your workflow with powerful automation tools.',
  media: {
    type: 'video',
    src: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
    poster:
      'https://i.ytimg.com/an_webp/-c_xDMtoOG0/mqdefault_6s.webp?du=3000&sqp=CKrwvMcG&rs=AOn4CLCwHpsblr0TRE9yI7UuEY4aLyr8sw',
    alt: 'Chatwoot Captain demo video',
  },
};

const handlePrimaryAction = data => {
  console.log('Primary action clicked:', data);
  console.log(`Primary action: ${data.card.title}`);
};

const handleSecondaryAction = data => {
  console.log('Secondary action clicked:', data);
  console.log(`Dismissed: ${data.card.title}`);
};

const handleCardClick = data => {
  console.log('Card clicked:', data);
  console.log(`Card clicked: ${data.card.title}`);
};
</script>

<template>
  <Story
    title="Components/ChangelogCard/StackedChangelogCard"
    :layout="{ type: 'grid', width: '260px' }"
  >
    <Variant title="Single Card - With Image">
      <div class="p-3 bg-n-solid-2 w-56">
        <StackedChangelogCard
          :card="imageCards"
          is-active
          show-actions
          show-media
          @primary-action="handlePrimaryAction"
          @secondary-action="handleSecondaryAction"
          @card-click="handleCardClick"
        />
      </div>
    </Variant>

    <Variant title="Single Card - With Video">
      <div class="p-3 bg-n-solid-2 w-56">
        <StackedChangelogCard
          :card="videoCards"
          is-active
          show-actions
          show-media
          @primary-action="handlePrimaryAction"
          @secondary-action="handleSecondaryAction"
          @card-click="handleCardClick"
        />
      </div>
    </Variant>
  </Story>
</template>
