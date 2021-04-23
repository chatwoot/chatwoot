<template>
  <div class="conv-details--item">
    <h4 class="conv-details--item__label text-block-title">
      <div class="title--icon">
        <emoji-or-icon :icon="icon" :emoji="emoji" />
        {{ title }}
      </div>
    </h4>
    <div v-if="value" class="conv-details--item__value">
      <slot>
        {{ value }}
      </slot>
    </div>
  </div>
</template>

<script>
import EmojiOrIcon from 'shared/components/EmojiOrIcon';

export default {
  components: {
    EmojiOrIcon,
  },

  props: {
    title: { type: String, required: true },
    icon: { type: String, default: '' },
    emoji: { type: String, default: '' },
    value: { type: [String, Number], default: '' },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';

.conv-details--item {
  padding-bottom: var(--space-small);

  .conv-details--item__label {
    align-items: center;
    display: flex;
    justify-content: space-between;
    margin-bottom: var(--space-smaller);
  }

  .conv-details--item__value {
    word-break: break-all;
    margin-left: var(--space-medium);
  }

  .title--icon .icon--emoji,
  .title--icon .icon--font {
    margin-right: var(--space-small);
  }

  .title--icon {
    display: flex;
    align-items: center;
  }
}
</style>
