<script setup>
import { computed, watch } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';

import Input from 'dashboard/components-next/input/Input.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

defineProps({
  nameLabel: {
    type: String,
    default: '',
  },
  namePlaceholder: {
    type: String,
    default: '',
  },
  descriptionLabel: {
    type: String,
    default: '',
  },
  descriptionPlaceholder: {
    type: String,
    default: '',
  },
  statusLabel: {
    type: String,
    default: '',
  },
  statusPlaceholder: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['validationChange']);

const policyName = defineModel('policyName', {
  type: String,
  default: '',
});

const description = defineModel('description', {
  type: String,
  default: '',
});

const enabled = defineModel('enabled', {
  type: Boolean,
  default: true,
});

const validationRules = {
  policyName: { required, minLength: minLength(1) },
  description: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(validationRules, { policyName, description });

const isValid = computed(() => !v$.value.$invalid);

watch(
  isValid,
  () => {
    emit('validationChange', {
      isValid: isValid.value,
    });
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex flex-col gap-4 pb-4">
    <!-- Policy Name Field -->
    <div class="flex items-center gap-6">
      <label class="text-sm font-medium text-n-slate-12 min-w-[120px]">
        {{ nameLabel }}
      </label>
      <div class="flex-1">
        <Input
          v-model="policyName"
          type="text"
          :placeholder="namePlaceholder"
        />
      </div>
    </div>

    <!-- Description Field -->
    <div class="flex items-center gap-6">
      <label class="text-sm font-medium text-n-slate-12 min-w-[120px]">
        {{ descriptionLabel }}
      </label>
      <div class="flex-1">
        <Input
          v-model="description"
          type="text"
          :placeholder="descriptionPlaceholder"
        />
      </div>
    </div>

    <!-- Status Field -->
    <div class="flex items-center gap-6">
      <label class="text-sm font-medium text-n-slate-12 min-w-[120px]">
        {{ statusLabel }}
      </label>
      <div class="flex items-center gap-3">
        <Switch v-model="enabled" />
        <span class="text-sm text-n-slate-11">
          {{ statusPlaceholder }}
        </span>
      </div>
    </div>
  </div>
</template>
