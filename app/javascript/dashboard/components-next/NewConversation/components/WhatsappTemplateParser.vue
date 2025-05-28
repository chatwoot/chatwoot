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

const templateString = computed(() => {
  return props.template?.components?.find(
    component => component.type === 'BODY'
  ).text;
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
  const matchedVariables = templateString.value.match(/{{([^}]+)}}/g);
  if (!matchedVariables) return;

  const finalVars = matchedVariables.map(i => processVariable(i));
  processedParams.value = finalVars.reduce((acc, variable) => {
    acc[variable] = '';
    return acc;
  }, {});
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
      class="mb-0 text-sm text-n-slate-11"
      v-html="processedStringWithVariableHighlight"
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

    <div
      v-for="(variable, key) in processedParams"
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
