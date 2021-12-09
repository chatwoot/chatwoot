<template>
  <div class="row loading-state">
    <h6 class="message">{{ message }}<span class="spinner"></span></h6>
  </div>
</template>
<script>
export default {
  props: {
    message: String,
  },
};
</script>
