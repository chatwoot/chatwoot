<template>
  <div class="row empty-state">
    <h3 class="title">
      {{ title }}
    </h3>
    <p class="message">
      {{ message }}
    </p>
    <slot />
  </div>
</template>
<script>
export default {
  props: {
    title: { type: String, default: '' },
    message: { type: String, default: '' },
    buttonText: { type: String, default: '' },
  },
};
</script>
