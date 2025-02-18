<script>
export default {
  props: {
    title: {
      type: String,
      default: '',
    },
    color: {
      type: String,
      default: '',
    },
    selected: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['selectLabel'],

  methods: {
    onClick() {
      this.$emit('selectLabel', this.title);
    },
  },
};
</script>

<template>
  <woot-dropdown-item>
    <div class="item-wrap">
      <woot-button variant="clear" @click="onClick">
        <div class="button-wrap">
          <div class="name-label-wrap">
            <div
              v-if="color"
              class="label-color--display"
              :style="{ backgroundColor: color }"
            />
            <span class="label-text" :title="title">{{ title }}</span>
          </div>
          <div>
            <i v-if="selected" class="i-lucide-circle-check" />
          </div>
        </div>
      </woot-button>
    </div>
  </woot-dropdown-item>
</template>

<style lang="scss" scoped>
.item-wrap {
  @apply flex;

  ::v-deep .button__content {
    @apply w-full;
  }

  .button-wrap {
    @apply flex justify-between w-full;

    &.active {
      @apply flex font-semibold text-woot-700 dark:text-woot-600;
    }

    .name-label-wrap {
      @apply flex min-w-0 w-full;

      .label-color--display {
        @apply mr-2 rtl:mr-0 rtl:ml-2;
      }

      .label-text {
        @apply overflow-hidden text-ellipsis whitespace-nowrap leading-[1.1] pr-2;
      }

      .icon {
        @apply text-sm;
      }
    }
  }

  .label-color--display {
    @apply rounded-md h-3 mr-1 rtl:mr-0 rtl:ml-1 mt-0.5 min-w-[0.75rem] w-3 border border-solid border-slate-50 dark:border-slate-600;
  }
}
</style>
