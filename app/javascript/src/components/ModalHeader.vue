<template>
  <div class="column page-top-bar">
    <img :src="headerImage" alt="No image" v-if="headerImage"/>
    <h2 class="page-sub-title">
      {{headerTitle}}
    </h2>
    <p class="small-12 column">
        {{headerContent}}
    </p>
  </div>
</template>

<script>
export default {
  props: {
    headerTitle: String,
    headerContent: String,
    headerImage: String,
  },
};
</script>
