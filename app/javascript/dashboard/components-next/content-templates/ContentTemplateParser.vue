<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { requiredIf } from '@vuelidate/validators';
import { useI18n } from 'vue-i18n';
import {
  isTwilioComplete,
  isTwilioMediaTemplate,
  getTwilioMediaVariableKey,
  getTwilioMediaUrl,
  applyTwilioMediaFilename,
} from '@chatwoot/utils';

import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  template: {
    type: Object,
    default: () => ({}),
    validator: value => {
      if (!value || typeof value !== 'object') return false;
      if (!value.friendly_name) return false;
      return true;
    },
  },
});

const emit = defineEmits(['sendMessage', 'resetTemplate', 'back']);

const VARIABLE_PATTERN = /{{([^}]+)}}/g;

const { t } = useI18n();

const processedParams = ref({});

const languageLabel = computed(() => {
  return `${t('CONTENT_TEMPLATES.PARSER.LANGUAGE')}: ${props.template.language || 'en'}`;
});

const categoryLabel = computed(() => {
  return `${t('CONTENT_TEMPLATES.PARSER.CATEGORY')}: ${props.template.category || 'utility'}`;
});

const templateBody = computed(() => {
  return props.template.body || '';
});

// Media-template detection and variable extraction are shared with the mobile
// app via @chatwoot/utils.
const hasMediaTemplate = computed(() => isTwilioMediaTemplate(props.template));

const hasVariables = computed(() => {
  return templateBody.value?.match(VARIABLE_PATTERN) !== null;
});

const mediaVariableKey = computed(() =>
  getTwilioMediaVariableKey(props.template)
);

const hasMediaVariable = computed(() => mediaVariableKey.value !== null);

const templateMediaUrl = computed(() =>
  hasMediaTemplate.value ? getTwilioMediaUrl(props.template) : ''
);

const variablePattern = computed(() => {
  if (!hasVariables.value) return [];
  const matches = templateBody.value.match(VARIABLE_PATTERN) || [];
  return matches.map(match => match.replace(/[{}]/g, ''));
});

const renderedTemplate = computed(() => {
  let rendered = templateBody.value;
  if (processedParams.value && Object.keys(processedParams.value).length > 0) {
    // Replace variables in the format {{1}}, {{2}}, etc.
    rendered = rendered.replace(VARIABLE_PATTERN, (match, variable) => {
      const cleanVariable = variable.trim();
      return processedParams.value[cleanVariable] || match;
    });
  }
  return rendered;
});

// Completeness validation is shared with the mobile app via @chatwoot/utils.
const isFormInvalid = computed(
  () => !isTwilioComplete(props.template, processedParams.value)
);

const v$ = useVuelidate(
  {
    processedParams: {
      requiredIfKeysPresent: requiredIf(
        () => hasVariables.value || hasMediaVariable.value
      ),
    },
  },
  { processedParams }
);

const initializeTemplateParameters = () => {
  processedParams.value = {};

  if (hasVariables.value) {
    variablePattern.value.forEach(variable => {
      processedParams.value[variable] = '';
    });
  }

  if (hasMediaVariable.value && mediaVariableKey.value) {
    processedParams.value[mediaVariableKey.value] = '';
  }
};

const sendMessage = () => {
  v$.value.$touch();
  if (v$.value.$invalid || isFormInvalid.value) return;

  const { friendly_name, language } = props.template;

  // For media templates, reduce the media URL to a filename before sending.
  const processedParameters = applyTwilioMediaFilename(
    props.template,
    processedParams.value
  );

  const payload = {
    message: renderedTemplate.value,
    templateParams: {
      name: friendly_name,
      language,
      processed_params: processedParameters,
    },
  };
  emit('sendMessage', payload);
};

const resetTemplate = () => {
  emit('resetTemplate');
};

const goBack = () => {
  emit('back');
};

onMounted(initializeTemplateParameters);

watch(
  () => props.template,
  () => {
    initializeTemplateParameters();
    v$.value.$reset();
  },
  { deep: true }
);

defineExpose({
  processedParams,
  hasVariables,
  hasMediaTemplate,
  renderedTemplate,
  v$,
  sendMessage,
  resetTemplate,
  goBack,
});
</script>

<template>
  <div>
    <div class="flex flex-col gap-4 p-4 mb-4 rounded-lg bg-n-alpha-black2">
      <div class="flex justify-between items-center">
        <h3 class="text-sm font-medium text-n-slate-12">
          {{ template.friendly_name }}
        </h3>
        <span class="text-xs text-n-slate-11">
          {{ languageLabel }}
        </span>
      </div>

      <div class="flex flex-col gap-2">
        <div class="rounded-md">
          <div class="text-sm whitespace-pre-wrap text-n-slate-12">
            {{ renderedTemplate }}
          </div>
        </div>
      </div>

      <div class="text-xs text-n-slate-11">
        {{ categoryLabel }}
      </div>
    </div>

    <div v-if="hasVariables || hasMediaVariable">
      <!-- Media URL for media templates -->
      <div v-if="hasMediaVariable" class="mb-4">
        <p class="mb-2.5 text-sm font-semibold">
          {{ $t('CONTENT_TEMPLATES.PARSER.MEDIA_URL_LABEL') }}
        </p>
        <div class="flex items-center mb-2.5">
          <Input
            v-model="processedParams[mediaVariableKey]"
            type="url"
            class="flex-1"
            :placeholder="
              templateMediaUrl ||
              t('CONTENT_TEMPLATES.PARSER.MEDIA_URL_PLACEHOLDER')
            "
          />
        </div>
      </div>

      <!-- Body Variables Section -->
      <div v-if="hasVariables">
        <p class="mb-2.5 text-sm font-semibold">
          {{ $t('CONTENT_TEMPLATES.PARSER.VARIABLES_LABEL') }}
        </p>
        <div
          v-for="variable in variablePattern"
          :key="`variable-${variable}`"
          class="flex items-center mb-2.5"
        >
          <Input
            v-model="processedParams[variable]"
            type="text"
            class="flex-1"
            :placeholder="
              t('CONTENT_TEMPLATES.PARSER.VARIABLE_PLACEHOLDER', {
                variable: variable,
              })
            "
          />
        </div>
      </div>

      <p
        v-if="v$.$dirty && (v$.$invalid || isFormInvalid)"
        class="p-2.5 text-center rounded-md bg-n-ruby-9/20 text-n-ruby-9"
      >
        {{ $t('CONTENT_TEMPLATES.PARSER.FORM_ERROR_MESSAGE') }}
      </p>
    </div>

    <slot
      name="actions"
      :send-message="sendMessage"
      :reset-template="resetTemplate"
      :go-back="goBack"
      :is-valid="!v$.$invalid && !isFormInvalid"
      :disabled="isFormInvalid"
    />
  </div>
</template>
