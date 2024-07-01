<template>
  <div class="w-full">
    <textarea v-model="processedString" rows="4" readonly class="template-input" />
    <div v-if="hasVariables" class="template__variables-container">
      <p class="variables-label">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.VARIABLES_LABEL') }}
      </p>
      <div v-for="(variable, key) in processedParams" :key="key" class="template__variable-item">
        <span class="variable-label">
          {{ key }}
        </span>
        <woot-input v-model="processedParams[key]" type="text" class="variable-input" :styles="{ marginBottom: 0 }" />
      </div>
      <p v-if="$v.$dirty && $v.$invalid" class="error">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.FORM_ERROR_MESSAGE') }}
      </p>
    </div>
    <footer>
      <woot-button variant="smooth" @click="$emit('resetTemplate')">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.GO_BACK_LABEL') }}
      </woot-button>
      <woot-button type="button" @click="sendMessage">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.SEND_MESSAGE_LABEL') }}
      </woot-button>
    </footer>
  </div>
</template>

<script>
const allKeysRequired = value => {
  const keys = Object.keys(value);
  return keys.every(key => value[key]);
};
import { requiredIf } from 'vuelidate/lib/validators';
export default {
  props: {
    template: {
      type: Object,
      default: () => { },
    },
  },
  validations: {
    processedParams: {
      requiredIfKeysPresent: requiredIf('hasVariables'),
      allKeysRequired,
    },
  },
  data() {
    return {
      processedParams: {},
    };
  },
  computed: {
    hasVariables() {
      return Object.keys(this.processedParams).length > 0;
    },
    templateString() {
      return this.template.components.find(
        component => component.type === 'BODY'
      ).text;
    },
    processedString() {
      return this.templateString.replace(/{{([^}]+)}}/g, (match, variable) => {
        const variableKey = this.processVariable(variable);
        return this.processedParams[variableKey] || `{{${variable}}}`;
      });
    },
  },
  mounted() {
    this.generateVariables();
  },
  methods: {
    sendMessage() {
      this.$v.$touch();
      if (this.$v.$invalid) return;
      const payload = {
        message: this.processedString,
        templateParams: {
          name: this.template.name,
          category: this.template.category,
          language: this.template.language,
          namespace: this.template.namespace,
          processed_params: this.processedParams,
        },
      };
      this.$emit('sendMessage', payload);
    },
    processVariable(str) {
      return str.replace(/{{|}}/g, '');
    },
    generateVariables() {
      this.processedParams = {};

      // Process BODY type components
      const bodyVariables = this.templateString.match(/{{([^}]+)}}/g);
      if (bodyVariables) {
        const variables = bodyVariables.map(i => this.processVariable(i));
        variables.forEach(variable => {
          this.processedParams[variable] = '';
        });
      }

      // Process BUTTONS type components and HEADER component
      this.template.components.forEach((component) => {
        if (component.type === 'BUTTONS') {
          component.buttons.forEach((button, buttonIndex) => {
            this.extractButtonPlaceholders(button, buttonIndex);
          });
        }
        if (component.type === 'HEADER') {
          const headerVariables = component.text.match(/{{([^}]+)}}/g);
          if (headerVariables) {
            const variables = headerVariables.map(i => 'header|' + this.processVariable(i));
            variables.forEach(variable => {
              this.processedParams[variable] = '';
            });
          }
        }
      });
    },
    extractButtonPlaceholders(button, buttonIndex) {

      var alltext = button.text + ' ' + button.url;

      // Extract placeholders from button text
      if (alltext) {
        const textPlaceholders = alltext.match(/{{([^}]+)}}/g);
        this.addPlaceholdersToParams(textPlaceholders, button.type, buttonIndex);
      }
    },
    addPlaceholdersToParams(placeholders, buttonType, buttonIndex) {
      if (placeholders) {
        placeholders.forEach((placeholder, placeholderIndex) => {
          const key = `button|${buttonIndex}|${buttonType}|${placeholderIndex}`;
          this.processedParams[key] = '';
        });
      }
    },
  },
};
</script>

<style scoped lang="scss">
.template__variables-container {
  @apply p-2.5;
}

.variables-label {
  @apply text-sm font-semibold mb-2.5;
}

.template__variable-item {
  @apply items-center flex mb-2.5;

  .label {
    @apply text-xs;
  }

  .variable-input {
    @apply flex-1 text-sm ml-2.5;
  }

  .variable-label {
    @apply bg-slate-75 dark:bg-slate-700 text-slate-700 dark:text-slate-100 inline-block rounded-md text-xs py-2.5 px-6;
  }
}

footer {
  @apply flex justify-end;

  button {
    @apply ml-2.5;
  }
}

.error {
  @apply bg-red-100 dark:bg-red-100 rounded-md text-red-800 dark:text-red-800 p-2.5 text-center;
}

.template-input {
  @apply bg-slate-25 dark:bg-slate-900 text-slate-700 dark:text-slate-100;
}
</style>
