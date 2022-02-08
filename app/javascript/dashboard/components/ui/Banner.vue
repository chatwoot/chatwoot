<template>
  <div class="banner" :class="bannerClasses">
    <span>
      {{ bannerMessage }}
      <a
        v-if="hrefLink"
        :href="hrefLink"
        rel="noopener noreferrer nofollow"
        target="_blank"
      >
        {{ hrefLinkText }}
      </a>
    </span>
    <woot-button
      v-if="hasActionButton"
      size="small"
      variant="link"
      icon="arrow-right"
      color-scheme="primary"
      class-names="banner-action__button"
      @click="onClick"
    >
      {{ actionButtonLabel }}
    </woot-button>
    <woot-button
      v-if="hasCloseButton"
      size="small"
      variant="link"
      color-scheme="warning"
      icon="dismiss-circle"
      class-names="banner-action__button"
      @click="onClickClose"
    >
    </woot-button>
  </div>
</template>

<script>
export default {
  props: {
    bannerMessage: {
      type: String,
      default: '',
    },
    hrefLink: {
      type: String,
      default: '',
    },
    hrefLinkText: {
      type: String,
      default: '',
    },
    hasActionButton: {
      type: Boolean,
      default: false,
    },
    actionButtonLabel: {
      type: String,
      default: '',
    },
    colorScheme: {
      type: String,
      default: '',
    },
    hasCloseButton: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    bannerClasses() {
      return [this.colorScheme];
    },
  },
  methods: {
    onClick(e) {
      this.$emit('click', e);
    },
    onClickClose(e) {
      this.$emit('close', e);
    },
  },
};
</script>

<style lang="scss" scoped>
.banner {
  display: flex;
  color: var(--white);
  font-size: var(--font-size-mini);
  padding: var(--space-slab) var(--space-normal);
  justify-content: center;
  position: sticky;

  &.secondary {
    background: var(--s-300);
  }

  &.alert {
    background: var(--r-400);
  }

  &.warning {
    background: var(--y-800);
    color: var(--s-600);
    a {
      color: var(--s-600);
    }
  }

  &.gray {
    background: var(--b-500);
  }

  a {
    text-decoration: underline;
    color: var(--white);
    font-size: var(--font-size-mini);
  }

  .banner-action__button {
    margin: 0 var(--space-smaller);

    ::v-deep .button__content {
      white-space: nowrap;
    }
  }
}
</style>
