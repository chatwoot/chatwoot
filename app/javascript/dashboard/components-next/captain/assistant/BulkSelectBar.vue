<script setup>
import { computed } from 'vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  allItems: {
    type: Array,
    required: true,
  },
  selectAllLabel: {
    type: String,
    default: '',
  },
  selectedCountLabel: {
    type: String,
    default: '',
  },
  deleteLabel: {
    type: String,
    default: 'Delete',
  },
});

const emit = defineEmits(['bulkDelete']);

const modelValue = defineModel({
  type: Set,
  default: () => new Set(),
});

const selectedCount = computed(() => modelValue.value.size);
const totalCount = computed(() => props.allItems.length);

const hasSelected = computed(() => selectedCount.value > 0);
const isIndeterminate = computed(
  () => hasSelected.value && selectedCount.value < totalCount.value
);
const allSelected = computed(
  () => totalCount.value > 0 && selectedCount.value === totalCount.value
);

const bulkCheckboxState = computed({
  get: () => allSelected.value,
  set: shouldSelectAll => {
    const newSelectedIds = shouldSelectAll
      ? new Set(props.allItems.map(item => item.id))
      : new Set();
    modelValue.value = newSelectedIds;
  },
});
</script>

<template>
  <transition
    name="slide-fade"
    enter-active-class="transition-all duration-300 ease-out"
    enter-from-class="opacity-0 transform ltr:-translate-x-4 rtl:translate-x-4"
    enter-to-class="opacity-100 transform translate-x-0"
    leave-active-class="hidden opacity-0"
  >
    <div
      v-if="hasSelected"
      class="flex items-center gap-3 py-1 ltr:pl-3 rtl:pr-3 ltr:pr-4 rtl:pl-4 rounded-lg bg-n-solid-2 outline outline-1 outline-n-container shadow"
    >
      <div class="flex items-center gap-3">
        <div class="flex items-center gap-1.5 min-w-0">
          <Checkbox
            v-model="bulkCheckboxState"
            :indeterminate="isIndeterminate"
          />
          <span
            class="text-sm font-medium truncate text-n-slate-12 tabular-nums"
          >
            {{ selectAllLabel }}
          </span>
        </div>
        <span class="text-sm text-n-slate-10 truncate tabular-nums">
          {{ selectedCountLabel }}
        </span>
        <div class="h-4 w-px bg-n-strong" />
        <slot name="secondary-actions" />
      </div>
      <div class="flex items-center gap-3">
        <slot name="actions" :selected-count="selectedCount">
          <Button
            :label="deleteLabel"
            sm
            ruby
            ghost
            class="!px-1.5"
            icon="i-lucide-trash"
            @click="emit('bulkDelete')"
          />
        </slot>
      </div>
    </div>
    <div v-else class="flex items-center gap-3">
      <slot name="default-actions" />
    </div>
  </transition>
</template>
