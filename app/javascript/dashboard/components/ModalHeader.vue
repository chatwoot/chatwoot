<template>
  <div class="column page-top-bar">
    <img v-if="headerImage" :src="headerImage" alt="No image" />
    <h2 class="page-sub-title">
      {{ headerTitle }}
    </h2>
    <p v-if="headerContent" class="small-12 column">
      {{ headerContent }}
    </p>
    <slot />
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
    headerImage: {
      type: String,
      default: '',
    },
  },
};
</script>
