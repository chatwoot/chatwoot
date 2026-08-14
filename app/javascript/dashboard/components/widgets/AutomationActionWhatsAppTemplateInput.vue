<script setup>
import { computed, nextTick, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';
import WhatsAppTemplateParser from 'dashboard/components-next/whatsapp/WhatsAppTemplateParser.vue';

const props = defineProps({
  modelValue: {
    type: [Object, Array],
    default: () => ({}),
  },
  dropdownMaxHeight: {
    type: String,
    default: 'max-h-80',
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

const inboxOptions = computed(() =>
  (whatsAppInboxes.value || []).map(inbox => ({
    id: inbox.id,
    name: String(inbox.name || inbox.id),
  }))
);

const inboxId = computed(() => currentParams.value.inbox_id || null);

const templateRecords = computed(() => {
  if (!inboxId.value) return [];
  const getter = getFilteredWhatsAppTemplates.value;
  if (typeof getter !== 'function') return [];
  try {
    const templates = getter(inboxId.value);
    return Array.isArray(templates) ? templates : [];
  } catch {
    return [];
  }
});

const templateOptions = computed(() =>
  templateRecords.value.map(template => {
    const language = template.language || 'en';
    const friendlyName = String(template.name || '')
      .replace(/_/g, ' ')
      .replace(/\b\w/g, letter => letter.toUpperCase());
    return {
      id: template.id || `${template.name}:${language}`,
      name: `${friendlyName} (${language})`,
      template,
    };
  })
);

const selectedTemplate = computed(() => {
  return (
    templateOptions.value.find(option => option.id === templateId.value)
      ?.template || null
  );
});

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
    option => option.id === value
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

const selectedInbox = computed({
  get() {
    if (!inboxId.value) return null;
    return (
      inboxOptions.value.find(option => option.id === inboxId.value) || null
    );
  },
  set(value) {
    onInboxChange(value?.id || null);
  },
});

const selectedTemplateOption = computed({
  get() {
    if (!templateId.value) return null;
    return (
      templateOptions.value.find(option => option.id === templateId.value) ||
      null
    );
  },
  set(value) {
    onTemplateChange(value?.id || null);
  },
});

const emitParams = (partial, processedParams) => {
  const template = selectedTemplate.value;
  emit('update:modelValue', {
    inbox_id: inboxId.value,
    name: template?.name || currentParams.value.name || '',
    language: template?.language || currentParams.value.language || '',
    namespace: template?.namespace || currentParams.value.namespace || '',
    category: template?.category || currentParams.value.category || '',
    processed_params:
      processedParams || currentParams.value.processed_params || {},
    ...partial,
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
    onInboxChange(options[0].id);
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
    templateId.value = match?.id || null;
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
      <SingleSelect
        v-if="inboxOptions.length"
        v-model="selectedInbox"
        :options="inboxOptions"
        :dropdown-max-height="dropdownMaxHeight"
        :placeholder="
          t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.INBOX_PLACEHOLDER')
        "
        disable-deselect
      />
      <p v-else class="mb-0 text-xs text-n-slate-11">
        {{ t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.INBOX_EMPTY') }}
      </p>
    </div>
    <div class="flex flex-col gap-1">
      <label class="mb-0 text-xs font-medium text-n-slate-12">
        {{ t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.TEMPLATE_LABEL') }}
      </label>
      <SingleSelect
        v-if="inboxId"
        v-model="selectedTemplateOption"
        :options="templateOptions"
        :dropdown-max-height="dropdownMaxHeight"
        :placeholder="
          t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.TEMPLATE_PLACEHOLDER')
        "
        disable-deselect
      />
      <p v-else class="mb-0 text-xs text-n-slate-11">
        {{ t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.TEMPLATE_DISABLED') }}
      </p>
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
