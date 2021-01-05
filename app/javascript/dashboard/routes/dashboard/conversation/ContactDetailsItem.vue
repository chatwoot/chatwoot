<template>
  <div class="conv-details--item">
    <h4 class="conv-details--item__label text-block-title">
      <div class="title--icon">
        <span v-if="showEmoji" class="conv-details--item__emoji">{{
          emoji
        }}</span>
        <i v-if="showIcon" :class="icon" class="conv-details--item__icon"></i>
        {{ title }}
      </div>
      <button
        v-if="showEdit"
        class="button clear small edit-button"
        @click="onEdit"
      >
        {{ $t('CONTACT_PANEL.EDIT_LABEL') }}
      </button>
    </h4>
    <div v-if="value" class="conv-details--item__value">
      <slot>
        {{ value }}
      </slot>
    </div>
  </div>
</template>

<script>
import { hasEmojiSupport } from 'shared/helpers/emoji';

export default {
  props: {
    title: { type: String, required: true },
    icon: { type: String, default: '' },
    emoji: { type: String, default: '' },
    value: { type: [String, Number], default: '' },
    showEdit: { type: Boolean, default: false },
  },
  computed: {
    showEmoji() {
      return this.emoji && hasEmojiSupport(this.emoji);
    },
    showIcon() {
      return !this.showEmoji && this.icon;
    },
  },
  methods: {
    onEdit() {
      this.$emit('edit');
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';

.conv-details--item {
  padding-bottom: var(--space-normal);

  .conv-details--item__label {
    align-items: center;
    display: flex;
    justify-content: space-between;
    margin-bottom: var(--space-smaller);

    .edit-button {
      padding: 0;
    }
  }

  .conv-details--item__value {
    word-break: break-all;
    margin-left: var(--space-medium);
  }

  .conv-details--item__emoji {
    font-size: var(--font-size-default);
    margin-right: var(--space-small);
  }

  .title--icon {
    display: flex;
    align-items: center;
  }
}
</style>
