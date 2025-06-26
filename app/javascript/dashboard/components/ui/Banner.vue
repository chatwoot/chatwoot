<script>
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
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
      default: 'faded',
    },
    actionButtonLabel: {
      type: String,
      default: '',
    },
    actionButtonIcon: {
      type: String,
      default: 'i-lucide-arrow-right',
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
    // TODO - Remove this method when we standardize
    // the button color and variant names
    getButtonColor() {
      const colorMap = {
        primary: 'blue',
        secondary: 'blue',
        alert: 'ruby',
        warning: 'amber',
      };

      return colorMap[this.colorScheme] || 'blue';
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
      <NextButton
        v-if="hasActionButton"
        xs
        :icon="actionButtonIcon"
        :variant="actionButtonVariant"
        :color="getButtonColor"
        :label="actionButtonLabel"
        @click="onClick"
      />
      <NextButton
        v-if="hasCloseButton"
        xs
        icon="i-lucide-circle-x"
        :color="getButtonColor"
        :label="$t('GENERAL_SETTINGS.DISMISS')"
        @click="onClickClose"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.banner {
  &.primary {
    @apply bg-woot-500 dark:bg-woot-500;
  }

  &.secondary {
    @apply bg-n-slate-3 dark:bg-n-solid-3 text-n-slate-12;
    a {
      @apply text-slate-800 dark:text-slate-800;
    }
  }

  &.alert {
    @apply bg-n-ruby-3 text-n-ruby-12;

    a {
      @apply text-n-ruby-12;
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
  }

  a {
    @apply ml-1 underline text-white dark:text-white text-xs;
  }

  .banner-message {
    @apply flex items-center;
  }

  .actions {
    @apply flex gap-1 right-3;
  }
}
</style>
