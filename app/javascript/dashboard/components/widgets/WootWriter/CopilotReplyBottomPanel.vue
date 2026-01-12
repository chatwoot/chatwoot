<script setup>
import { computed } from 'vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { useI18n } from 'vue-i18n';

defineProps({
  isGeneratingContent: {
    type: Boolean,
    default: false,
  },
  isPrivate: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['submit', 'cancel']);
const { t } = useI18n();
const handleCancel = () => {
  emit('cancel');
};

const acceptLabel = computed(() => {
  const isMac =
    navigator.platform.startsWith('Mac') || navigator.platform === 'iPhone';
  const modKey = isMac ? '⌘' : 'Ctrl';

  return `${t('GENERAL.ACCEPT')}  (${modKey} + ↵)`;
});

const handleSubmit = () => {
  emit('submit');
};
</script>

<template>
  <div
    class="flex justify-between items-center p-3 border-t"
    :class="{ 'border-n-weak': !isPrivate, 'border-n-amber-12/5': isPrivate }"
  >
    <NextButton
      :label="t('GENERAL.DISCARD')"
      slate
      link
      class="!px-1 hover:!no-underline"
      sm
      :disabled="isGeneratingContent"
      @click="handleCancel"
    />
    <NextButton
      :label="acceptLabel"
      class="bg-n-iris-9 text-white"
      solid
      sm
      :disabled="isGeneratingContent"
      @click="handleSubmit"
    />
  </div>
</template>
