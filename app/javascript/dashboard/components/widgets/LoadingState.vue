<template>
  <div class="row loading-state">
    <h6 class="message">{{ message }}<span class="spinner" /></h6>
  </div>
</template>
<script>
export default {
  props: {
    message: { type: String, default: '' },
  },
};
</script>
