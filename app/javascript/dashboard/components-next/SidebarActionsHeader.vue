<script setup>
import Button from './button/Button.vue';
defineProps({
  title: {
    type: String,
    required: true,
  },
  buttons: {
    type: Array,
    default: () => [],
  },
  showCloseButton: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['click', 'close']);

const handleButtonClick = button => {
  emit('click', button.key);
};
</script>

<template>
  <div
    class="flex flex-col items-start gap-3 justify-between px-4 my-2 py-2 border-b border-n-weak"
  >
    <div class="flex items-center justify-between gap-2 flex-1">
      <span class="font-medium text-base text-n-slate-12">{{ title }}</span>
      <div class="flex items-center">
        <Button
          v-for="button in buttons"
          :key="button.key"
          v-tooltip="button.tooltip"
          :icon="button.icon"
          ghost
          sm
          @click="handleButtonClick(button)"
        />
        <Button
          v-if="showCloseButton"
          v-tooltip="$t('GENERAL.CLOSE')"
          icon="i-lucide-x"
          ghost
          sm
          @click="$emit('close')"
        />
      </div>
    </div>
    <slot />
  </div>
</template>
