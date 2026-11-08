<script setup>
import { useI18n } from 'vue-i18n';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';
import Label from 'dashboard/components-next/label/Label.vue';

defineProps({
  header: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  compact: {
    type: Boolean,
    default: false,
  },
  hideToggle: {
    type: Boolean,
    default: false,
  },
  beta: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();
const modelValue = defineModel({ type: Boolean, default: false });
</script>

<template>
  <div
    class="flex flex-col items-start outline outline-1 -outline-offset-1 outline-n-weak rounded-xl [interpolate-size:allow-keywords]"
  >
    <div class="flex flex-col gap-1 items-start w-full py-3">
      <div class="flex items-center gap-3 w-full justify-between px-4">
        <div class="flex items-center gap-2">
          <span class="text-heading-3 text-n-slate-12">
            {{ header }}
          </span>
          <Label v-if="beta" :label="t('GENERAL.BETA')" color="blue" compact />
        </div>
        <template v-if="hideToggle">
          <slot name="hiddenToggle">
            <div class="size-2" />
          </slot>
        </template>
        <ToggleSwitch v-else v-model="modelValue" />
      </div>
      <span v-if="description" class="text-body-main text-n-slate-11 px-4">
        {{ description }}
      </span>
      <slot />
    </div>
    <div
      v-if="$slots.editor"
      class="w-full border-t border-n-weak"
      :class="{ 'p-0': compact, 'px-4 pb-4 pt-2': !compact }"
    >
      <slot name="editor" />
    </div>
  </div>
</template>
