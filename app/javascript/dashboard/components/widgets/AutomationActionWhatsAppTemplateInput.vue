<script setup>
import { computed, nextTick, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import WhatsAppTemplateParser from 'dashboard/components-next/whatsapp/WhatsAppTemplateParser.vue';

const props = defineProps({
  modelValue: {
    type: [Object, Array],
    default: () => ({}),
  },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();
const whatsAppInboxes = useMapGetter('inboxes/getWhatsAppInboxes');
const getFilteredWhatsAppTemplates = useMapGetter(
  'inboxes/getFilteredWhatsAppTemplates'
);

const templateParserRef = ref(null);
const templateId = ref(null);
const hydratedKey = ref('');
const hydrating = ref(false);

const currentParams = computed(() => {
  const raw = props.modelValue;
  if (Array.isArray(raw)) return raw[0] || {};
  return raw && typeof raw === 'object' ? raw : {};
});

const inboxOptions = computed(
  () =>
    whatsAppInboxes.value?.map(inbox => ({
      value: inbox.id,
      label: inbox.name,
    })) ?? []
);

const inboxId = computed(() => currentParams.value.inbox_id || null);

const templateOptions = computed(() => {
  if (!inboxId.value) return [];
  const templates = getFilteredWhatsAppTemplates.value(inboxId.value) || [];
  return templates.map(template => {
    const friendlyName = String(template.name || '')
      .replace(/_/g, ' ')
      .replace(/\b\w/g, letter => letter.toUpperCase());
    return {
      value: template.id || `${template.name}:${template.language}`,
      label: `${friendlyName} (${template.language || 'en'})`,
      template,
    };
  });
});

const selectedTemplate = computed(() => {
  if (!templateId.value) return null;
  return (
    templateOptions.value.find(option => option.value === templateId.value)
      ?.template || null
  );
});

const emitParams = (partial, processedParams) => {
  const template = selectedTemplate.value;
  const next = {
    inbox_id: inboxId.value,
    name: template?.name || currentParams.value.name || '',
    language: template?.language || currentParams.value.language || '',
    namespace: template?.namespace || currentParams.value.namespace || '',
    category: template?.category || currentParams.value.category || '',
    processed_params:
      processedParams || currentParams.value.processed_params || {},
    ...partial,
  };
  emit('update:modelValue', next);
};

const onInboxChange = value => {
  templateId.value = null;
  hydratedKey.value = '';
  emit('update:modelValue', {
    inbox_id: value || null,
    name: '',
    language: '',
    namespace: '',
    category: '',
    processed_params: {},
  });
};

const onTemplateChange = value => {
  templateId.value = value || null;
  hydratedKey.value = '';
  const template = templateOptions.value.find(
    option => option.value === value
  )?.template;
  emit('update:modelValue', {
    inbox_id: inboxId.value,
    name: template?.name || '',
    language: template?.language || '',
    namespace: template?.namespace || '',
    category: template?.category || '',
    processed_params: {},
  });
};

const syncProcessedParams = () => {
  const parser = templateParserRef.value;
  if (!parser || !selectedTemplate.value) return;
  emitParams({}, parser.processedParams || {});
};

watch(
  inboxOptions,
  options => {
    if (inboxId.value || options.length !== 1) return;
    onInboxChange(options[0].value);
  },
  { immediate: true }
);

watch(
  () => [inboxId.value, currentParams.value.name, currentParams.value.language],
  () => {
    const { name, language } = currentParams.value;
    if (!name) {
      templateId.value = null;
      return;
    }
    const match = templateOptions.value.find(
      option =>
        option.template.name === name &&
        String(option.template.language || '').toLowerCase() ===
          String(language || '').toLowerCase()
    );
    templateId.value = match?.value || null;
  },
  { immediate: true }
);

watch(
  selectedTemplate,
  async template => {
    if (!template) return;
    const key = `${template.name}:${template.language}`;
    hydrating.value = true;
    await nextTick();
    const parser = templateParserRef.value;
    const saved = currentParams.value.processed_params;
    if (
      parser &&
      saved &&
      Object.keys(saved).length &&
      hydratedKey.value !== key
    ) {
      parser.processedParams = saved;
      hydratedKey.value = key;
    }
    hydrating.value = false;
  },
  { flush: 'post' }
);

watch(
  () => templateParserRef.value?.processedParams,
  () => {
    if (hydrating.value || !selectedTemplate.value) return;
    syncProcessedParams();
  },
  { deep: true }
);
</script>

<template>
  <div class="flex flex-col gap-2">
    <div class="flex flex-col gap-1">
      <label class="mb-0 text-xs font-medium text-n-slate-12">
        {{ t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.INBOX_LABEL') }}
      </label>
      <ComboBox
        :model-value="inboxId"
        :options="inboxOptions"
        :placeholder="
          inboxOptions.length
            ? t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.INBOX_PLACEHOLDER')
            : t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.INBOX_EMPTY')
        "
        :disabled="!inboxOptions.length"
        teleport
        @update:model-value="onInboxChange"
      />
    </div>
    <div class="flex flex-col gap-1">
      <label class="mb-0 text-xs font-medium text-n-slate-12">
        {{ t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.TEMPLATE_LABEL') }}
      </label>
      <ComboBox
        :model-value="templateId"
        :options="templateOptions"
        :disabled="!inboxId"
        :placeholder="
          inboxId
            ? t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.TEMPLATE_PLACEHOLDER')
            : t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.TEMPLATE_DISABLED')
        "
        teleport
        @update:model-value="onTemplateChange"
      />
    </div>
    <WhatsAppTemplateParser
      v-if="selectedTemplate"
      ref="templateParserRef"
      :template="selectedTemplate"
    />
    <p class="mb-0 text-xs text-n-slate-11">
      {{ t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.VARIABLES_HINT') }}
    </p>
  </div>
</template>
