<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
defineProps({
  title: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  buttonLabel: {
    type: String,
    default: '',
  },

  buttonIcon: {
    type: String,
    default: 'edit',
  },
});
defineEmits(['open']);
</script>

<template>
  <div
    class="flex justify-between items-center shadow outline-1 outline outline-n-container rounded-2xl bg-n-solid-2 px-6 py-5"
  >
    <div>
      <h6 class="text-n-slate-12">{{ title }}</h6>
      <p class="mb-0 text-n-slate-11">
        {{ description }}
      </p>
    </div>
    <div>
      <Button
        :label="buttonLabel"
        variant="faded"
        size="sm"
        @click="$emit('open')"
      />
    </div>
  </div>
</template>
