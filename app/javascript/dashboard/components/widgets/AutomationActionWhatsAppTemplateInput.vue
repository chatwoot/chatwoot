<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import {
  COMPONENT_TYPES,
  DEFAULT_CATEGORY,
  DEFAULT_LANGUAGE,
  findComponentByType,
  getTemplateKey,
} from 'dashboard/helper/templateHelper';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TemplateFields from 'dashboard/components-next/Campaigns/WhatsAppCampaign/TemplateFields.vue';

const modelValue = defineModel({ type: Object, default: null });

const { t } = useI18n();
const whatsAppInboxes = useMapGetter('inboxes/getWhatsAppInboxes');
const sendableTemplates = useMapGetter('inboxes/getFilteredWhatsAppTemplates');

const saved = modelValue.value ?? {};
const savedTemplate = saved.template_params ?? {};

const inboxId = ref(saved.inbox_id ?? null);
// The saved value is a reactive proxy, which structuredClone rejects.
const processedParams = ref(
  JSON.parse(JSON.stringify(savedTemplate.processed_params ?? {}))
);

const templates = computed(() =>
  inboxId.value ? sendableTemplates.value(inboxId.value) : []
);

const templateId = ref(null);
let isRestoringSavedTemplate = Boolean(savedTemplate.name);

const inboxOptions = computed(() =>
  whatsAppInboxes.value.map(inbox => ({ value: inbox.id, label: inbox.name }))
);

const selectedTemplate = computed(
  () =>
    templates.value.find(
      template => getTemplateKey(template) === templateId.value
    ) ?? null
);

const onInboxChange = value => {
  isRestoringSavedTemplate = false;
  inboxId.value = value;
  templateId.value = null;
  processedParams.value = {};
};

// The raw body is stored so the backend renders the sent bubble from the template and its values.
const buildValue = () => {
  const template = selectedTemplate.value;
  if (!template) return { inbox_id: inboxId.value };

  return {
    inbox_id: inboxId.value,
    content: findComponentByType(template, COMPONENT_TYPES.BODY)?.text ?? '',
    template_params: {
      name: template.name,
      namespace: template.namespace ?? '',
      category: template.category ?? DEFAULT_CATEGORY,
      language: template.language ?? DEFAULT_LANGUAGE,
      processed_params: processedParams.value,
    },
  };
};

// Inboxes and their templates can load after the editor opens. Once they have, restore the saved
// template, or clear it when it was deleted or unapproved so the form asks for a new one.
watch(
  [whatsAppInboxes, templates],
  ([inboxes, list]) => {
    if (!isRestoringSavedTemplate || inboxes.length === 0) return;
    isRestoringSavedTemplate = false;

    const match = list.find(
      template =>
        template.name === savedTemplate.name &&
        template.language === savedTemplate.language
    );
    if (match) {
      templateId.value = getTemplateKey(match);
      return;
    }
    if (!inboxes.some(inbox => inbox.id === inboxId.value)) {
      inboxId.value = null;
    }
    processedParams.value = {};
    modelValue.value = buildValue();
  },
  { immediate: true }
);

watch(
  [inboxId, templateId, processedParams],
  () => {
    modelValue.value = buildValue();
  },
  { deep: true }
);
</script>

<template>
  <div class="flex flex-col gap-3">
    <div class="flex flex-col gap-1">
      <label class="mb-0.5 text-heading-3 text-n-slate-12">
        {{ t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.INBOX_LABEL') }}
      </label>
      <ComboBox
        :model-value="inboxId"
        :options="inboxOptions"
        :placeholder="
          t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.INBOX_PLACEHOLDER')
        "
        :message="t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.INBOX_HELP')"
        @update:model-value="onInboxChange"
      />
    </div>
    <TemplateFields
      v-model:template-id="templateId"
      v-model:processed-params="processedParams"
      :templates="templates"
      :has-inbox="Boolean(inboxId)"
    />
  </div>
</template>
