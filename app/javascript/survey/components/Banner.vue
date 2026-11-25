<script>
export default {
  props: {
    showSuccess: {
      type: Boolean,
      default: false,
    },
    showError: {
      type: Boolean,
      default: false,
    },
    message: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <!-- The rating and the feedback both land here after a write, and neither moves focus, so
       without a live region a screen reader never learns the submission went through. -->
  <div class="flex items-center gap-1" role="status" aria-live="polite">
    <span
      v-if="showSuccess"
      class="i-ri-checkbox-circle-fill text-2xl text-n-teal-10"
    />
    <span
      v-if="showError"
      class="i-ri-error-warning-fill text-2xl text-n-ruby-10"
    />
    <p class="text-base font-medium text-n-slate-12 my-4">
      {{ message }}
    </p>
  </div>
</template>
