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
    actionButtonIcon: {
      type: String,
      default: 'arrow-right',
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
  emits: ['primaryAction', 'close'],
  computed: {
    bannerClasses() {
      const classList = [this.colorScheme];

      if (this.hasActionButton || this.hasCloseButton) {
        classList.push('has-button');
      }
      return classList;
    },
  },
  methods: {
    onClick(e) {
      this.$emit('primaryAction', e);
    },
    onClickClose(e) {
      this.$emit('close', e);
    },
  },
};
</script>

<template>
  <div
    class="flex items-center justify-center h-12 gap-4 px-4 py-3 text-xs text-white banner dark:text-white woot-banner"
    :class="bannerClasses"
  >
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
        :icon="actionButtonIcon"
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

<style lang="scss" scoped>
.banner {
  &.primary {
    @apply bg-woot-500 dark:bg-woot-500;
    .banner-action__button {
      @apply bg-woot-600 dark:bg-woot-600 border-none text-white;

      &:hover {
        @apply bg-woot-700 dark:bg-woot-700;
      }
    }
  }

  &.secondary {
    @apply bg-slate-200 dark:bg-slate-300 text-slate-800 dark:text-slate-800;
    a {
      @apply text-slate-800 dark:text-slate-800;
    }
  }

  &.alert {
    @apply bg-red-500 dark:bg-red-500;
    .banner-action__button {
      @apply bg-red-700 dark:bg-red-700 border-none text-white dark:text-white;

      &:hover {
        @apply bg-red-800 dark:bg-red-800;
      }
    }
  }

  &.warning {
    @apply bg-yellow-500 dark:bg-yellow-500 text-yellow-500 dark:text-yellow-500;
    a {
      @apply text-yellow-500 dark:text-yellow-500;
    }
  }

  &.gray {
    @apply text-black-500 dark:text-black-500;
    .banner-action__button {
      @apply text-white dark:text-white;
    }
  }

  a {
    @apply ml-1 underline text-white dark:text-white text-xs;
  }

  .banner-action__button {
    ::v-deep .button__content {
      @apply whitespace-nowrap;
    }
  }

  .banner-message {
    @apply flex items-center;
  }

  .actions {
    @apply flex gap-1 right-3;
  }
}
</style>
