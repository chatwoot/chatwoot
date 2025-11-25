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
  isCompact: {
    type: Boolean,
    default: false,
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
    class="flex-shrink-0 my-0 mx-2 ltr:first:ml-0 rtl:first:mr-0 ltr:last:mr-0 rtl:last:ml-0 hover:text-n-slate-12"
  >
    <a
      class="flex items-center flex-row border-b select-none cursor-pointer text-sm relative top-[1px] transition-[border-color] duration-[150ms] ease-[cubic-bezier(0.37,0,0.63,1)]"
      :class="[
        active
          ? 'border-b border-n-brand text-n-blue-11'
          : 'border-transparent text-n-slate-11',
        isCompact ? 'py-2 text-sm' : 'text-base py-3',
      ]"
      @click="onTabClick"
    >
      {{ name }}
      <div
        v-if="showBadge"
        class="rounded-full h-5 flex items-center justify-center text-xxs font-semibold my-0 mx-1 px-1.5 py-0 min-w-[20px]"
        :class="[
          active
            ? 'bg-n-blue-3 text-n-blue-11'
            : 'bg-n-alpha-1 text-n-slate-10',
        ]"
      >
        <span>
          {{ getItemCount }}
        </span>
      </div>
    </a>
  </li>
</template>
