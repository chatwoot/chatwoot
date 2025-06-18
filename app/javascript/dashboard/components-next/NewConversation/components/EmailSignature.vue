<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
</script>

<script>
export default {
  name: 'EmailSignature',
  props: {
    html: {
      type: String,
      default: '',
    },
  },
  computed: {
    editSignatureTooltip() {
      return this.$t(
        'COMPOSE_NEW_CONVERSATION.FORM.EMAIL_OPTIONS.SIGNATURE_EDIT_TOOLTIP'
      );
    },
  },
};
</script>

<template>
  <div class="flex items-baseline flex-1 w-full h-8 gap-3 px-4 py-3">
    <label
      class="w-[80px] text-end mb-0.5 text-sm font-medium whitespace-nowrap text-n-slate-11"
    >
      <i v-tooltip.top="editSignatureTooltip" class="i-ri-information-2-line" />
      {{ t('COMPOSE_NEW_CONVERSATION.FORM.EMAIL_OPTIONS.SIGNATURE_LABEL') }}
    </label>
    <div class="max-h-[6rem] overflow-y-auto w-full">
      <div v-html="html" />
    </div>
  </div>
</template>
