<script setup>
import { ref, computed, nextTick } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBoxDropdown from 'dashboard/components-next/combobox/ComboBoxDropdown.vue';
import EmojiIcon from 'dashboard/components-next/emoji-icon-picker/EmojiIcon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

// Drag-reorderable multi-select capped at `max`. The model is the ordered list
// of selected values.
const props = defineProps({
  // { value, label, subtitle?, icon?, iconColor? } — icon is an emoji or an
  // icon-picker value, and falls back to `fallbackIcon`.
  options: {
    type: Array,
    default: () => [],
  },
  max: {
    type: Number,
    default: 3,
  },
  label: {
    type: String,
    default: '',
  },
  addLabel: {
    type: String,
    default: '',
  },
  searchPlaceholder: {
    type: String,
    default: '',
  },
  emptyState: {
    type: String,
    default: '',
  },
  fallbackIcon: {
    type: String,
    default: 'i-lucide-file-text',
  },
  // Show skeleton rows while options load, so the row height stays stable.
  loading: {
    type: Boolean,
    default: false,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  // Let the parent filter `options` (via the `search` event) instead of locally.
  serverSearch: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['search']);

const selectedIds = defineModel({ type: Array, default: () => [] });

const isOpen = ref(false);
const searchQuery = ref('');
const dragIndex = ref(null);
const dropdownRef = ref(null);

const optionsByValue = computed(
  () => new Map(props.options.map(option => [option.value, option]))
);

const selectedRows = computed(() =>
  selectedIds.value.map(
    id => optionsByValue.value.get(id) || { value: id, label: String(id) }
  )
);

const remaining = computed(() => props.max - selectedIds.value.length);

const canAddMore = computed(() => selectedIds.value.length < props.max);

const dropdownOptions = computed(() => {
  const available = props.options.filter(
    option => !selectedIds.value.includes(option.value)
  );
  if (props.serverSearch) return available;

  const query = searchQuery.value.toLowerCase();
  return available.filter(option =>
    option.label?.toLowerCase().includes(query)
  );
});

const onSearch = value => {
  searchQuery.value = value;
  emit('search', value);
};

const toggleDropdown = () => {
  isOpen.value = !isOpen.value;
  if (isOpen.value) {
    onSearch('');
    nextTick(() => dropdownRef.value?.focus());
  }
};

const onSelect = option => {
  if (!canAddMore.value) return;
  selectedIds.value = [...selectedIds.value, option.value];
  if (!canAddMore.value) isOpen.value = false;
};

const removeItem = id => {
  selectedIds.value = selectedIds.value.filter(value => value !== id);
};

const onDragStart = index => {
  dragIndex.value = index;
};

const onDragOver = index => {
  if (dragIndex.value === null || dragIndex.value === index) return;
  const ids = [...selectedIds.value];
  const [moved] = ids.splice(dragIndex.value, 1);
  ids.splice(index, 0, moved);
  dragIndex.value = index;
  selectedIds.value = ids;
};

const onDragEnd = () => {
  dragIndex.value = null;
};
</script>

<template>
  <div>
    <div
      v-if="label || $slots.counter"
      class="flex items-center justify-between mb-1.5"
    >
      <label class="text-sm font-medium text-n-slate-12">{{ label }}</label>
      <div class="flex items-center gap-2">
        <span class="text-xs text-n-slate-10">
          <slot name="counter" :remaining="remaining" :max="max" />
        </span>
        <div class="flex items-center gap-1">
          <span
            v-for="slot in max"
            :key="slot"
            class="w-4 h-1 rounded-full"
            :class="slot <= selectedIds.length ? 'bg-n-brand' : 'bg-n-slate-4'"
          />
        </div>
      </div>
    </div>

    <OnClickOutside @trigger="isOpen = false">
      <div
        class="flex flex-col gap-1 p-1 border rounded-xl border-n-weak bg-n-background"
        :class="{ 'opacity-50 pointer-events-none': disabled }"
      >
        <div
          v-if="loading && selectedIds.length && !isOpen"
          class="flex flex-col gap-1 overflow-y-auto max-h-[216px]"
          aria-busy="true"
        >
          <div
            v-for="n in selectedIds.length"
            :key="n"
            class="flex items-center gap-2 px-2 py-1.5 rounded-lg bg-n-alpha-2"
          >
            <span
              class="flex-shrink-0 opacity-40 i-lucide-grip-vertical size-4 text-n-slate-9"
            />
            <div class="flex-shrink-0 rounded-md size-6 bg-n-alpha-3" />
            <div class="flex-grow min-w-0">
              <p class="mb-0 text-sm">
                <span
                  class="inline-block w-32 h-2.5 align-middle rounded bg-n-alpha-3 animate-pulse"
                />
              </p>
              <p class="mb-0 text-xs">
                <span
                  class="inline-block w-20 h-2 align-middle rounded bg-n-alpha-3 animate-pulse"
                />
              </p>
            </div>
            <span class="flex-shrink-0 size-6" />
          </div>
        </div>

        <div
          v-else-if="selectedRows.length"
          class="flex flex-col gap-1 overflow-y-auto max-h-[216px]"
        >
          <div
            v-for="(row, index) in selectedRows"
            :key="row.value"
            draggable="true"
            class="flex items-center gap-2 px-2 py-1.5 transition-colors rounded-lg cursor-grab group/row"
            :class="
              index === dragIndex
                ? 'opacity-40 bg-n-alpha-3 ring-1 ring-inset ring-n-brand'
                : 'bg-n-alpha-2 hover:bg-n-alpha-3'
            "
            @dragstart="onDragStart(index)"
            @dragover.prevent="onDragOver(index)"
            @dragend="onDragEnd"
          >
            <span
              class="flex-shrink-0 transition-colors i-lucide-grip-vertical size-4 text-n-slate-9 group-hover/row:text-n-slate-11"
            />
            <div
              class="flex items-center justify-center flex-shrink-0 text-sm rounded-md size-6 bg-n-alpha-3 text-n-slate-11"
            >
              <EmojiIcon
                v-if="row.icon"
                :value="row.icon"
                :color="row.iconColor"
                class="shrink-0 size-4"
              />
              <span v-else class="size-4" :class="fallbackIcon" />
            </div>
            <div class="flex-grow min-w-0">
              <p class="mb-0 text-sm truncate text-n-slate-12">
                {{ row.label }}
              </p>
              <p
                v-if="row.subtitle"
                class="mb-0 text-xs truncate text-n-slate-10"
              >
                {{ row.subtitle }}
              </p>
            </div>
            <Button
              type="button"
              ghost
              slate
              xs
              no-animation
              icon="i-lucide-x"
              class="flex-shrink-0"
              @click="removeItem(row.value)"
            />
          </div>
        </div>

        <div v-if="canAddMore" class="relative">
          <Button
            type="button"
            ghost
            slate
            sm
            no-animation
            justify="start"
            :label="addLabel"
            :disabled="loading && !isOpen"
            class="w-full"
            @click="toggleDropdown"
          >
            <template #icon>
              <Spinner
                v-if="loading && !isOpen"
                :size="16"
                class="text-n-slate-11"
              />
              <Icon
                v-else
                icon="i-lucide-search"
                class="flex-shrink-0 size-4"
              />
            </template>
          </Button>
          <ComboBoxDropdown
            ref="dropdownRef"
            :open="isOpen"
            :options="dropdownOptions"
            :search-value="searchQuery"
            :search-placeholder="searchPlaceholder"
            :empty-state="emptyState"
            :loading="loading"
            @update:search-value="onSearch"
            @select="onSelect"
          />
        </div>
      </div>
    </OnClickOutside>

    <p
      v-if="selectedIds.length && $slots.note"
      class="flex items-center gap-1.5 mt-1.5 mb-0 text-xs text-n-slate-11"
    >
      <span class="rounded-full size-1.5 bg-n-teal-9" />
      <slot name="note" />
    </p>
  </div>
</template>
