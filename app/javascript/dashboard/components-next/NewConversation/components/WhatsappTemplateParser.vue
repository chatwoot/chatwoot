<script setup>
import { computed, ref, onMounted } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { requiredIf } from '@vuelidate/validators';
import { useI18n } from 'vue-i18n';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  template: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['sendMessage', 'back']);

const { t } = useI18n();

const processedParams = ref({});

const templateName = computed(() => {
  return props.template?.name || '';
});

const templateComponents = computed(() => {
  return props.template?.components || [];
});

const templateString = computed(() => {
  return (
    props.template?.components?.find(component => component.type === 'BODY')
      ?.text || ''
  );
});

const headerComponent = computed(() => {
  return templateComponents.value.find(
    component => component.type === 'HEADER'
  );
});

const footerComponent = computed(() => {
  return templateComponents.value.find(
    component => component.type === 'FOOTER'
  );
});

const buttonComponents = computed(() => {
  return templateComponents.value.filter(
    component => component.type === 'BUTTONS'
  );
});

const legacyParams = computed(() => {
  const params = {};
  Object.keys(processedParams.value).forEach(key => {
    if (!['header', 'body', 'footer', 'buttons'].includes(key)) {
      params[key] = processedParams.value[key];
    }
  });
  return params;
});

const processVariable = str => {
  return str.replace(/{{|}}/g, '');
};

const processedString = computed(() => {
  return templateString.value.replace(/{{([^}]+)}}/g, (match, variable) => {
    const variableKey = processVariable(variable);
    return processedParams.value[variableKey] || `{{${variable}}}`;
  });
});

const processedStringWithVariableHighlight = computed(() => {
  const variables = templateString.value.match(/{{([^}]+)}}/g) || [];

  return variables.reduce((result, variable) => {
    const variableKey = processVariable(variable);
    const value = processedParams.value[variableKey] || variable;
    return result.replace(
      variable,
      `<span class="break-all text-n-slate-12">${value}</span>`
    );
  }, templateString.value);
});

const rules = computed(() => {
  const paramRules = {};
  Object.keys(processedParams.value).forEach(key => {
    paramRules[key] = { required: requiredIf(true) };
  });
  return {
    processedParams: paramRules,
  };
});

const v$ = useVuelidate(rules, { processedParams });

const getFieldErrorType = key => {
  if (!v$.value.processedParams[key]?.$error) return 'info';
  return 'error';
};

const generateVariables = () => {
  const allVariables = {};

  // Process body variables
  const bodyVars = templateString.value.match(/{{([^}]+)}}/g) || [];
  if (bodyVars.length > 0) {
    allVariables.body = {};
    bodyVars.forEach(variable => {
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

  // Process header variables
  if (headerComponent.value) {
    if (headerComponent.value.text) {
      // Text headers with variables
      const headerVars = headerComponent.value.text.match(/{{([^}]+)}}/g) || [];
      if (headerVars.length > 0) {
        allVariables.header = {};
        headerVars.forEach(variable => {
          const key = processVariable(variable);
          allVariables.header[key] = '';
        });
      }
    } else if (
      headerComponent.value.format &&
      ['IMAGE', 'VIDEO', 'DOCUMENT'].includes(headerComponent.value.format)
    ) {
      // Media headers need URL input
      allVariables.header = {
        media_url: '',
        media_type: headerComponent.value.format.toLowerCase(),
      };
    }
  }

  // Process footer variables
  if (footerComponent.value?.text) {
    const footerVars = footerComponent.value.text.match(/{{([^}]+)}}/g) || [];
    if (footerVars.length > 0) {
      allVariables.footer = {};
      footerVars.forEach(variable => {
        const key = processVariable(variable);
        allVariables.footer[key] = '';
      });
    }
  }

  // Process button variables
  buttonComponents.value.forEach(buttonComponent => {
    if (buttonComponent.buttons) {
      buttonComponent.buttons.forEach((button, index) => {
        // Handle URL buttons with variables
        if (button.type === 'URL' && button.url && button.url.includes('{{')) {
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

        // Handle interactive buttons with dynamic text
        if (['QUICK_REPLY', 'URL', 'PHONE_NUMBER'].includes(button.type)) {
          if (button.text && button.text.includes('{{')) {
            if (!allVariables.buttons) allVariables.buttons = [];
            allVariables.buttons[index] = {
              type: button.type.toLowerCase(),
              parameter: '',
              text: button.text,
            };
          }
        }
      });
    }
  });

  processedParams.value = allVariables;
};

const validateButtonParameter = (button, index) => {
  const parameter = processedParams.value.buttons[index].parameter;

  if (button.type === 'copy_code') {
    if (parameter && parameter.length > 15) {
      processedParams.value.buttons[index].parameter = parameter.substring(
        0,
        15
      );
    }
  }
};

const getHeaderFieldLabel = key => {
  if (key === 'media_url') {
    const mediaType = processedParams.value.header?.media_type || 'media';
    return (
      t('WHATSAPP_TEMPLATES.PARSER.MEDIA_URL', {
        type: mediaType.toUpperCase(),
      }) || `${mediaType.toUpperCase()} URL`
    );
  }
  return key;
};

const getHeaderFieldPlaceholder = key => {
  if (key === 'media_url') {
    const mediaType = processedParams.value.header?.media_type || 'media';
    switch (mediaType) {
      case 'image':
        return (
          t('WHATSAPP_TEMPLATES.PARSER.IMAGE_URL_PLACEHOLDER') ||
          'Enter image URL (https://example.com/image.jpg)'
        );
      case 'video':
        return (
          t('WHATSAPP_TEMPLATES.PARSER.VIDEO_URL_PLACEHOLDER') ||
          'Enter video URL (https://example.com/video.mp4)'
        );
      case 'document':
        return (
          t('WHATSAPP_TEMPLATES.PARSER.DOCUMENT_URL_PLACEHOLDER') ||
          'Enter document URL (https://example.com/document.pdf)'
        );
      default:
        return 'Enter media URL';
    }
  }
  return `Enter ${key} value`;
};

const getBodyParameterLabel = key => {
  if (props.template?.category === 'AUTHENTICATION') {
    switch (key) {
      case 'otp_code':
        return t('WHATSAPP_TEMPLATES.PARSER.OTP_CODE') || 'OTP Code';
      case 'expiry_minutes':
        return (
          t('WHATSAPP_TEMPLATES.PARSER.EXPIRY_MINUTES') || 'Expiry (minutes)'
        );
      default:
        return key;
    }
  }
  return key;
};

const getBodyParameterPlaceholder = key => {
  if (props.template?.category === 'AUTHENTICATION') {
    switch (key) {
      case 'otp_code':
        return (
          t('WHATSAPP_TEMPLATES.PARSER.OTP_CODE_PLACEHOLDER') ||
          'Enter 4-8 digit OTP code'
        );
      case 'expiry_minutes':
        return (
          t('WHATSAPP_TEMPLATES.PARSER.EXPIRY_MINUTES_PLACEHOLDER') ||
          'Enter expiry time in minutes'
        );
      default:
        return `Enter ${key} value`;
    }
  }
  return `Enter ${key} value`;
};

const getBodyParameterType = key => {
  if (props.template?.category === 'AUTHENTICATION') {
    switch (key) {
      case 'otp_code':
        return 'tel';
      case 'expiry_minutes':
        return 'number';
      default:
        return 'text';
    }
  }
  return 'text';
};

const getBodyParameterMaxLength = key => {
  if (props.template?.category === 'AUTHENTICATION') {
    switch (key) {
      case 'otp_code':
        return 8;
      case 'expiry_minutes':
        return 3;
      default:
        return null;
    }
  }
  return null;
};

const sendMessage = async () => {
  const isValid = await v$.value.$validate();
  if (!isValid) return;

  // Auto-populate button parameters for authentication templates
  const finalParams = { ...processedParams.value };
  if (props.template?.category === 'AUTHENTICATION' && finalParams.buttons) {
    finalParams.buttons.forEach((button, index) => {
      if (
        button.type === 'url' &&
        button.variables?.includes('1') &&
        finalParams.body?.otp_code
      ) {
        finalParams.buttons[index].parameter = finalParams.body.otp_code;
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

onMounted(() => {
  generateVariables();
});
</script>

<template>
  <div
    class="absolute top-full mt-1.5 max-h-[30rem] overflow-y-auto left-0 flex flex-col gap-4 px-4 pt-6 pb-5 items-start w-[28.75rem] h-auto bg-n-solid-2 border border-n-strong shadow-sm rounded-lg"
  >
    <span class="text-sm text-n-slate-12">
      {{
        t(
          'COMPOSE_NEW_CONVERSATION.FORM.WHATSAPP_OPTIONS.TEMPLATE_PARSER.TEMPLATE_NAME',
          { templateName: templateName }
        )
      }}
    </span>

    <p
      v-dompurify-html="processedStringWithVariableHighlight"
      class="mb-0 text-sm text-n-slate-11"
    />

    <span
      v-if="Object.keys(processedParams).length"
      class="text-sm font-medium text-n-slate-12"
    >
      {{
        t(
          'COMPOSE_NEW_CONVERSATION.FORM.WHATSAPP_OPTIONS.TEMPLATE_PARSER.VARIABLES'
        )
      }}
    </span>

    <!-- Header Variables -->
    <div v-if="processedParams.header" class="w-full">
      <h4 class="mb-2 text-sm font-medium text-n-slate-12">
        {{
          t('WHATSAPP_TEMPLATES.PARSER.HEADER_PARAMETERS') ||
          'Header Parameters'
        }}
      </h4>
      <!-- Header Parameters -->
      <div
        v-for="[key] in Object.entries(processedParams.header)"
        :key="`header-${key}`"
        class="flex gap-2 items-center mb-2 w-full"
      >
        <span
          class="flex items-center h-8 text-sm min-w-6 ltr:text-left rtl:text-right text-n-slate-10"
        >
          {{ getHeaderFieldLabel(key) }}
        </span>
        <Input
          v-model="processedParams.header[key]"
          custom-input-class="!h-8 w-full !bg-transparent"
          class="w-full"
          :message-type="getFieldErrorType(`header.${key}`)"
          :placeholder="getHeaderFieldPlaceholder(key)"
          :type="key === 'media_url' ? 'url' : 'text'"
        />
      </div>
    </div>

    <!-- Body Variables -->
    <div v-if="processedParams.body" class="w-full">
      <h4 class="mb-2 text-sm font-medium text-n-slate-12">
        {{
          t('WHATSAPP_TEMPLATES.PARSER.BODY_PARAMETERS') || 'Body Parameters'
        }}
      </h4>
      <div
        v-for="(variable, key) in processedParams.body"
        :key="`body-${key}`"
        class="flex gap-2 items-center mb-2 w-full"
      >
        <span
          class="flex items-center h-8 text-sm min-w-6 ltr:text-left rtl:text-right text-n-slate-10"
        >
          {{ getBodyParameterLabel(key) }}
        </span>
        <Input
          v-model="processedParams.body[key]"
          custom-input-class="!h-8 w-full !bg-transparent"
          class="w-full"
          :message-type="getFieldErrorType(`body.${key}`)"
          :placeholder="getBodyParameterPlaceholder(key)"
          :type="getBodyParameterType(key)"
          :maxlength="getBodyParameterMaxLength(key)"
        />
      </div>
    </div>

    <!-- Footer Variables -->
    <div v-if="processedParams.footer" class="w-full">
      <h4 class="mb-2 text-sm font-medium text-n-slate-12">
        {{
          t('WHATSAPP_TEMPLATES.PARSER.FOOTER_PARAMETERS') ||
          'Footer Parameters'
        }}
      </h4>
      <div
        v-for="(variable, key) in processedParams.footer"
        :key="`footer-${key}`"
        class="flex gap-2 items-center mb-2 w-full"
      >
        <span
          class="flex items-center h-8 text-sm min-w-6 ltr:text-left rtl:text-right text-n-slate-10"
        >
          {{ key }}
        </span>
        <Input
          v-model="processedParams.footer[key]"
          custom-input-class="!h-8 w-full !bg-transparent"
          class="w-full"
          :message-type="getFieldErrorType(`footer.${key}`)"
        />
      </div>
    </div>

    <!-- Button Variables -->
    <div v-if="processedParams.buttons" class="w-full">
      <h4 class="mb-2 text-sm font-medium text-n-slate-12">
        {{
          t('WHATSAPP_TEMPLATES.PARSER.BUTTON_PARAMETERS') ||
          'Button Parameters'
        }}
      </h4>
      <div
        v-for="(button, index) in processedParams.buttons"
        :key="`button-${index}`"
        class="flex gap-2 items-center mb-2 w-full"
      >
        <span
          class="flex items-center h-8 text-sm min-w-6 ltr:text-left rtl:text-right text-n-slate-10"
        >
          {{
            button.type === 'copy_code'
              ? t('WHATSAPP_TEMPLATES.PARSER.COUPON_CODE') || 'Coupon Code'
              : `${t('WHATSAPP_TEMPLATES.PARSER.BUTTON') || 'Button'} ${index + 1}`
          }}
        </span>
        <Input
          v-model="processedParams.buttons[index].parameter"
          custom-input-class="!h-8 w-full !bg-transparent"
          class="w-full"
          :message-type="getFieldErrorType(`buttons.${index}.parameter`)"
          :placeholder="
            button.type === 'copy_code'
              ? 'Enter coupon code (max 15 chars)'
              : 'Enter button parameter'
          "
          :max-length="button.type === 'copy_code' ? 15 : 500"
          @input="validateButtonParameter(button, index)"
        />
      </div>
    </div>

    <!-- Legacy Variables (for backward compatibility) -->
    <div
      v-for="(variable, key) in legacyParams"
      :key="key"
      class="flex gap-2 items-center w-full"
    >
      <span
        class="flex items-center h-8 text-sm min-w-6 ltr:text-left rtl:text-right text-n-slate-10"
      >
        {{ key }}
      </span>
      <Input
        v-model="processedParams[key]"
        custom-input-class="!h-8 w-full !bg-transparent"
        class="w-full"
        :message-type="getFieldErrorType(key)"
      />
    </div>

    <div class="flex gap-3 justify-between items-end w-full h-14">
      <Button
        :label="
          t(
            'COMPOSE_NEW_CONVERSATION.FORM.WHATSAPP_OPTIONS.TEMPLATE_PARSER.BACK'
          )
        "
        color="slate"
        variant="faded"
        class="w-full font-medium"
        @click="emit('back')"
      />
      <Button
        :label="
          t(
            'COMPOSE_NEW_CONVERSATION.FORM.WHATSAPP_OPTIONS.TEMPLATE_PARSER.SEND_MESSAGE'
          )
        "
        class="w-full font-medium"
        @click="sendMessage"
      />
    </div>
  </div>
</template>
