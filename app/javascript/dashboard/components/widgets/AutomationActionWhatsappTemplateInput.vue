<script setup>
import { computed, watch, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';
import NextInput from 'dashboard/components-next/input/Input.vue';

// Tokens the rule author can drop into a variable input. Substitution
// happens server-side via Liquid drops, so anything supported by the
// existing message drops (contact / conversation / inbox / account / agent)
// works — this list is just the most useful shortcuts.
const PLACEHOLDER_TOKENS = [
  '{{contact.name}}',
  '{{contact.email}}',
  '{{contact.phone_number}}',
  '{{conversation.display_id}}',
  '{{inbox.name}}',
  '{{agent.name}}',
];

const defaultConfig = () => ({
  inbox_id: null,
  template_name: '',
  template_language: '',
  template_namespace: null,
  template_category: '',
  template_body: '',
  processed_params: {},
});

const props = defineProps({
  modelValue: {
    type: [Object, Array],
    default: () => null,
  },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();
const store = useStore();

const unwrap = value => {
  if (!value) return defaultConfig();
  if (Array.isArray(value)) return { ...defaultConfig(), ...(value[0] || {}) };
  return { ...defaultConfig(), ...value };
};

const config = computed(() => unwrap(props.modelValue));

const updateConfig = patch => {
  emit('update:modelValue', { ...config.value, ...patch });
};

const allInboxes = computed(() => store.getters['inboxes/getInboxes'] || []);

const whatsappInboxOptions = computed(() =>
  allInboxes.value
    .filter(inbox => inbox.channel_type === 'Channel::Whatsapp')
    .map(inbox => ({ id: inbox.id, name: inbox.name }))
);

const selectedInboxOption = computed({
  get: () => {
    if (!config.value.inbox_id) return null;
    return (
      whatsappInboxOptions.value.find(o => o.id === config.value.inbox_id) ||
      null
    );
  },
  set: option => {
    updateConfig({
      inbox_id: option ? option.id : null,
      template_name: '',
      template_language: '',
      template_namespace: null,
      template_category: '',
      template_body: '',
      processed_params: {},
    });
  },
});

const bodyText = template => {
  const body = (template?.components || []).find(c => c.type === 'BODY');
  return body ? body.text || '' : '';
};

const availableTemplates = computed(() => {
  if (!config.value.inbox_id) return [];
  return store.getters['inboxes/getWhatsAppTemplates'](
    config.value.inbox_id
  ).filter(tpl => (tpl.status || '').toLowerCase() === 'approved');
});

const templateOptions = computed(() =>
  availableTemplates.value.map(tpl => ({
    id: `${tpl.name}|||${tpl.language}`,
    name: `${tpl.name} · ${tpl.language}`,
    raw: tpl,
  }))
);

const selectedTemplateOption = computed({
  get: () => {
    if (!config.value.template_name) return null;
    const id = `${config.value.template_name}|||${config.value.template_language}`;
    return templateOptions.value.find(o => o.id === id) || null;
  },
  set: option => {
    if (!option) {
      updateConfig({
        template_name: '',
        template_language: '',
        template_namespace: null,
        template_category: '',
        template_body: '',
        processed_params: {},
      });
      return;
    }
    const raw =
      option.raw ||
      availableTemplates.value.find(
        tpl => `${tpl.name}|||${tpl.language}` === option.id
      );
    if (!raw) return;

    const body = bodyText(raw);
    const matches = body.match(/{{\s*\d+\s*}}/g) || [];
    const initialParams = {};
    matches.forEach(token => {
      initialParams[token.replace(/[^0-9]/g, '')] = '';
    });

    updateConfig({
      template_name: raw.name,
      template_language: raw.language,
      template_namespace: raw.namespace || null,
      template_category: raw.category || '',
      template_body: body,
      processed_params: initialParams,
    });
  },
});

const bodyVariableKeys = computed(() => {
  const body = config.value.template_body || '';
  const matches = body.match(/{{\s*\d+\s*}}/g) || [];
  return matches.map(token => token.replace(/[^0-9]/g, ''));
});

const renderedBody = computed(() => {
  const body = config.value.template_body || '';
  if (!body) return '';
  return body.replace(/{{\s*(\d+)\s*}}/g, (match, key) => {
    const value = (config.value.processed_params || {})[key];
    return value ? value : match;
  });
});

const updateVariable = (key, value) => {
  const next = { ...(config.value.processed_params || {}), [key]: value };
  updateConfig({ processed_params: next });
};

watch(availableTemplates, () => {
  if (!config.value.template_name) return;
  const id = `${config.value.template_name}|||${config.value.template_language}`;
  if (!templateOptions.value.some(o => o.id === id)) {
    selectedTemplateOption.value = null;
  }
});

onMounted(() => {
  if (Array.isArray(props.modelValue) || !props.modelValue) {
    emit('update:modelValue', config.value);
  }
});

const placeholdersHint = computed(() => PLACEHOLDER_TOKENS.join(', '));

const formatVariableKey = key => `{{${key}}}`;
</script>

<template>
  <div class="wa-template-input flex flex-col gap-3 w-full">
    <p class="form-row__hint">
      {{ t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.OVERVIEW') }}
    </p>

    <div class="form-row">
      <label class="form-row__label">
        {{ t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.INBOX_LABEL') }}
      </label>
      <SingleSelect
        v-model="selectedInboxOption"
        :options="whatsappInboxOptions"
        :placeholder="t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.INBOX_PLACEHOLDER')"
      />
      <p
        v-if="!whatsappInboxOptions.length"
        class="form-row__hint form-row__hint--warn"
      >
        {{ t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.NO_WA_INBOXES') }}
      </p>
    </div>

    <div v-if="config.inbox_id" class="form-row">
      <label class="form-row__label">
        {{ t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.TEMPLATE_LABEL') }}
      </label>
      <SingleSelect
        v-model="selectedTemplateOption"
        :options="templateOptions"
        :placeholder="
          t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.TEMPLATE_PLACEHOLDER')
        "
      />
      <p
        v-if="config.inbox_id && !templateOptions.length"
        class="form-row__hint form-row__hint--warn"
      >
        {{ t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.NO_TEMPLATES') }}
      </p>
    </div>

    <div v-if="config.template_name" class="wa-template-preview">
      <p class="wa-template-preview__label">
        {{ t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.BODY_LABEL') }}
      </p>
      <p class="wa-template-preview__body">{{ renderedBody }}</p>
    </div>

    <div
      v-if="config.template_name && bodyVariableKeys.length"
      class="form-row"
    >
      <label class="form-row__label">
        {{ t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.VARIABLES_LABEL') }}
      </label>
      <p class="form-row__hint">
        {{ t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.VARIABLES_HINT') }}
      </p>
      <code class="wa-template-tokens">{{ placeholdersHint }}</code>
      <div
        v-for="key in bodyVariableKeys"
        :key="key"
        class="flex items-center gap-2 mt-2"
      >
        <span class="wa-template-variable__key">{{ formatVariableKey(key) }}</span>
        <NextInput
          :model-value="(config.processed_params || {})[key] || ''"
          type="text"
          size="sm"
          class="flex-1"
          :placeholder="
            t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.VARIABLE_PLACEHOLDER')
          "
          @update:model-value="value => updateVariable(key, value)"
        />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.form-row__label {
  @apply block text-sm font-medium text-n-slate-12 mb-1;
}

.form-row__hint {
  @apply text-xs text-n-slate-11 mt-1;

  &--warn {
    @apply text-n-amber-11;
  }
}

.wa-template-tokens {
  @apply block mt-1 px-2 py-1 rounded text-xs bg-n-alpha-black2 text-n-slate-12;
  font-family: monospace;
}

.wa-template-preview {
  @apply rounded-md p-3 bg-n-alpha-black2 border border-solid border-n-weak;

  &__label {
    @apply text-xs font-semibold text-n-slate-11 mb-1;
  }

  &__body {
    @apply text-sm whitespace-pre-wrap text-n-slate-12 mb-0;
    font-family: monospace;
  }
}

.wa-template-variable__key {
  @apply text-xs font-mono px-2 py-1 rounded bg-n-alpha-black2 text-n-slate-12 flex-shrink-0;
}
</style>
