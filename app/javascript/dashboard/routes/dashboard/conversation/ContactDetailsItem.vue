<template>
  <div class="conv-details--item">
    <h4 class="conv-details--item__label text-block-title">
      <span class="title--icon">
        <emoji-or-icon :icon="icon" :emoji="emoji" />
        <span>{{ title }}</span>
      </span>
      <slot name="button"></slot>
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
.conv-details--item {
  overflow: auto;
  .conv-details--item__label {
    align-items: center;
    display: flex;
    justify-content: space-between;

    .edit-button {
      padding: 0;
    }
  }

  .conv-details--item__value {
    word-break: break-all;
    margin-left: var(--space-medium);
    margin-bottom: var(--space-normal);
  }

  .title--icon .icon--emoji,
  .title--icon .icon--font {
    display: inline-block;
    width: var(--space-medium);
  }

  .title--icon {
    display: flex;
    align-items: center;
  }
}
</style>
