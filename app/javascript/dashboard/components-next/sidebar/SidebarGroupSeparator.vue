<script setup>
import Icon from 'next/icon/Icon.vue';
import SidebarSortMenu from './SidebarSortMenu.vue';

defineProps({
  collapsible: {
    type: Boolean,
    default: false,
  },
  isExpanded: {
    type: Boolean,
    default: true,
  },
  label: {
    type: String,
    default: '',
  },
  icon: {
    type: [Object, String],
    default: '',
  },
  sortOptions: {
    type: Array,
    default: () => [],
  },
  activeSort: {
    type: String,
    default: '',
  },
  showTreeLine: {
    type: Boolean,
    default: false,
  },
  endTreeLine: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['toggle', 'update-sort']);

const TREE_VERTICAL_LINE =
  "before:content-[''] before:absolute before:-top-1 before:w-0.5 before:bg-n-slate-4 before:start-[-0.5rem]";
const TREE_ELBOW =
  "after:content-[''] after:absolute after:w-2.5 after:h-3 after:bottom-1/2 after:start-[-0.5rem] after:border-b-2 after:border-s-2 after:rounded-es after:border-n-slate-4";
</script>

<template>
  <div class="relative min-w-0" :class="{ 'ms-5': collapsible }">
    <component
      :is="collapsible ? 'button' : 'div'"
      :type="collapsible ? 'button' : undefined"
      :aria-expanded="collapsible ? isExpanded : undefined"
      :title="label"
      class="relative flex h-8 w-full min-w-0 items-center justify-between gap-2 rounded-lg px-2 py-1.5 text-n-slate-10 select-none"
      :class="[
        showTreeLine && TREE_VERTICAL_LINE,
        showTreeLine &&
          (endTreeLine ? `before:h-3 ${TREE_ELBOW}` : 'before:-bottom-1'),
        {
          'pointer-events-none': !collapsible,
          'cursor-pointer hover:bg-n-alpha-2': collapsible,
          'pe-14': collapsible && sortOptions.length,
          'pe-8': collapsible && !sortOptions.length,
          'pe-10': !collapsible && sortOptions.length,
        },
      ]"
      @click.stop="collapsible ? emit('toggle') : undefined"
    >
      <div class="inline-flex min-w-0 items-center gap-2">
        <Icon v-if="icon" :icon="icon" class="size-4 flex-shrink-0" />
        <span
          class="flex-grow truncate text-start text-sm font-medium leading-5"
        >
          {{ label }}
        </span>
      </div>
    </component>
    <div
      v-if="collapsible || sortOptions.length"
      class="absolute end-2 top-1/2 flex -translate-y-1/2 items-center gap-1"
    >
      <SidebarSortMenu
        v-if="sortOptions.length"
        :active-sort="activeSort"
        :options="sortOptions"
        @sort="sortBy => emit('update-sort', sortBy)"
      />
      <button
        v-if="collapsible"
        type="button"
        class="flex size-6 flex-shrink-0 items-center justify-center rounded-md text-n-slate-10 hover:bg-n-alpha-2 focus-visible:bg-n-alpha-2 focus-visible:outline-none"
        :aria-expanded="isExpanded"
        :aria-label="label"
        @click.stop="emit('toggle')"
      >
        <span
          class="size-3 flex-shrink-0"
          :class="isExpanded ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        />
      </button>
    </div>
  </div>
</template>
