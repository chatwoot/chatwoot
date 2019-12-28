<template>
  <div class="column">
    <h2 class="page-sub-title">
      {{ headerTitle }}
    </h2>
    <p class="small-12 column" v-html="headerContent"></p>
  </div>
</template>

<script>
export default {
  props: {
    headerTitle: String,
    headerContent: String,
  },
};
</script>
