<script>
/**
 * This component handles parsing and sending WhatsApp message templates.
 * It works as follows:
 * 1. Displays the template text with variable placeholders.
 * 2. Generates input fields for each variable in the template.
 * 3. Validates that all variables are filled before sending.
 * 4. Replaces placeholders with user-provided values.
 * 5. Emits events to send the processed message or reset the template.
 */
import { ref, computed, onMounted } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { requiredIf } from '@vuelidate/validators';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    template: {
      type: Object,
      default: () => ({}),
    },
  },
  emits: ['sendMessage', 'resetTemplate'],
  setup(props, { emit }) {
    const processVariable = str => {
      return str.replace(/{{|}}/g, '');
    };

    const allKeysRequired = value => {
      const keys = Object.keys(value);
      return keys.every(key => value[key]);
    };

    const processedParams = ref({});

    const templateString = computed(() => {
      return props.template.components.find(
        component => component.type === 'BODY'
      ).text;
    });

    const variables = computed(() => {
      return templateString.value.match(/{{([^}]+)}}/g);
    });

    const processedString = computed(() => {
      return templateString.value.replace(/{{([^}]+)}}/g, (match, variable) => {
        const variableKey = processVariable(variable);
        return processedParams.value[variableKey] || `{{${variable}}}`;
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
      const matchedVariables = templateString.value.match(/{{([^}]+)}}/g);
      if (!matchedVariables) return;

      const finalVars = matchedVariables.map(i => processVariable(i));
      processedParams.value = finalVars.reduce((acc, variable) => {
        acc[variable] = '';
        return acc;
      }, {});
    };

    const resetTemplate = () => {
      emit('resetTemplate');
    };

    const sendMessage = () => {
      v$.value.$touch();
      if (v$.value.$invalid) return;

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

    onMounted(generateVariables);

    return {
      processedParams,
      variables,
      templateString,
      processedString,
      v$,
      resetTemplate,
      sendMessage,
    };
  },
};
</script>

<template>
  <div class="w-full">
    <textarea
      v-model="processedString"
      rows="4"
      readonly
      class="template-input"
    />
    <div v-if="variables" class="p-2.5">
      <p class="text-sm font-semibold mb-2.5">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.VARIABLES_LABEL') }}
      </p>
      <div
        v-for="(variable, key) in processedParams"
        :key="key"
        class="items-center flex mb-2.5"
      >
        <span
          class="bg-n-alpha-black2 text-n-slate-12 inline-block rounded-md text-xs py-2.5 px-6"
        >
          {{ key }}
        </span>
        <woot-input
          v-model="processedParams[key]"
          type="text"
          class="flex-1 text-sm ml-2.5"
          :styles="{ marginBottom: 0 }"
        />
      </div>
      <p
        v-if="v$.$dirty && v$.$invalid"
        class="bg-n-ruby-9/20 rounded-md text-n-ruby-9 p-2.5 text-center"
      >
        {{ $t('WHATSAPP_TEMPLATES.PARSER.FORM_ERROR_MESSAGE') }}
      </p>
    </div>
    <footer class="flex justify-end gap-2">
      <NextButton
        faded
        slate
        type="reset"
        :label="$t('WHATSAPP_TEMPLATES.PARSER.GO_BACK_LABEL')"
        @click="resetTemplate"
      />
      <NextButton
        type="button"
        :label="$t('WHATSAPP_TEMPLATES.PARSER.SEND_MESSAGE_LABEL')"
        @click="sendMessage"
      />
    </footer>
  </div>
</template>
