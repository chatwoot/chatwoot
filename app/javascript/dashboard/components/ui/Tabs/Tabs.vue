<script setup>
import { ref, provide, onMounted, computed } from 'vue';
import { useEventListener } from '@vueuse/core';

const props = defineProps({
  index: {
    type: Number,
    default: 0,
  },
  border: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['change']);

const hasScroll = ref(false);

const activeIndex = computed({
  get: () => props.index,
  set: newValue => {
    emit('change', newValue);
  },
});

provide('activeIndex', activeIndex);
provide('updateActiveIndex', index => {
  activeIndex.value = index;
});

const computeScrollWidth = () => {
  // TODO: use useElementSize from vueuse
  const tabElement = document.querySelector('.tabs');
  if (tabElement) {
    hasScroll.value = tabElement.scrollWidth > tabElement.clientWidth;
  }
};

const onScrollClick = direction => {
  // TODO: use useElementSize from vueuse
  const tabElement = document.querySelector('.tabs');
  if (tabElement) {
    let scrollPosition = tabElement.scrollLeft;
    scrollPosition += direction === 'left' ? -100 : 100;
    tabElement.scrollTo({
      top: 0,
      left: scrollPosition,
      behavior: 'smooth',
    });
  }
};

useEventListener(window, 'resize', computeScrollWidth);
onMounted(() => {
  computeScrollWidth();
});
</script>

<template>
  <div
    :class="{ 'tabs--container--with-border': border }"
    class="tabs--container"
  >
    <button
      v-if="hasScroll"
      class="tabs--scroll-button button clear secondary button--only-icon"
      @click="onScrollClick('left')"
    >
      <fluent-icon icon="chevron-left" :size="16" />
    </button>
    <ul :class="{ 'tabs--with-scroll': hasScroll }" class="tabs">
      <slot />
    </ul>
    <button
      v-if="hasScroll"
      class="tabs--scroll-button button clear secondary button--only-icon"
      @click="onScrollClick('right')"
    >
      <fluent-icon icon="chevron-right" :size="16" />
    </button>
  </div>
</template>
