<script setup>
import { computed, inject } from 'vue';

const props = defineProps({
  index: {
    type: Number,
    default: 0,
  },
  name: {
    type: String,
    required: true,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  count: {
    type: Number,
    default: 0,
  },
  showBadge: {
    type: Boolean,
    default: true,
  },
  icon: {
    type: String,
    default: '',
  },
});

const activeIndex = inject('activeIndex');
const updateActiveIndex = inject('updateActiveIndex');

const active = computed(() => props.index === activeIndex.value);
const getItemCount = computed(() => props.count);

const onTabClick = event => {
  event.preventDefault();
  if (!props.disabled) {
    updateActiveIndex(props.index);
  }
};
</script>

<template>
  <li
    class="tabs-title flex items-center gap-2"
    :class="{
      'is-active': active,
    }"
  >
    <div>
      <fluent-icon
        v-if="!!props.icon"
        size="18"
        type="outline"
        :icon="icon"
        viewBox="0 0 18 18"
        class="icon w-6 h-6 ml-1 mt-1"
        :class="{
          'text-woot-500': active,
          'text-gray-400': !active,
        }"
      />
    </div>
    <a @click="onTabClick">
      {{ name }}
      <div v-if="showBadge" class="badge min-w-[20px]">
        <span>
          {{ getItemCount }}
        </span>
      </div>
    </a>
  </li>
</template>
