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
  <div class="flex items-center">
    <i
      v-if="showSuccess"
      class="ion-checkmark-circled text-3xl text-green-500 mr-1"
    />
    <i v-if="showError" class="ion-android-alert text-3xl text-red-600 mr-1" />
    <label class="text-base font-medium text-n-slate-12 mt-4 mb-4">
      {{ message }}
    </label>
  </div>
</template>
