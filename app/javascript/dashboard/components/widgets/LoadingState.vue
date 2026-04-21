<script setup>
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

defineProps({
  message: { type: String, default: '' },
});
</script>

<template>
  <div class="flex items-center justify-center p-8">
    <h6
      class="flex items-center gap-3 text-base text-center w-100 text-s-muted"
    >
      <span class="text-body-main !text-base text-s-primary">
        {{ message }}
      </span>
      <Spinner class="text-s-brand" />
    </h6>
  </div>
</template>
