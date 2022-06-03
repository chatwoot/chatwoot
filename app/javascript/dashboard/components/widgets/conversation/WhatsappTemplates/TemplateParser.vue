<template>
  <div class="medium-12 columns">
    <textarea v-model="processedString" rows="4" readonly></textarea>
    <div>
      <div class="template__variables-container">
        <p class="variables-label">
          {{ $t('WHATSAPP_TEMPLATES.PARSER.VARIABLES_LABEL') }}
        </p>
        <div
          v-for="(variable, key) in processedParams"
          :key="key"
          class="template__variable-item"
        >
          <span class="label secondary">
            {{ key }}
          </span>
          <woot-input
            v-model="processedParams[key]"
            type="text"
            class="variable-input"
          />
        </div>
        <p v-if="showRequiredMessage" class="error">
          All variables are required
        </p>
      </div>
    </div>
    <footer>
      <woot-button variant="smooth" @click="$emit('resetTemplate')">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.GO_BACK_LABEL') }}
      </woot-button>
      <woot-button @click="sendMessage">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.SEND_MESSAGE_LABEL') }}
      </woot-button>
    </footer>
  </div>
</template>

<script>
import { required } from 'vuelidate/lib/validators';

const allKeysRequired = value => {
  const keys = Object.keys(value);
  return keys.every(key => value[key]);
};
export default {
  props: {
    template: {
      type: Object,
      default: () => {},
    },
  },
  validations: {
    processedParams: {
      required,
      allKeysRequired,
    },
  },
  data() {
    return {
      message: this.template.message,
      processedParams: {},
      showRequiredMessage: false,
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
      if (this.$v.$invalid) {
        this.showRequiredMessage = true;
        return;
      }
      const message = {
        message: this.processedString,
        templateParams: {
          name: this.template.name,
          category: this.template.category,
          language: this.template.language,
          namespace: this.template.namespace,
          processed_params: this.processedParams,
        },
      };
      this.$emit('sendMessage', message);
    },
    processVariable(str) {
      return str.replace(/{{|}}/g, '');
    },
    generateVariables() {
      const templateString = this.template.components.find(
        component => component.type === 'BODY'
      ).text;
      const variables = templateString.match(/{{([^}]+)}}/g).map(variable => {
        return this.processVariable(variable);
      });
      this.processedParams = variables.reduce((acc, variable) => {
        acc[variable] = '';
        return acc;
      }, {});
    },
  },
};
</script>

<style scoped lang="scss">
.template__variables-container {
  padding: var(--space-one);
}
.variables-label {
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-bold);
  margin-bottom: var(--space-one);
}
.template__variable-item {
  display: flex;
  align-items: center;
  .label {
    font-size: var(--font-size-mini);
  }
  .variable-input {
    flex: 1;
    margin-left: var(--space-one);
    font-size: var(--font-size-small);
  }
}

footer {
  display: flex;
  justify-content: flex-end;
  button {
    margin-left: var(--space-one);
  }
}
.error {
  color: var(--r-400);
  text-align: right;
}
</style>
