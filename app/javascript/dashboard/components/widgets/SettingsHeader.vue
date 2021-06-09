<template>
  <div class="column page-top-banner">
    <h2 class="page-sub-title">
      {{ headerTitle }}
    </h2>
    <p v-if="headerContent" class="small-12 column">
      {{ headerContent }}
    </p>
    <slot></slot>
  </div>
</template>

<script>
export default {
  props: {
    headerTitle: {
      type: String,
      default: '',
    },
    headerContent: {
      type: String,
      default: '',
    },
  },
};
</script>
