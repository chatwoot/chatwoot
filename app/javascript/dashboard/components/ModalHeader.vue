<template>
  <div class="column page-top-bar">
    <img v-if="headerImage" :src="headerImage" alt="No image" />
    <h2
      ref="modalHeaderTitle"
      class="text-slate-800 text-lg dark:text-slate-100"
    >
      {{ headerTitle }}
    </h2>
    <p
      v-if="headerContent"
      ref="modalHeaderContent"
      class="small-12 column wrap-content"
    >
      {{ headerContent }}
      <span v-if="headerContentValue" class="content-value">
        {{ headerContentValue }}
      </span>
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
    headerContentValue: {
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
<style scoped lang="scss">
.wrap-content {
  word-wrap: break-word;
  margin-top: var(--space-small);

  .content-value {
    font-weight: var(--font-weight-bold);
  }
}
</style>
