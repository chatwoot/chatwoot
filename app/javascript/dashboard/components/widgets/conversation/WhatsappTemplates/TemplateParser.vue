<template>
  <div class="w-full">
    <div class="p-2.5">
      <div
        class="p-2.5 bg-woot-25 dark:bg-modal-backdrop-light border rounded-md max-h-24 overflow-auto"
      >
        <vue-markdown-it :source="processedString" />
      </div>
    </div>
    <div v-if="variables" class="template__variables-container">
      <p class="variables-label">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.VARIABLES_LABEL') }}
      </p>
      <div
        v-for="(variable, key) in processedParams"
        :key="key"
        class="template__variable-item"
      >
        <span class="variable-label">
          {{ key }}
        </span>
        <input-select
          v-if="options.length > 0"
          v-model="processedParams[key]"
          type="text"
          class="variable-input"
          :styles="{ marginBottom: 0 }"
          :suggestions="options"
          :selected="selectedParams && selectedParams[key]"
          @input="variableChanged()"
          @variable="value => eventVariableChanged(value, key)"
        />
        <woot-input
          v-else
          v-model="processedParams[key]"
          type="text"
          class="variable-input"
          :styles="{ marginBottom: 0 }"
          @input="variableChanged()"
        />
      </div>
      <p v-if="$v.$dirty && $v.$invalid" class="error">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.FORM_ERROR_MESSAGE') }}
      </p>
    </div>
    <footer>
      <woot-button
        :disabled="disableResetButton"
        variant="smooth"
        type="button"
        @click="$emit('resetTemplate')"
      >
        {{ $t('WHATSAPP_TEMPLATES.PARSER.GO_BACK_LABEL') }}
      </woot-button>
      <woot-button v-if="showMessageButton" type="button" @click="sendMessage">
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
import InputSelect from '../../../../../v3/components/Form/InputSelect.vue';
import VueMarkdownIt from 'vue-markdown-it';

export default {
  components: {
    InputSelect,
    VueMarkdownIt,
  },

  props: {
    template: {
      type: Object,
      default: () => {},
    },
    options: {
      type: Array,
      default: () => [],
    },
    selectedParams: {
      type: Object,
      default: null,
    },
    selectedEventParams: {
      type: Object,
      default: null,
    },
    showMessageButton: {
      type: Boolean,
      default: true,
    },
  },
  validations: {
    processedParams: {
      requiredIfKeysPresent: requiredIf('variables'),
      allKeysRequired,
    },
  },
  data() {
    return {
      processedParams: {},
      disableResetButton: true,
      eventVariables: {},
    };
  },
  computed: {
    variables() {
      const variables = this.templateString.match(/{{([^}]+)}}/g);
      return variables;
    },
    templateString() {
      return this.template.components.find(
        component => component.type === 'BODY'
      ).text;
    },

    processedString() {
      return this.templateString.replace(/{{([^}]+)}}/g, (match, variable) => {
        const variableKey = this.processVariable(variable);
        const processedParam = this.eventVariables[variableKey]
          ? `==${this.processedParams[variableKey]}==`
          : `**${this.processedParams[variableKey]}**`;

        return this.processedParams[variableKey]
          ? processedParam
          : `**{{${variable}}}**`;
      });
    },
  },

  mounted() {
    this.generateVariables();
    this.setDisableResetButton();

    if (this.selectedParams) {
      this.processedParams = this.selectedParams;
    }

    if (this.selectedEventParams) {
      console.log(this.selectedEventParams);
      this.eventVariables = this.selectedEventParams;
    }
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
      const matchedVariables = this.templateString.match(/{{([^}]+)}}/g);
      if (!matchedVariables) return;

      const variables = matchedVariables.map(i => this.processVariable(i));
      this.processedParams = variables.reduce((acc, variable) => {
        acc[variable] = '';
        return acc;
      }, {});
    },
    variableChanged() {
      this.$emit('changeVariable', this.processedParams);
      Object.keys(this.processedParams).forEach(key => {
        this.$set(this.processedParams, key, this.processedParams[key]);
      });
    },
    eventVariableChanged(value, key) {
      this.$set(this.eventVariables, key, value);
      this.$emit('changeEventVariable', this.eventVariables);
    },

    setDisableResetButton() {
      setTimeout(() => {
        this.disableResetButton = false;
      }, 100);
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
