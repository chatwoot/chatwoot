<script setup>
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'confirm']);
const { t } = useI18n();

const closeModal = () => emit('close');
const confirmModal = () => emit('confirm');
</script>

<template>
  <woot-modal v-model:show="props.show" :on-close="closeModal">
    <div class="flex flex-col gap-4 p-6 w-full max-w-md">
      <h3 class="text-base font-medium text-n-slate-12">
        {{ t('WEBPHONE.PERMISSIONS.TITLE') }}
      </h3>
      <p class="text-sm text-n-slate-11">
        {{ t('WEBPHONE.PERMISSIONS.DESCRIPTION') }}
      </p>
      <div class="flex justify-end gap-2">
        <NextButton
          faded
          slate
          :label="t('WEBPHONE.PERMISSIONS.NOT_NOW')"
          @click="closeModal"
        />
        <NextButton
          :label="t('WEBPHONE.PERMISSIONS.ALLOW')"
          @click="confirmModal"
        />
      </div>
    </div>
  </woot-modal>
</template>
