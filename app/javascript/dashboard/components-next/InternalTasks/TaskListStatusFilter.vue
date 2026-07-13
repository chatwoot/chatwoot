<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { TASK_STATUS_FILTER } from 'dashboard/helper/internalTaskUi';

const props = defineProps({
  modelValue: { type: String, default: TASK_STATUS_FILTER.OPEN },
  isOnExpandedLayout: { type: Boolean, default: false },
});

const emit = defineEmits(['update:modelValue']);
const { t } = useI18n();
const [showDropdown, toggleDropdown] = useToggle();

const options = computed(() => [
  {
    value: TASK_STATUS_FILTER.OPEN,
    label: t('INTERNAL_TASKS.FILTER.STATUS_OPEN'),
  },
  {
    value: TASK_STATUS_FILTER.COMPLETED,
    label: t('INTERNAL_TASKS.FILTER.STATUS_COMPLETED'),
  },
  {
    value: TASK_STATUS_FILTER.ALL,
    label: t('INTERNAL_TASKS.FILTER.STATUS_ALL'),
  },
]);

const activeLabel = computed(
  () =>
    options.value.find(option => option.value === props.modelValue)?.label || ''
);

const selectStatus = value => {
  emit('update:modelValue', value);
  toggleDropdown(false);
};
</script>

<template>
  <div class="relative flex shrink-0">
    <NextButton
      v-tooltip.right="$t('INTERNAL_TASKS.FILTER.STATUS_TOOLTIP')"
      icon="i-lucide-list-filter"
      slate
      faded
      xs
      :class="{ 'text-n-slate-12': modelValue !== TASK_STATUS_FILTER.OPEN }"
      @click="toggleDropdown()"
    />
    <div
      v-if="showDropdown"
      v-on-click-outside="() => toggleDropdown(false)"
      class="mt-1 bg-n-alpha-3 backdrop-blur-[100px] border border-n-weak w-48 rounded-xl p-2 absolute z-40 top-full"
      :class="{
        'ltr:left-0 rtl:right-0': !isOnExpandedLayout,
        'ltr:right-0 rtl:left-0': isOnExpandedLayout,
      }"
    >
      <p class="px-2 py-1 text-xs text-n-slate-11">
        {{ $t('INTERNAL_TASKS.FILTER.STATUS_LABEL') }}
      </p>
      <button
        v-for="option in options"
        :key="option.value"
        type="button"
        class="w-full text-left px-2 py-1.5 text-sm rounded-lg hover:bg-n-alpha-1"
        :class="{ 'bg-n-alpha-1 font-medium': option.value === modelValue }"
        @click="selectStatus(option.value)"
      >
        {{ option.label }}
      </button>
    </div>
    <span
      v-if="modelValue !== TASK_STATUS_FILTER.OPEN"
      class="ml-2 inline-flex items-center max-w-[9rem] px-2 py-0.5 rounded-md bg-n-slate-3 text-xs text-n-slate-12 truncate"
    >
      {{ activeLabel }}
    </span>
  </div>
</template>
