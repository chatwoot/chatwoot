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
    class="flex flex-col items-start gap-3 justify-between ltr:pl-4 ltr:pr-2 rtl:pl-2 rtl:pr-4 my-2 pt-2"
  >
    <div class="flex items-center justify-between gap-2 flex-1 w-full">
      <span class="text-heading-1 text-n-slate-12">{{ title }}</span>
      <div class="flex items-center h-6">
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
    <slot />
  </div>
</template>
