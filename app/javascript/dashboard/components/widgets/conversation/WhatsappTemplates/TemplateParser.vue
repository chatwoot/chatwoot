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

import Input from 'dashboard/components-next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
    // eslint-disable-next-line vue/no-reserved-component-names
    Input,
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
        allVariables.header.media_type =
          headerComponent.value.format.toLowerCase();
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

    const resetTemplate = () => {
      emit('resetTemplate');
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
      if (
        props.template?.category === 'AUTHENTICATION' &&
        finalParams.buttons
      ) {
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

    onMounted(generateVariables);

    return {
      processedParams,
      variables,
      templateString,
      processedString,
      headerComponent,
      hasMediaHeader,
      v$,
      resetTemplate,
      sendMessage,
      updateMediaUrl,
    };
  },
};
</script>

<template>
  <div class="w-full">
    <div
      v-if="template"
      class="flex flex-col gap-4 p-4 mb-4 rounded-lg bg-n-alpha-black2"
    >
      <div class="flex justify-between items-center">
        <h3 class="text-sm font-medium text-n-slate-12">
          {{ template.name }}
        </h3>
        <span class="text-xs text-n-slate-11">
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
        {{ template.category || 'UTILITY' }}
      </div>
    </div>

    <div v-if="variables || hasMediaHeader">
      <!-- Media Header Section -->
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
            :placeholder="`Enter ${headerComponent.format.toLowerCase()} URL`"
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
                ? 'Enter 4-8 digit OTP'
                : key === 'expiry_minutes'
                  ? 'Enter expiry minutes'
                  : `Enter ${key} value`
            "
          />
        </div>
      </div>

      <!-- Button Variables Section -->
      <div v-if="processedParams.buttons">
        <p class="mb-2.5 text-sm font-semibold">
          {{
            $t('WHATSAPP_TEMPLATES.PARSER.BUTTON_PARAMETERS') ||
            'Button Parameters'
          }}
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
                ? 'Enter coupon code (max 15 chars)'
                : 'Enter button parameter'
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
    <footer class="flex gap-2 justify-end">
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
