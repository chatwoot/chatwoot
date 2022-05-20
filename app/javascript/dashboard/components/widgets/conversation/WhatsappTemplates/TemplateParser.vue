<template>
  <div class="medium-12 columns">
    <textarea v-model="generateMessage" rows="4" readonly></textarea>
    <div>
      <div class="template__variables-container">
        <p class="variables-label">Variables</p>
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
            :placeholder="`Enter ${variable.name} value`"
          />
        </div>
      </div>
    </div>
    <footer>
      <woot-button variant="smooth" @click="$emit('resetTemplate')">
        Go Back
      </woot-button>
      <woot-button>Send</woot-button>
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
