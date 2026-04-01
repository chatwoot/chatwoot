<script setup>
import { ref } from 'vue';
import { Chrome } from '@lk77/vue3-color';
import { OnClickOutside } from '@vueuse/components';

import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  modelValue: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:modelValue']);

const isPickerOpen = ref(false);

const toggleColorPicker = () => {
  isPickerOpen.value = !isPickerOpen.value;
};

const closeTogglePicker = () => {
  if (isPickerOpen.value) {
    toggleColorPicker();
  }
};

const updateColor = e => {
  emit('update:modelValue', e.hex);
};

const pickerRef = ref(null);
</script>

<template>
  <div ref="pickerRef" class="relative w-fit">
    <OnClickOutside @trigger="closeTogglePicker">
      <button
        type="button"
        class="inline-flex h-10 min-w-[12rem] items-center gap-2 rounded-lg border border-solid bg-surface-container-lowest px-3 py-2.5 text-left text-sm text-on-surface outline-none transition-all duration-200 ease-in-out focus:outline-none focus:ring-1 focus:ring-offset-0 disabled:cursor-not-allowed disabled:opacity-50"
        :class="
          isPickerOpen
            ? 'border-secondary ring-1 ring-secondary'
            : 'border-outline-variant/30 hover:border-outline-variant/50 focus:border-secondary focus:ring-secondary'
        "
        @click="toggleColorPicker"
      >
        <Icon
          icon="i-lucide-pipette"
          class="size-4 shrink-0 text-on-primary-container"
        />
        <div class="flex min-w-0 flex-1 items-center gap-2">
          <span
            class="size-4 shrink-0 rounded-md ring-1 ring-inset ring-outline-variant/40"
            :style="{ backgroundColor: modelValue || 'transparent' }"
          />
          <span
            class="min-w-0 truncate font-normal"
            :class="!modelValue && 'text-on-primary-container/70'"
          >
            {{ modelValue }}
          </span>
        </div>
        <Icon
          :icon="isPickerOpen ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
          class="size-4 shrink-0 text-on-primary-container"
        />
      </button>
      <Chrome
        v-if="isPickerOpen"
        disable-alpha
        :model-value="modelValue"
        class="colorpicker--chrome"
        @update:model-value="updateColor"
      />
    </OnClickOutside>
  </div>
</template>

<style scoped lang="scss">
.colorpicker--chrome.vc-chrome {
  @apply absolute z-[9999] rounded-lg border border-outline-variant/20 bg-surface-container-low shadow-lg;

  :deep() {
    .vc-chrome-saturation-wrap {
      @apply rounded-t-[7px];

      .vc-saturation {
        @apply rounded-t-[8px];
      }
    }

    .vc-chrome-body {
      @apply rounded-b-[7px] bg-surface-container-low;

      .vc-chrome-toggle-btn {
        .vc-chrome-toggle-icon svg {
          @apply relative left-3 [&>path]:fill-on-primary-container;
        }

        .vc-chrome-toggle-icon-highlight {
          @apply bg-surface-container-high;
        }
      }
    }

    .vc-chrome-active-color {
      @apply ring-2 ring-secondary ring-offset-2 ring-offset-surface-container-low;
    }

    .vc-hue-picker {
      @apply rounded-sm bg-surface-container-highest ring-2 ring-secondary #{!important};
      width: 6px !important;
      height: 10px !important;
      margin-top: 0 !important;
      box-shadow: none !important;
      transform: translateX(-3px) !important;
    }

    .vc-saturation-circle {
      box-shadow: none !important;
      @apply ring-2 ring-secondary;
    }

    input,
    .vc-input__input {
      @apply rounded-md border border-outline-variant/30 bg-surface-container-lowest text-on-surface shadow-none;
    }

    .vc-input__label {
      @apply text-on-surface-variant;
    }
  }
}
</style>
