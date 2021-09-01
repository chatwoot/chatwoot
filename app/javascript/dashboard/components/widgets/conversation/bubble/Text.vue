<template>
  <div class="message-text__wrap">
    <div class="text-content" v-html="message"></div>
  </div>
</template>

<script>
export default {
  props: {
    message: {
      type: String,
      default: '',
    },
    readableTime: {
      type: String,
      default: '',
    },
    isEmail: {
      type: Boolean,
      default: true,
    },
  },
};
</script>
<style lang="scss">
.text-content {
  overflow: auto;

  &::v-deep {
    ul,
    ol {
      margin-left: var(--space-normal);
    }
  }
  table {
    all: revert;

    td {
      all: revert;
    }

    tr {
      all: revert;
    }
  }

  h1,
  h2,
  h3,
  h4,
  h5,
  h6 {
    font-size: var(--font-size-normal);
  }
}
</style>
