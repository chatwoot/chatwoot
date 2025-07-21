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
  bodyVars.forEach(variable => {
    const key = processVariable(variable);
    if (!allVariables.body) allVariables.body = {};
    allVariables.body[key] = '';
  });

  // Process header variables
  if (headerComponent.value?.text) {
    const headerVars = headerComponent.value.text.match(/{{([^}]+)}}/g) || [];
    headerVars.forEach(variable => {
      const key = processVariable(variable);
      if (!allVariables.header) allVariables.header = {};
      allVariables.header[key] = '';
    });
  }

  // Process footer variables
  if (footerComponent.value?.text) {
    const footerVars = footerComponent.value.text.match(/{{([^}]+)}}/g) || [];
    footerVars.forEach(variable => {
      const key = processVariable(variable);
      if (!allVariables.footer) allVariables.footer = {};
      allVariables.footer[key] = '';
    });
  }

  // Process button variables
  buttonComponents.value.forEach(buttonComponent => {
    if (buttonComponent.buttons) {
      buttonComponent.buttons.forEach((button, index) => {
        // Handle URL buttons with variables
        if (button.url && button.url.includes('{{')) {
          const buttonVars = button.url.match(/{{([^}]+)}}/g) || [];
          buttonVars.forEach(() => {
            if (!allVariables.buttons) allVariables.buttons = [];
            if (!allVariables.buttons[index]) allVariables.buttons[index] = {};
            allVariables.buttons[index].type = 'url';
            allVariables.buttons[index].parameter = '';
          });
        }

        // Handle copy code buttons
        if (button.type === 'COPY_CODE') {
          if (!allVariables.buttons) allVariables.buttons = [];
          if (!allVariables.buttons[index]) allVariables.buttons[index] = {};
          allVariables.buttons[index].type = 'copy_code';
          allVariables.buttons[index].parameter = '';
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

const sendMessage = async () => {
  const isValid = await v$.value.$validate();
  if (!isValid) return;

  const payload = {
    message: processedString.value,
    templateParams: {
      name: props.template.name,
      category: props.template.category,
      language: props.template.language,
      namespace: props.template.namespace,
      processed_params: processedParams.value,
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
      <h4 class="text-sm font-medium text-n-slate-12 mb-2">
        {{
          t('WHATSAPP_TEMPLATES.PARSER.HEADER_PARAMETERS') ||
          'Header Parameters'
        }}
      </h4>
      <div
        v-for="(variable, key) in processedParams.header"
        :key="`header-${key}`"
        class="flex items-center w-full gap-2 mb-2"
      >
        <span
          class="flex items-center h-8 text-sm min-w-6 ltr:text-left rtl:text-right text-n-slate-10"
        >
          {{ key }}
        </span>
        <Input
          v-model="processedParams.header[key]"
          custom-input-class="!h-8 w-full !bg-transparent"
          class="w-full"
          :message-type="getFieldErrorType(`header.${key}`)"
        />
      </div>
    </div>

    <!-- Body Variables -->
    <div v-if="processedParams.body" class="w-full">
      <h4 class="text-sm font-medium text-n-slate-12 mb-2">
        {{
          t('WHATSAPP_TEMPLATES.PARSER.BODY_PARAMETERS') || 'Body Parameters'
        }}
      </h4>
      <div
        v-for="(variable, key) in processedParams.body"
        :key="`body-${key}`"
        class="flex items-center w-full gap-2 mb-2"
      >
        <span
          class="flex items-center h-8 text-sm min-w-6 ltr:text-left rtl:text-right text-n-slate-10"
        >
          {{ key }}
        </span>
        <Input
          v-model="processedParams.body[key]"
          custom-input-class="!h-8 w-full !bg-transparent"
          class="w-full"
          :message-type="getFieldErrorType(`body.${key}`)"
        />
      </div>
    </div>

    <!-- Footer Variables -->
    <div v-if="processedParams.footer" class="w-full">
      <h4 class="text-sm font-medium text-n-slate-12 mb-2">
        {{
          t('WHATSAPP_TEMPLATES.PARSER.FOOTER_PARAMETERS') ||
          'Footer Parameters'
        }}
      </h4>
      <div
        v-for="(variable, key) in processedParams.footer"
        :key="`footer-${key}`"
        class="flex items-center w-full gap-2 mb-2"
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
      <h4 class="text-sm font-medium text-n-slate-12 mb-2">
        {{
          t('WHATSAPP_TEMPLATES.PARSER.BUTTON_PARAMETERS') ||
          'Button Parameters'
        }}
      </h4>
      <div
        v-for="(button, index) in processedParams.buttons"
        :key="`button-${index}`"
        class="flex items-center w-full gap-2 mb-2"
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
      class="flex items-center w-full gap-2"
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

    <div class="flex items-end justify-between w-full gap-3 h-14">
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
