<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';

const props = defineProps({
  inboxId: { type: Number, required: true },
  modelValue: { type: String, default: '' },
  bodyVariables: { type: Object, default: () => ({}) },
});

const emit = defineEmits([
  'update:modelValue',
  'templateSelected',
  'update:bodyVariables',
]);

const LIQUID_VARIABLES = [
  { label: 'contact.name', value: '{{contact.name}}' },
  { label: 'contact.first_name', value: '{{contact.first_name}}' },
  { label: 'contact.last_name', value: '{{contact.last_name}}' },
  { label: 'contact.email', value: '{{contact.email}}' },
  { label: 'contact.phone_number', value: '{{contact.phone_number}}' },
  { label: 'conversation.display_id', value: '{{conversation.display_id}}' },
  {
    label: 'conversation.first_reply_created_at',
    value: '{{conversation.first_reply_created_at}}',
  },
  {
    label: 'conversation.first_reply_created_at_time',
    value: '{{conversation.first_reply_created_at_time}}',
  },
  {
    label: 'conversation.last_activity_at',
    value: '{{conversation.last_activity_at}}',
  },
  {
    label: 'conversation.last_activity_at_time',
    value: '{{conversation.last_activity_at_time}}',
  },
  { label: 'account.name', value: '{{account.name}}' },
  { label: 'inbox.name', value: '{{inbox.name}}' },
];

const { t } = useI18n();
const store = useStore();

const templates = ref([]);
const isLoading = ref(false);
const isSyncing = ref(false);
const localBodyVariables = ref({});

const templateOptions = computed(() =>
  templates.value.map(tpl => ({
    label: `${tpl.name} (${tpl.language})`,
    value: tpl.name,
    description: tpl.body_text,
  }))
);

const selectedTemplate = computed(() =>
  templates.value.find(tpl => tpl.name === props.modelValue)
);

const bodyVariableKeys = computed(
  () => selectedTemplate.value?.body_variables || []
);

const hasBodyVariables = computed(() => bodyVariableKeys.value.length > 0);

const isLiquidVariable = value => /^\{\{.+\}\}$/.test(value || '');

const liquidVariableLabel = value => {
  const match = LIQUID_VARIABLES.find(v => v.value === value);
  return match ? match.label : value.replace(/^\{\{|\}\}$/g, '');
};

// Watch for template changes to initialize/reset body variables
watch(selectedTemplate, (newTemplate, oldTemplate) => {
  if (!newTemplate) {
    localBodyVariables.value = {};
    emit('update:bodyVariables', {});
    return;
  }

  if (!newTemplate.body_variables?.length) {
    localBodyVariables.value = {};
    emit('update:bodyVariables', {});
    return;
  }

  const isInitialLoad = !oldTemplate;
  const vars = {};
  newTemplate.body_variables.forEach(key => {
    vars[key] = isInitialLoad ? props.bodyVariables[key] || '' : '';
  });
  localBodyVariables.value = vars;
  emit('update:bodyVariables', vars);
});

const updateBodyVariable = (key, value) => {
  localBodyVariables.value[key] = value;
  emit('update:bodyVariables', { ...localBodyVariables.value });
};

const selectLiquidVariable = (key, liquidVar) => {
  localBodyVariables.value[key] = liquidVar;
  emit('update:bodyVariables', { ...localBodyVariables.value });
};

const clearVariable = key => {
  localBodyVariables.value[key] = '';
  emit('update:bodyVariables', { ...localBodyVariables.value });
};

const variableErrors = ref({});

const validate = () => {
  const errors = {};
  bodyVariableKeys.value.forEach(key => {
    if (!localBodyVariables.value[key]?.trim()) {
      errors[key] = true;
    }
  });
  variableErrors.value = errors;
  return Object.keys(errors).length === 0;
};

const clearErrors = () => {
  variableErrors.value = {};
};

defineExpose({ validate, clearErrors });

const fetchAvailableTemplates = async () => {
  try {
    isLoading.value = true;
    const response = await store.dispatch('inboxes/getAvailableCSATTemplates', {
      inboxId: props.inboxId,
    });
    templates.value = response.templates || [];

    // Emit initial template data if already selected (page load)
    const initial = templates.value.find(tpl => tpl.name === props.modelValue);
    if (initial) emit('templateSelected', initial);
  } catch {
    templates.value = [];
  } finally {
    isLoading.value = false;
  }
};

const syncAndRefetch = async () => {
  try {
    isSyncing.value = true;
    await store.dispatch('inboxes/syncTemplates', props.inboxId);
    await fetchAvailableTemplates();
  } catch {
    useAlert(t('INBOX_MGMT.CSAT.EXISTING_TEMPLATE.SYNC_ERROR'));
  } finally {
    isSyncing.value = false;
  }
};

const handleSelect = value => {
  emit('update:modelValue', value);
  const selected = templates.value.find(tpl => tpl.name === value);
  if (selected) {
    emit('templateSelected', selected);
  }
};

onMounted(fetchAvailableTemplates);
</script>

<template>
  <div class="flex flex-col gap-3">
    <div class="flex gap-2 items-end">
      <WithLabel
        :label="$t('INBOX_MGMT.CSAT.EXISTING_TEMPLATE.LABEL')"
        name="existing_template"
        class="flex-1"
      >
        <ComboBox
          :model-value="modelValue"
          :options="templateOptions"
          :placeholder="
            isLoading
              ? $t('INBOX_MGMT.CSAT.EXISTING_TEMPLATE.LOADING')
              : $t('INBOX_MGMT.CSAT.EXISTING_TEMPLATE.PLACEHOLDER')
          "
          :disabled="isLoading"
          :empty-state="$t('INBOX_MGMT.CSAT.EXISTING_TEMPLATE.EMPTY_STATE')"
          @update:model-value="handleSelect"
        />
      </WithLabel>
      <NextButton
        faded
        slate
        :label="
          isSyncing
            ? $t('INBOX_MGMT.CSAT.EXISTING_TEMPLATE.SYNCING')
            : $t('INBOX_MGMT.CSAT.EXISTING_TEMPLATE.SYNC_BUTTON')
        "
        icon="i-lucide-refresh-cw"
        :is-loading="isSyncing"
        @click="syncAndRefetch"
      />
    </div>

    <!-- Body variable inputs -->
    <div v-if="hasBodyVariables" class="flex flex-col gap-3 mt-1">
      <div>
        <p class="text-sm font-medium text-n-slate-12">
          {{ $t('INBOX_MGMT.CSAT.TEMPLATE_VARIABLES.TITLE') }}
        </p>
        <p class="mt-0.5 text-xs text-n-slate-11">
          {{ $t('INBOX_MGMT.CSAT.TEMPLATE_VARIABLES.DESCRIPTION') }}
        </p>
      </div>
      <div
        v-for="key in bodyVariableKeys"
        :key="key"
        class="flex flex-col gap-1"
      >
        <label class="text-xs font-medium text-n-slate-11">
          {{
            $t('INBOX_MGMT.CSAT.TEMPLATE_VARIABLES.VARIABLE_LABEL', {
              variable: key,
            })
          }}
        </label>
        <!-- Show locked pill when a liquid variable is selected -->
        <div
          v-if="isLiquidVariable(localBodyVariables[key])"
          class="flex gap-2 items-center px-3 h-9 rounded-lg border border-n-weak bg-n-alpha-black2"
        >
          <Icon icon="i-lucide-braces" class="text-n-slate-11 size-3.5" />
          <span class="flex-1 text-sm text-n-slate-12">
            {{ liquidVariableLabel(localBodyVariables[key]) }}
          </span>
          <button
            type="button"
            class="flex items-center p-0.5 rounded transition-colors text-n-slate-10 hover:text-n-slate-12 hover:bg-n-alpha-black2"
            @click="clearVariable(key)"
          >
            <Icon icon="i-lucide-x" class="size-3.5" />
          </button>
        </div>
        <!-- Show text input + variable picker when no liquid variable is selected -->
        <div v-else class="flex flex-col gap-1.5">
          <Input
            :model-value="localBodyVariables[key] || ''"
            :placeholder="
              $t('INBOX_MGMT.CSAT.TEMPLATE_VARIABLES.VARIABLE_PLACEHOLDER', {
                variable: key,
              })
            "
            :message-type="variableErrors[key] ? 'error' : 'info'"
            :message="
              variableErrors[key]
                ? $t('INBOX_MGMT.CSAT.TEMPLATE_VARIABLES.VARIABLE_REQUIRED')
                : ''
            "
            @update:model-value="
              value => {
                updateBodyVariable(key, value);
                if (value?.trim()) variableErrors[key] = false;
              }
            "
          />
          <ComboBox
            :options="LIQUID_VARIABLES"
            :placeholder="
              $t('INBOX_MGMT.CSAT.TEMPLATE_VARIABLES.INSERT_VARIABLE')
            "
            @update:model-value="value => selectLiquidVariable(key, value)"
          />
        </div>
      </div>
    </div>
  </div>
</template>
