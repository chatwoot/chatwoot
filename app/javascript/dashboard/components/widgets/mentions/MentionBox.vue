<script setup>
import { ref, watch, computed } from 'vue';
import { useKeyboardNavigableList } from 'dashboard/composables/useKeyboardNavigableList';

const props = defineProps({
  items: {
    type: Array,
    default: () => [],
  },
  type: {
    type: String,
    default: 'canned',
  },
});

const emit = defineEmits(['mentionSelect']);

const mentionsListContainerRef = ref(null);
const selectedIndex = ref(0);

const adjustScroll = () => {
  const container = mentionsListContainerRef.value;
  const item = container.querySelector(`#mention-item-${selectedIndex.value}`);
  if (item) {
    const itemTop = item.offsetTop;
    const itemBottom = itemTop + item.offsetHeight;
    const containerTop = container.scrollTop;
    const containerBottom = containerTop + container.offsetHeight;
    if (itemTop < containerTop) {
      container.scrollTop = itemTop;
    } else if (itemBottom + 34 > containerBottom) {
      container.scrollTop = itemBottom - container.offsetHeight + 34;
    }
  }
};

const onSelect = () => {
  emit('mentionSelect', props.items[selectedIndex.value]);
};

useKeyboardNavigableList({
  items: computed(() => props.items),
  onSelect,
  adjustScroll,
  selectedIndex,
});

watch(
  () => props.items,
  newItems => {
    if (newItems.length < selectedIndex.value + 1) {
      selectedIndex.value = 0;
    }
  }
);

watch(selectedIndex, adjustScroll);

const onHover = index => {
  selectedIndex.value = index;
};

const onListItemSelection = index => {
  selectedIndex.value = index;
  onSelect();
};

const variableKey = (item = {}) => {
  return props.type === 'variable' ? `{{${item.label}}}` : `/${item.label}`;
};
</script>

<template>
  <div
    ref="mentionsListContainerRef"
    class="bg-n-solid-1 p-1 rounded-xl overflow-auto absolute w-full z-20 shadow-md left-0 bottom-full max-h-[9.75rem] border border-solid border-n-strong mention--box"
  >
    <ul class="mb-0 vertical dropdown menu">
      <woot-dropdown-item
        v-for="(item, index) in items"
        :id="`mention-item-${index}`"
        :key="item.key"
        class="!mb-1"
        @mouseover="onHover(index)"
      >
        <button
          class="flex rounded-lg group flex-col gap-0.5 overflow-hidden cursor-pointer items-start px-3 py-2 justify-center w-full h-full text-left hover:bg-n-alpha-black2"
          :class="{
            'bg-n-alpha-black2': index === selectedIndex,
          }"
          @click="onListItemSelection(index)"
        >
          <slot :item="item" :index="index" :selected="index === selectedIndex">
            <p
              class="max-w-full min-w-0 mb-0 overflow-hidden text-sm font-medium text-n-slate-11 group-hover:text-n-slate-11 text-ellipsis whitespace-nowrap"
              :class="{
                'text-n-slate-12': index === selectedIndex,
              }"
            >
              {{ item.description }}
            </p>
            <p
              class="max-w-full min-w-0 mb-0 overflow-hidden text-xs text-slate-500 dark:text-slate-300 group-hover:text-n-slate-11 text-ellipsis whitespace-nowrap"
              :class="{
                'text-n-slate-12': index === selectedIndex,
              }"
            >
              {{ variableKey(item) }}
            </p>
          </slot>
        </button>
      </woot-dropdown-item>
    </ul>
  </div>
</template>

<style scoped lang="scss">
.mention--box {
  .dropdown-menu__item:last-child > button {
    @apply border-0;
  }
}

.canned-item__button::v-deep .button__content {
  @apply overflow-hidden text-ellipsis whitespace-nowrap;
}
</style>
