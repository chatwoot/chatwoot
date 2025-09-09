<script setup>
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
