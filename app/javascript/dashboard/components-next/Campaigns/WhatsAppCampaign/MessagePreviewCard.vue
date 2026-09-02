<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import { PLATFORMS } from 'dashboard/services/TemplateConstants';
import TemplatePreview from 'dashboard/components-next/template-preview/TemplatePreview.vue';

const props = defineProps({
  template: {
    type: Object,
    default: null,
  },
  processedParams: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();

const variables = computed(() => ({
  ...props.processedParams.header,
  ...props.processedParams.body,
}));
</script>

<template>
  <section
    class="flex flex-col w-full gap-5 p-4 rounded-xl outline outline-1 -outline-offset-1 outline-n-weak"
  >
    <h2 class="text-center text-heading-2 text-n-slate-12">
      {{ t('CAMPAIGN.WHATSAPP.FORM.PREVIEW.TITLE') }}
    </h2>
    <template v-if="template">
      <TemplatePreview
        :template="template"
        :variables="variables"
        :platform="PLATFORMS.WHATSAPP"
        class="flex justify-center py-6"
      />
      <p class="mb-0 text-center text-label-small text-n-slate-11">
        {{ t('CAMPAIGN.WHATSAPP.FORM.PREVIEW.FOOTNOTE') }}
      </p>
    </template>
    <p v-else class="mb-0 text-center text-body-main text-n-slate-11">
      {{ t('CAMPAIGN.WHATSAPP.FORM.PREVIEW.EMPTY_STATE') }}
    </p>
  </section>
</template>
