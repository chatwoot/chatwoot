<script setup>
import { useI18n } from 'vue-i18n';
import { ICON_COLORS } from './constants';

const { t } = useI18n();
const selectedColor = defineModel({ type: String, default: '' });
</script>

<template>
  <div class="flex items-center justify-between gap-1 px-0.5 mx-2 py-1 mb-px">
    <button
      v-for="color in ICON_COLORS"
      :key="color.value"
      v-tooltip.top="t(`EMOJI_ICON_PICKER.COLORS.${color.name}`)"
      type="button"
      class="flex items-center justify-center flex-shrink-0 transition-all rounded-full size-5 ring-offset-2 ring-offset-n-surface-2 hover:ring-2"
      :class="{ 'ring-2': selectedColor === color.value }"
      :style="{ backgroundColor: color.value, '--tw-ring-color': color.value }"
      @click="selectedColor = color.value"
    >
      <span
        v-if="selectedColor === color.value"
        class="text-white i-lucide-check size-3"
      />
    </button>
  </div>
</template>
