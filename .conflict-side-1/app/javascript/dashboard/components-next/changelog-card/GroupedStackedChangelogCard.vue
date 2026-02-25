<script setup>
import { computed } from 'vue';
import StackedChangelogCard from './StackedChangelogCard.vue';

const props = defineProps({
  posts: {
    type: Array,
    required: true,
  },
  currentIndex: {
    type: Number,
    default: 0,
  },
  dismissingSlugs: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['readMore', 'dismiss', 'imgClick']);

const stackedPosts = computed(() => props.posts?.slice(0, 5));

const isPostDismissing = post => props.dismissingSlugs.includes(post.slug);

const handleReadMore = post => emit('readMore', post.slug);
const handleDismiss = post => emit('dismiss', post.slug);
const handlePostClick = (post, index) => {
  if (index === props.currentIndex && !isPostDismissing(post)) {
    emit('imgClick', { slug: post.slug, index });
  }
};

const getCardClasses = index => {
  const pos =
    (index - props.currentIndex + stackedPosts.value.length) %
    stackedPosts.value.length;
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
    <div class="relative grid grid-cols-1 pt-8 pb-1 px-2">
      <div
        v-for="(post, index) in stackedPosts"
        :key="post.slug || index"
        :class="getCardClasses(index)"
      >
        <StackedChangelogCard
          :card="post"
          :is-active="index === currentIndex"
          :is-dismissing="isPostDismissing(post)"
          @read-more="handleReadMore(post)"
          @dismiss="handleDismiss(post)"
          @img-click="handlePostClick(post, index)"
        />
      </div>
    </div>
  </div>
</template>
