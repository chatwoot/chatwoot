<script setup>
import { ref, defineProps, defineEmits } from 'vue';
import { Chrome } from '@lk77/vue3-color';
import { OnClickOutside } from '@vueuse/components';

import Button from 'dashboard/components-next/button/Button.vue';

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
      <Button
        color="slate"
        icon="i-lucide-pipette"
        trailing-icon
        class="!px-3 !py-3 [&>svg]:w-4 [&>svg]:h-4"
        @click="toggleColorPicker"
      >
        <div class="flex items-center flex-grow gap-2">
          <span
            class="rounded-md size-4"
            :style="{ backgroundColor: modelValue }"
          />
          <span class="min-w-0 truncate">{{ modelValue }}</span>
        </div>
      </Button>
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
  @apply shadow-lg absolute bg-n-background z-[9999] border border-n-weak dark:border-n-weak rounded-[8px];

  :deep() {
    .vc-chrome-saturation-wrap {
      @apply rounded-t-[7px];

      .vc-saturation {
        @apply rounded-t-[8px];
      }
    }

    .vc-chrome-body {
      @apply rounded-b-[7px] bg-n-alpha-3;

      .vc-chrome-toggle-btn {
        .vc-chrome-toggle-icon svg {
          @apply [&>path]:fill-n-slate-10 dark:[&>path]:fill-n-slate-10 left-3 relative;
        }
        .vc-chrome-toggle-icon-highlight {
          @apply bg-n-background;
        }
      }
    }

    input,
    .vc-input__input {
      @apply bg-n-background text-slate-900 dark:text-slate-50 rounded-md shadow-none;
    }

    .vc-input__label {
      @apply text-n-slate-11 dark:text-n-slate-11;
    }
  }
}
</style>
