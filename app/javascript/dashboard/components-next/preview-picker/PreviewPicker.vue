<script setup>
import { nextTick, onMounted, useTemplateRef } from 'vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
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
  previewTitle: {
    type: String,
    default: '',
  },
  previewContent: {
    type: String,
    default: '',
  },
  showPreview: {
    type: Boolean,
    default: true,
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

const focusSearch = () => searchRef.value?.focus();

// Scrolls the list itself. `scrollIntoView` would also scroll clipped ancestors, which
// shifts the card under a stationary cursor and leaves `mouseover` flickering between rows.
const scrollSelectedIntoView = () => {
  nextTick(() => {
    const list = listRef.value;
    const item = list?.children[selectedIndex.value];
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

onMounted(focusSearch);

defineExpose({ scrollSelectedIntoView });
</script>

<template>
  <div
    class="flex overflow-hidden border shadow-lg rounded-xl border-n-weak bg-n-alpha-3 backdrop-blur-[100px]"
  >
    <div
      class="flex flex-col min-h-0"
      :class="
        showPreview && items.length
          ? 'w-2/5 flex-shrink-0 border-r rtl:border-r-0 rtl:border-l border-n-weak'
          : 'w-full'
      "
    >
      <div
        class="relative flex items-center flex-shrink-0 h-12 px-3 border-b border-n-weak"
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
        <li v-for="(item, index) in items" :key="item.id">
          <button
            class="flex flex-col items-start w-full gap-0.5 px-2 py-1.5 overflow-hidden text-left rounded-lg cursor-pointer"
            :class="index === selectedIndex ? 'bg-n-alpha-black2' : ''"
            @mouseover="selectedIndex = index"
            @click="emit('select', index)"
          >
            <span
              v-dompurify-html="item.title"
              class="max-w-full min-w-0 text-sm font-medium truncate text-n-slate-12"
            />
            <span
              v-dompurify-html="item.subtitle"
              class="max-w-full min-w-0 text-xs truncate text-n-slate-11"
            />
          </button>
        </li>
        <li v-if="!items.length" class="px-2 py-1.5 text-sm text-n-slate-11">
          {{ emptyLabel }}
        </li>
      </ul>
    </div>
    <div
      v-if="showPreview && items.length"
      class="flex flex-col flex-1 min-w-0"
    >
      <span
        class="flex items-center flex-shrink-0 h-12 px-4 text-xs font-medium truncate border-b text-n-slate-11 border-n-weak"
      >
        {{ previewTitle }}
      </span>
      <div class="relative flex-1 min-h-0">
        <div
          v-dompurify-html="previewContent"
          class="absolute inset-0 px-4 py-3 overflow-y-auto text-sm break-words prose-sm prose-p:text-sm prose-p:leading-relaxed prose-p:mb-1 prose-p:mt-0 prose-ul:mb-1 prose-ul:mt-0 text-n-slate-12"
        />
      </div>
    </div>
  </div>
</template>
