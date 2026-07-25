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
});

const emit = defineEmits(['click', 'close']);

const handleButtonClick = button => {
  emit('click', button.key);
};
</script>

<template>
  <div
    class="flex items-center justify-between px-4 py-2 border-b border-n-weak h-14 shrink-0 bg-n-surface-2"
  >
    <div class="flex items-center justify-between gap-2 flex-1">
      <span class="font-medium text-sm text-n-slate-12">{{ title }}</span>
      <div class="flex items-center">
        <slot name="actions" />
        <Button
          v-for="button in buttons"
          :key="button.key"
          v-tooltip="button.tooltip"
          :icon="button.icon"
          ghost
          sm
          slate
          @click="handleButtonClick(button)"
        />
        <Button
          v-tooltip="$t('GENERAL.CLOSE')"
          icon="i-lucide-x"
          ghost
          sm
          slate
          @click="$emit('close')"
        />
      </div>
    </div>
  </div>
</template>
