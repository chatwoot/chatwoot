<template>
  <div class="column">
    <h2 class="page-sub-title">
      {{ headerTitle }}
    </h2>
    <p v-dompurify-html="headerContent" class="small-12 column"></p>
  </div>
</template>

<script>
export default {
  props: {
    headerTitle: { type: String, default: '' },
    headerContent: { type: String, default: '' },
  },
};
</script>
