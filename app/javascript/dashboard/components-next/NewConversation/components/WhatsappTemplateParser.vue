<script setup>
import { computed, ref, onMounted } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { requiredIf } from '@vuelidate/validators';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  template: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['sendMessage', 'back']);

const processedParams = ref({});

const templateString = computed(() => {
  return props.template?.components?.find(
    component => component.type === 'BODY'
  ).text;
});

const allKeysRequired = value => {
  const keys = Object.keys(value);
  return keys.every(key => value[key]);
};

const variables = computed(() => {
  return templateString.value.match(/{{([^}]+)}}/g);
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

onMounted(() => {
  generateVariables();
});
</script>

<template>
  <div
    class="absolute top-full mt-1.5 left-0 flex flex-col gap-4 px-4 pt-6 pb-5 items-start w-[460px] h-auto bg-n-solid-2 border border-n-strong shadow-sm rounded-lg"
  >
    <span class="text-sm text-n-slate-12">
      {{ `WhatsApp template: ${template.name}` }}
    </span>
    <p class="mb-0 text-sm text-n-slate-11">{{ processedString }}</p>

    <span
      v-if="processedParams.length"
      class="text-sm font-medium text-n-slate-12"
    >
      {{ 'Variables' }}
    </span>

    <div
      v-for="(variable, key) in processedParams"
      :key="key"
      class="flex flex-col w-full gap-4"
    >
      <span class="w-8 h-8 text-sm text-left text-n-slate-12">{{ key }}</span>
      <Input v-model="processedParams[key]" custom-input-class="!h-8" />
    </div>

    <div class="flex items-end justify-between w-full gap-3 h-14">
      <Button
        label="Go back"
        color="slate"
        class="w-full font-medium"
        @click="emit('back')"
      />
      <Button
        label="Send message"
        class="w-full font-medium"
        @click="sendMessage"
      />
    </div>
  </div>
</template>
