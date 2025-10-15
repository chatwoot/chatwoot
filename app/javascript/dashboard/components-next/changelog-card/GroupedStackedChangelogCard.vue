<script setup>
import { computed } from 'vue';
import StackedChangelogCard from './StackedChangelogCard.vue';

const props = defineProps({
  cards: {
    type: Array,
    required: true,
  },
  currentIndex: {
    type: Number,
    default: 0,
  },
  dismissingCards: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['readMore', 'dismiss', 'cardClick']);

const stackedCards = computed(() => props.cards?.slice(0, 5));

const isCardDismissing = card => props.dismissingCards.includes(card.slug);

const handleReadMore = card => emit('readMore', card.slug);
const handleDismiss = card => emit('dismiss', card.slug);
const handleCardClick = (card, index) => {
  if (index !== props.currentIndex && !isCardDismissing(card)) {
    emit('cardClick', { slug: card.slug, index });
  }
};

const getCardClasses = index => {
  const pos =
    (index - props.currentIndex + stackedCards.value.length) %
    stackedCards.value.length;
  const base =
    'relative transition-all duration-500 ease-out col-start-1 row-start-1';

  const layers = [
    'z-50 scale-100 translate-y-0 opacity-100',
    'z-40 scale-[0.95] -translate-y-3 opacity-90',
    'z-30 scale-[0.9] -translate-y-6 opacity-70',
    'z-20 scale-[0.85] -translate-y-9 opacity-50',
    'z-10 scale-[0.8] -translate-y-12 opacity-30',
  ];

  return pos < layers.length
    ? `${base} ${layers[pos]}`
    : `${base} opacity-0 scale-75 -translate-y-16`;
};
</script>

<template>
  <div class="overflow-hidden">
    <div class="hidden relative grid-cols-1 pt-8 pb-2 lg:grid">
      <div
        v-for="(card, index) in stackedCards"
        :key="card.slug || index"
        :class="getCardClasses(index)"
      >
        <StackedChangelogCard
          :card="card"
          :show-actions="index === currentIndex"
          :show-media="index === currentIndex"
          :is-dismissing="isCardDismissing(card)"
          @read-more="handleReadMore(card)"
          @dismiss="handleDismiss(card)"
          @card-click="handleCardClick(card, index)"
        />
      </div>
    </div>
  </div>
</template>
