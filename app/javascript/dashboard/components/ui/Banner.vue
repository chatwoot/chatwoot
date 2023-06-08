<template>
  <div class="banner" :class="bannerClasses">
    <span class="banner-message">
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
    <div class="actions">
      <woot-button
        v-if="hasActionButton"
        size="tiny"
        icon="arrow-right"
        :variant="actionButtonVariant"
        color-scheme="primary"
        class-names="banner-action__button"
        @click="onClick"
      >
        {{ actionButtonLabel }}
      </woot-button>
      <woot-button
        v-if="hasCloseButton"
        size="tiny"
        :color-scheme="colorScheme"
        icon="dismiss-circle"
        class-names="banner-action__button"
        @click="onClickClose"
      >
        {{ $t('GENERAL_SETTINGS.DISMISS') }}
      </woot-button>
    </div>
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
    actionButtonVariant: {
      type: String,
      default: '',
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
      const classList = [this.colorScheme, `banner-align-${this.align}`];

      if (this.hasActionButton || this.hasCloseButton) {
        classList.push('has-button');
      }
      return classList;
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
  --x-padding: var(--space-normal);
  --y-padding: var(--space-slab);

  display: flex;
  gap: var(--x-padding);
  color: var(--white);
  font-size: var(--font-size-mini);
  padding: var(--y-padding) var(--x-padding);
  justify-content: center;

  &.primary {
    background: var(--w-500);
    .banner-action__button {
      background: var(--w-600);
      border: none;
      color: var(--white);

      &:hover {
        background: var(--w-800);
      }
    }
  }

  &.secondary {
    background: var(--s-200);
    color: var(--s-800);
    a {
      color: var(--s-800);
    }
  }

  &.alert {
    background: var(--r-500);
    .banner-action__button {
      background: var(--r-700);
      border: none;
      color: var(--white);

      &:hover {
        background: var(--r-800);
      }
    }
  }

  &.warning {
    background: var(--y-600);
    color: var(--y-500);
    a {
      color: var(--y-500);
    }
  }

  &.gray {
    background: var(--b-500);
    .banner-action__button {
      color: var(--white);
    }
  }

  a {
    margin-left: var(--space-smaller);
    text-decoration: underline;
    color: var(--white);
    font-size: var(--font-size-mini);
  }

  .banner-action__button {
    ::v-deep .button__content {
      white-space: nowrap;
    }
  }

  .banner-message {
    display: flex;
    align-items: center;
  }

  .actions {
    display: flex;
    gap: var(--space-smaller);
    right: var(--y-padding);
  }
}
</style>
