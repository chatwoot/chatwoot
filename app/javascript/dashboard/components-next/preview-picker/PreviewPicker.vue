<script setup>
import { computed, nextTick, onMounted, useTemplateRef } from 'vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  items: {
    type: Array,
    required: true,
  },
  searchPlaceholder: {
    type: String,
    default: '',
  },
  emptyLabel: {
    type: String,
    default: '',
  },
  previewLayout: {
    type: String,
    default: 'side',
    validator: value => ['side', 'stacked', 'none'].includes(value),
  },
});

const emit = defineEmits(['select']);

const selectedIndex = defineModel('selectedIndex', {
  type: Number,
  default: 0,
});
const search = defineModel('search', { type: String, default: '' });

const listRef = useTemplateRef('listRef');
const searchRef = useTemplateRef('searchRef');

const selectedItem = computed(() => props.items[selectedIndex.value]);

const isStacked = computed(() => props.previewLayout === 'stacked');

const hasPreview = computed(
  () => props.previewLayout !== 'none' && props.items.length > 0
);

const listClass = computed(() => {
  if (!hasPreview.value) return 'w-full';
  return isStacked.value
    ? 'w-full flex-1'
    : 'w-2/5 flex-shrink-0 border-r rtl:border-r-0 rtl:border-l border-n-weak';
});

const previewClass = computed(() =>
  isStacked.value ? 'h-24 flex-shrink-0 border-t border-n-weak' : 'flex-1'
);

const groupFor = index => {
  const { group } = props.items[index];
  return group && group !== props.items[index - 1]?.group ? group : null;
};

// Scrolls the list itself. `scrollIntoView` would also scroll clipped ancestors, which
// shifts the card under a stationary cursor and leaves `mouseover` flickering between rows.
const scrollSelectedIntoView = () => {
  nextTick(() => {
    const list = listRef.value;
    const item = list?.querySelector(`[data-index="${selectedIndex.value}"]`);
    if (!item) return;

    const listRect = list.getBoundingClientRect();
    const itemRect = item.getBoundingClientRect();

    if (itemRect.top < listRect.top) {
      list.scrollTop -= listRect.top - itemRect.top;
    } else if (itemRect.bottom > listRect.bottom) {
      list.scrollTop += itemRect.bottom - listRect.bottom;
    }
  });
};

onMounted(() => searchRef.value?.focus());

defineExpose({ scrollSelectedIntoView });
</script>

<template>
  <div
    class="flex overflow-hidden border shadow-lg rounded-xl border-n-weak bg-n-alpha-3 backdrop-blur-[100px]"
    :class="{ 'flex-col': isStacked }"
  >
    <div class="flex flex-col min-h-0" :class="listClass">
      <div
        class="relative flex items-center flex-shrink-0 h-11 px-3 border-b border-n-weak"
      >
        <Icon icon="i-lucide-search" class="size-4 text-n-slate-10" />
        <input
          ref="searchRef"
          v-model="search"
          type="text"
          class="w-full h-full px-2 text-sm bg-transparent outline-none text-n-slate-12 placeholder:text-n-slate-10 reset-base"
          :placeholder="searchPlaceholder"
        />
      </div>
      <ul ref="listRef" class="flex-1 p-1 m-0 overflow-y-auto list-none">
        <template v-for="(item, index) in items" :key="item.id">
          <li
            v-if="groupFor(index)"
            class="px-2 pt-2 pb-1 text-xs font-medium text-n-slate-10"
          >
            {{ groupFor(index) }}
          </li>
          <li>
            <button
              :data-index="index"
              class="flex items-center w-full gap-2 px-2 py-1 overflow-hidden text-left rounded-lg cursor-pointer"
              :class="index === selectedIndex ? 'bg-n-alpha-black2' : ''"
              @mouseover="selectedIndex = index"
              @click="emit('select', index)"
            >
              <slot
                name="leading"
                :item="item"
                :selected="index === selectedIndex"
              />
              <span class="flex flex-col min-w-0 gap-0.5">
                <span
                  v-dompurify-html="item.title"
                  class="max-w-full min-w-0 text-sm font-medium truncate text-n-slate-12"
                />
                <span
                  v-if="item.subtitle"
                  v-dompurify-html="item.subtitle"
                  class="max-w-full min-w-0 text-xs truncate text-n-slate-11"
                />
              </span>
            </button>
          </li>
        </template>
        <li v-if="!items.length" class="px-2 py-1.5 text-sm text-n-slate-11">
          {{ emptyLabel }}
        </li>
      </ul>
    </div>
    <div v-if="hasPreview" class="flex flex-col min-w-0" :class="previewClass">
      <div
        v-if="!isStacked"
        class="flex items-center flex-shrink-0 h-11 px-4 border-b border-n-weak"
      >
        <span class="min-w-0 text-xs font-medium truncate text-n-slate-11">
          {{ selectedItem?.label }}
        </span>
      </div>
      <div class="relative flex-1 min-h-0">
        <div class="absolute inset-0 overflow-y-auto">
          <slot name="preview" :item="selectedItem" />
        </div>
      </div>
    </div>
  </div>
</template>
