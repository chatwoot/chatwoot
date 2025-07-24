<script setup>
import Index from '../../../routes/dashboard/settings/agents/Index.vue';
import { defineProps } from 'vue';

defineProps({
  currentStep: {
    type: Number,
    required: true,
  },
  stepNumber: {
    type: Number,
    required: true,
  },
});
</script>

<template>
  <div>
    <Index v-if="currentStep === stepNumber" />
  </div>
</template>
