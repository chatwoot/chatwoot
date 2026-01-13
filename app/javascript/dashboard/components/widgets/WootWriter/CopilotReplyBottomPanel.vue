<script setup>
import { computed } from 'vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { useI18n } from 'vue-i18n';
import { useKbd } from 'dashboard/composables/utils/useKbd';

defineProps({
  isGeneratingContent: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['submit', 'cancel']);
const { t } = useI18n();
const handleCancel = () => {
  emit('cancel');
};

const shortcutKey = useKbd(['$mod', '+', 'enter']);

const acceptLabel = computed(() => {
  return `${t('GENERAL.ACCEPT')}  (${shortcutKey.value})`;
});

const handleSubmit = () => {
  emit('submit');
};
</script>

<template>
  <div class="flex justify-between items-center p-3 pt-0">
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
