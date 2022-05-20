<template>
  <div class="medium-12 columns">
    <textarea v-model="generateMessage" rows="4" readonly></textarea>
    <div>
      <div class="template__variables-container">
        <p class="variables-label">
          {{ $t('WHATSAPP_TEMPLATES.PARSER.VARIABLES_LABEL') }}
        </p>
        <div
          v-for="variable in message.variables"
          :key="variable.name"
          class="template__variable-item"
        >
          <span class="label secondary">
            {{ variable.name }}
          </span>
          <input
            v-model="variable.value"
            type="text"
            class="variable-input"
            :placeholder="
              $t('WHATSAPP_TEMPLATES.PARSER.VARIABLE_PLACEHOLDER', {
                variable: variable.name,
              })
            "
          />
        </div>
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
export default {
  props: {
    template: {
      type: Object,
      default: () => {},
    },
  },
  data() {
    return {
      message: this.template.message,
    };
  },
  computed: {
    generateMessage() {
      const variables = this.message.variables.reduce((acc, variable) => {
        acc[variable.name] = variable.value;
        return acc;
      }, {});
      return this.message.content.replace(/{([^}]+)}/g, (match, variable) => {
        return variables[variable] || `{${variable}}`;
      });
    },
  },
  methods: {
    sendMessage() {
      this.$emit('sendMessage', this.generateMessage);
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
</style>
