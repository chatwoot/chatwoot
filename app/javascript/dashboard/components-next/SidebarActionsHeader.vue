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
    class="flex items-center justify-between px-4 py-2 border-b border-outline-variant/[.15] h-12 bg-surface-container"
  >
    <div class="flex items-center justify-between gap-2 flex-1">
      <span class="font-semibold text-sm text-on-surface">{{ title }}</span>
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
          v-tooltip="$t('GENERAL.CLOSE')"
          icon="i-lucide-x"
          ghost
          sm
          @click="$emit('close')"
        />
      </div>
    </div>
  </div>
</template>
