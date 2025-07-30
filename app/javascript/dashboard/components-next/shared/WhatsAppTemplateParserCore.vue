<script setup>
import { ref, computed, onMounted } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { requiredIf } from '@vuelidate/validators';
import { useI18n } from 'vue-i18n';

import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  template: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['sendMessage', 'resetTemplate', 'back']);

const { t } = useI18n();

const processVariable = str => {
  return str.replace(/{{|}}/g, '');
};

const allKeysRequired = value => {
  const keys = Object.keys(value);
  return keys.every(key => value[key]);
};

const processedParams = ref({});

const templateString = computed(() => {
  return props.template.components.find(component => component.type === 'BODY')
    .text;
});

const headerComponent = computed(() => {
  return props.template.components.find(
    component => component.type === 'HEADER'
  );
});

const hasMediaHeader = computed(() => {
  return (
    headerComponent.value &&
    headerComponent.value.format &&
    ['IMAGE', 'VIDEO', 'DOCUMENT'].includes(headerComponent.value.format)
  );
});

const variables = computed(() => {
  return templateString.value.match(/{{([^}]+)}}/g);
});

const processedString = computed(() => {
  return templateString.value.replace(/{{([^}]+)}}/g, (match, variable) => {
    const variableKey = processVariable(variable);
    return processedParams.value.body?.[variableKey] || `{{${variable}}}`;
  });
});

const v$ = useVuelidate(
  {
    processedParams: {
      requiredIfKeysPresent: requiredIf(variables),
      allKeysRequired,
    },
  },
  { processedParams }
);

const generateVariables = () => {
  const allVariables = {};

  // Process body variables
  const matchedVariables = templateString.value.match(/{{([^}]+)}}/g);
  if (matchedVariables) {
    allVariables.body = {};
    matchedVariables.forEach(variable => {
      const key = processVariable(variable);
      // Special handling for authentication templates
      if (props.template?.category === 'AUTHENTICATION') {
        if (
          key === '1' ||
          key.toLowerCase().includes('otp') ||
          key.toLowerCase().includes('code')
        ) {
          allVariables.body.otp_code = '';
        } else if (
          key === '2' ||
          key.toLowerCase().includes('expiry') ||
          key.toLowerCase().includes('minute')
        ) {
          allVariables.body.expiry_minutes = '';
        } else {
          allVariables.body[key] = '';
        }
      } else {
        allVariables.body[key] = '';
      }
    });
  }

  // Add media URL field if template has media header
  if (hasMediaHeader.value) {
    if (!allVariables.header) allVariables.header = {};
    allVariables.header.media_url = '';
    allVariables.header.media_type = headerComponent.value.format.toLowerCase();
  }

  // Process button variables
  const buttonComponents = props.template.components.filter(
    component => component.type === 'BUTTONS'
  );

  buttonComponents.forEach(buttonComponent => {
    if (buttonComponent.buttons) {
      buttonComponent.buttons.forEach((button, index) => {
        // Skip button parameter inputs for authentication templates
        // as they are auto-populated with OTP codes
        if (props.template?.category !== 'AUTHENTICATION') {
          // Handle URL buttons with variables
          if (
            button.type === 'URL' &&
            button.url &&
            button.url.includes('{{')
          ) {
            const buttonVars = button.url.match(/{{([^}]+)}}/g) || [];
            if (buttonVars.length > 0) {
              if (!allVariables.buttons) allVariables.buttons = [];
              allVariables.buttons[index] = {
                type: 'url',
                parameter: '',
                url: button.url,
                variables: buttonVars.map(v => processVariable(v)),
              };
            }
          }

          // Handle copy code buttons
          if (button.type === 'COPY_CODE') {
            if (!allVariables.buttons) allVariables.buttons = [];
            allVariables.buttons[index] = {
              type: 'copy_code',
              parameter: '',
            };
          }
        }
      });
    }
  });

  processedParams.value = allVariables;
};

const updateMediaUrl = value => {
  if (!processedParams.value.header) {
    processedParams.value.header = {};
  }
  processedParams.value.header.media_url = value;
};

const sendMessage = () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  // Auto-populate button parameters for authentication templates
  const finalParams = { ...processedParams.value };
  if (props.template?.category === 'AUTHENTICATION' && finalParams.buttons) {
    finalParams.buttons.forEach((button, index) => {
      if (button.type === 'url') {
        // For authentication templates, auto-populate URL button parameter with OTP
        if (finalParams.body?.['1']) {
          finalParams.buttons[index].parameter = finalParams.body['1'];
        } else if (finalParams.body?.otp_code) {
          finalParams.buttons[index].parameter = finalParams.body.otp_code;
        }
      }
    });
  }

  const payload = {
    message: processedString.value,
    templateParams: {
      name: props.template.name,
      category: props.template.category,
      language: props.template.language,
      namespace: props.template.namespace,
      processed_params: finalParams,
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

onMounted(generateVariables);

defineExpose({
  processedParams,
  variables,
  hasMediaHeader,
  headerComponent,
  processedString,
  v$,
  updateMediaUrl,
  sendMessage,
  resetTemplate,
  goBack,
});
</script>

<template>
  <div>
    <div
      v-if="template"
      class="flex flex-col gap-4 p-4 mb-4 rounded-lg bg-n-alpha-black2"
    >
      <div class="flex justify-between items-center">
        <h3 class="text-sm font-medium text-n-slate-12">
          {{ template.name }}
        </h3>
        <span class="text-xs text-n-slate-11">
          {{ t('WHATSAPP_TEMPLATES.PARSER.LANGUAGE') }}:
          {{ template.language || 'en' }}
        </span>
      </div>

      <div class="flex flex-col gap-2">
        <div class="rounded-md bg-n-alpha-black3">
          <div class="text-sm whitespace-pre-wrap text-n-slate-12">
            {{ processedString }}
          </div>
        </div>
      </div>

      <div class="text-xs text-n-slate-11">
        {{ t('WHATSAPP_TEMPLATES.PARSER.CATEGORY') }}:
        {{ template.category || 'UTILITY' }}
      </div>
    </div>

    <div v-if="variables || hasMediaHeader">
      <div v-if="hasMediaHeader" class="mb-4">
        <p class="mb-2.5 text-sm font-semibold">
          {{
            $t('WHATSAPP_TEMPLATES.PARSER.MEDIA_HEADER_LABEL', {
              type:
                headerComponent.format.charAt(0) +
                headerComponent.format.slice(1).toLowerCase(),
            }) ||
            `${
              headerComponent.format.charAt(0) +
              headerComponent.format.slice(1).toLowerCase()
            } Header`
          }}
        </p>
        <div class="flex items-center mb-2.5">
          <Input
            :model-value="processedParams.header?.media_url || ''"
            type="url"
            class="flex-1"
            :placeholder="
              t('WHATSAPP_TEMPLATES.PARSER.MEDIA_URL_LABEL', {
                type:
                  headerComponent.format.charAt(0) +
                  headerComponent.format.slice(1).toLowerCase(),
              })
            "
            @update:model-value="updateMediaUrl"
          />
        </div>
      </div>

      <!-- Body Variables Section -->
      <div v-if="processedParams.body">
        <p class="mb-2.5 text-sm font-semibold">
          {{ $t('WHATSAPP_TEMPLATES.PARSER.VARIABLES_LABEL') }}
        </p>
        <div
          v-for="(variable, key) in processedParams.body"
          :key="`body-${key}`"
          class="flex items-center mb-2.5"
        >
          <Input
            v-model="processedParams.body[key]"
            :type="
              key === 'otp_code'
                ? 'tel'
                : key === 'expiry_minutes'
                  ? 'number'
                  : 'text'
            "
            :maxlength="
              key === 'otp_code' ? 8 : key === 'expiry_minutes' ? 3 : null
            "
            class="flex-1"
            :placeholder="
              key === 'otp_code'
                ? t('WHATSAPP_TEMPLATES.PARSER.OTP_CODE')
                : key === 'expiry_minutes'
                  ? t('WHATSAPP_TEMPLATES.PARSER.EXPIRY_MINUTES')
                  : t('WHATSAPP_TEMPLATES.PARSER.VARIABLE_PLACEHOLDER', {
                      variable: key,
                    })
            "
          />
        </div>
      </div>

      <!-- Button Variables Section -->
      <div v-if="processedParams.buttons">
        <p class="mb-2.5 text-sm font-semibold">
          {{ t('WHATSAPP_TEMPLATES.PARSER.BUTTON_PARAMETERS') }}
        </p>
        <div
          v-for="(button, index) in processedParams.buttons"
          :key="`button-${index}`"
          class="flex items-center mb-2.5"
        >
          <Input
            v-model="processedParams.buttons[index].parameter"
            :type="button.type === 'copy_code' ? 'text' : 'text'"
            :maxlength="button.type === 'copy_code' ? 15 : 500"
            class="flex-1"
            :placeholder="
              button.type === 'copy_code'
                ? t('WHATSAPP_TEMPLATES.PARSER.COUPON_CODE')
                : t('WHATSAPP_TEMPLATES.PARSER.BUTTON_PARAMETER')
            "
          />
        </div>
      </div>
      <p
        v-if="v$.$dirty && v$.$invalid"
        class="p-2.5 text-center rounded-md bg-n-ruby-9/20 text-n-ruby-9"
      >
        {{ $t('WHATSAPP_TEMPLATES.PARSER.FORM_ERROR_MESSAGE') }}
      </p>
    </div>

    <slot
      name="actions"
      :send-message="sendMessage"
      :reset-template="resetTemplate"
      :go-back="goBack"
      :is-valid="!v$.$invalid"
    />
  </div>
</template>
