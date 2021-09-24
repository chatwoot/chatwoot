<template>
  <woot-dropdown-item>
    <div class="item-wrap">
      <woot-button variant="clear" @click="onClick">
        <div class="button-wrap">
          <div class="name-label-wrap">
            <emoji-or-icon
              v-if="icon || emoji"
              class="icon"
              :emoji="emoji"
              :icon="icon"
            />
            <span class="label-text" :title="title">{{ title }}</span>
          </div>
        </div>
      </woot-button>
    </div>
  </woot-dropdown-item>
</template>

<script>
import EmojiOrIcon from 'shared/components/EmojiOrIcon';
export default {
  name: 'AttributeDropDownItem',
  components: { EmojiOrIcon },
  props: {
    title: {
      type: String,
      default: '',
    },
    icon: {
      type: String,
      default: '',
    },
    emoji: {
      type: String,
      default: '',
    },
  },

  methods: {
    onClick() {
      this.$emit('click', this.title);
    },
  },
};
</script>

<style lang="scss" scoped>
.item-wrap {
  display: flex;

  ::v-deep .button__content {
    width: 100%;
  }

  .button-wrap {
    display: flex;
    justify-content: space-between;
    width: 100%;

    &.active {
      display: flex;
      font-weight: var(--font-weight-bold);
      color: var(--w-700);
    }

    .name-label-wrap {
      display: flex;
      min-width: 0;
      width: 100%;

      .label-color--display {
        margin-right: var(--space-small);
      }

      .label-text {
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        line-height: 1.1;
        padding-right: var(--space-small);
        padding-left: var(--space-small);
      }

      .icon {
        font-size: var(--font-size-small);
      }
    }
  }

  .label-color--display {
    border-radius: var(--border-radius-normal);
    height: var(--space-slab);
    margin-right: var(--space-smaller);
    margin-top: var(--space-micro);
    min-width: var(--space-slab);
    width: var(--space-slab);
  }
}
</style>
