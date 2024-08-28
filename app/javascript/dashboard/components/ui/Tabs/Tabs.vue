<script setup>
// [VITE] TODO: Test this component across different screen sizes and usages
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
// TODO: We may not this internalActiveIndex, we can use activeIndex directly
// But right I'll keep it and fix it when testing the rest of the codebase
const internalActiveIndex = ref(props.index);

// Create a proxy for activeIndex using computed
const activeIndex = computed({
  get: () => internalActiveIndex.value,
  set: newValue => {
    internalActiveIndex.value = newValue;
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
