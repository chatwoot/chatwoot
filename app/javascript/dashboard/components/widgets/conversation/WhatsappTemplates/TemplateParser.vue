<template>
  <div class="w-full">
    <textarea
      v-model="processedString"
      rows="4"
      readonly
      class="template-input"
    />
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
        <woot-input
          v-model="processedParams[key]"
          type="text"
          class="variable-input"
          :styles="{ marginBottom: 0 }"
        />
      </div>
      <p v-if="v$.$dirty && v$.$invalid" class="error">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.FORM_ERROR_MESSAGE') }}
      </p>
    </div>
    <footer>
      <woot-button variant="smooth" @click="resetTemplate">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.GO_BACK_LABEL') }}
      </woot-button>
      <woot-button type="button" @click="sendMessage">
        {{ $t('WHATSAPP_TEMPLATES.PARSER.SEND_MESSAGE_LABEL') }}
      </woot-button>
    </footer>
  </div>
</template>

<script setup>
import { useVuelidate } from '@vuelidate/core';
import { computed, onMounted, ref } from 'vue';
import { requiredIf } from '@vuelidate/validators';

const processVariable = str => {
  return str.replace(/{{|}}/g, '');
};

const allKeysRequired = value => {
  const keys = Object.keys(value);
  return keys.every(key => value[key]);
};

const props = defineProps({
  template: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['sendMessage', 'resetTemplate']);
const processedParams = ref({});

const templateString = computed(() => {
  return props.template.value.components.find(
    component => component.type === 'BODY'
  ).text;
});

const variables = computed(() => {
  return templateString.value.match(/{{([^}]+)}}/g);
});

const processedString = computed(() => {
  return templateString.value.replace(/{{([^}]+)}}/g, (match, variable) => {
    const variableKey = processVariable(variable);
    return this.processedParams[variableKey] || `{{${variable}}}`;
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

  const finalVars = matchedVariables.map(i => this.processVariable(i));
  processedParams.value = finalVars.reduce((acc, variable) => {
    acc[variable] = '';
    return acc;
  }, {});
};

const resetTemplate = () => {
  emit('resetTemplate');
};

const sendMessage = () => {
  v$.$touch();
  if (v$.$invalid) return;

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
