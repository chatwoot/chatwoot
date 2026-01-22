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
  animationDirection: {
    type: String,
    default: 'horizontal',
    validator: value => ['horizontal', 'vertical'].includes(value),
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

const animationClasses = computed(() => {
  if (props.animationDirection === 'vertical') {
    return {
      enterActive: 'transition-all duration-200 ease-out origin-bottom',
      enterFrom: 'opacity-0 scale-95 translate-y-2',
      enterTo: 'opacity-100 scale-100 translate-y-0',
      leaveActive: 'transition-all duration-150 ease-in origin-bottom',
      leaveFrom: 'opacity-100 scale-100 translate-y-0',
      leaveTo: 'opacity-0 scale-95 translate-y-2',
    };
  }
  return {
    enterActive: 'transition-all duration-300 ease-out',
    enterFrom: 'opacity-0 ltr:-translate-x-4 rtl:translate-x-4',
    enterTo: 'opacity-100 translate-x-0',
    leaveActive: 'transition-all duration-200 ease-in',
    leaveFrom: 'opacity-100 translate-x-0',
    leaveTo: 'opacity-0 ltr:-translate-x-4 rtl:translate-x-4',
  };
});
</script>

<template>
  <Transition
    :enter-active-class="animationClasses.enterActive"
    :enter-from-class="animationClasses.enterFrom"
    :enter-to-class="animationClasses.enterTo"
    :leave-active-class="animationClasses.leaveActive"
    :leave-from-class="animationClasses.leaveFrom"
    :leave-to-class="animationClasses.leaveTo"
  >
    <div
      v-if="hasSelected"
      class="flex items-center gap-3 py-2 ltr:pl-3 rtl:pr-3 ltr:pr-2 rtl:pl-2 rounded-xl bg-n-solid-2 outline outline-1 outline-n-container -outline-offset-1 shadow-sm origin-bottom"
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
  </Transition>
</template>
