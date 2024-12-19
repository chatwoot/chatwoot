<script setup>
import BackButton from 'dashboard/components/widgets/BackButton.vue';

defineProps({
  headerTitle: {
    required: true,
    type: String,
  },
  headerDescription: {
    type: String,
    default: '',
  },
  hasBackButton: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <div class="flex items-center justify-between w-full h-20 gap-2">
    <div class="flex items-center gap-2">
      <BackButton v-if="hasBackButton" compact />
      <span class="text-xl font-medium text-n-slate-12">
        {{ headerTitle }}
      </span>
    </div>
    <slot />
  </div>
  <p
    v-if="headerDescription"
    class="text-n-slate-12 mb-8 border-b border-n-weak pb-8"
  >
    {{ headerDescription }}
  </p>
</template>
