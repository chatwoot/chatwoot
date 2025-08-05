<script setup>
import { CALENDAR_PERIODS } from '../helpers/DatePickerHelper';

import NextButton from 'dashboard/components-next/button/Button.vue';

defineProps({
  calendarType: {
    type: String,
    default: 'start',
  },
  firstButtonLabel: {
    type: String,
    default: '',
  },
  buttonLabel: {
    type: String,
    default: '',
  },
  viewMode: {
    type: String,
    default: '',
  },
});
const emit = defineEmits(['prev', 'next', 'setView']);

const { YEAR } = CALENDAR_PERIODS;

const onClickPrev = type => {
  emit('prev', type);
};

const onClickNext = type => {
  emit('next', type);
};

const onClickSetView = (type, mode) => {
  emit('setView', type, mode);
};
</script>

<template>
  <div class="flex items-start justify-between w-full h-9">
    <NextButton
      slate
      ghost
      xs
      icon="i-lucide-chevron-left"
      class="rtl:rotate-180"
      @click="onClickPrev(calendarType)"
    />
    <div class="flex items-center gap-1">
      <button
        v-if="firstButtonLabel"
        class="p-0 text-sm font-medium text-center text-n-slate-12 hover:text-n-brand"
        @click="onClickSetView(calendarType, viewMode)"
      >
        {{ firstButtonLabel }}
      </button>
      <button
        v-if="buttonLabel"
        class="p-0 text-sm font-medium text-center text-n-slate-12"
        :class="{ 'hover:text-n-brand': viewMode }"
        @click="onClickSetView(calendarType, YEAR)"
      >
        {{ buttonLabel }}
      </button>
    </div>
    <NextButton
      slate
      ghost
      xs
      icon="i-lucide-chevron-right"
      class="rtl:rotate-180"
      @click="onClickNext(calendarType)"
    />
  </div>
</template>
