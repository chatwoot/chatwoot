<template>
  <div class="contact-attribute">
    <div class="title-wrap">
      <h4 class="text-block-title title">
        <div class="title--icon">
          <emoji-or-icon :icon="icon" :emoji="emoji" />
        </div>
        {{ label }}
      </h4>
    </div>
    <div class="value-wrap">
      <p v-if="value" class="value">
        {{ value }}
      </p>
      <woot-button
        v-if="showEdit"
        variant="clear link"
        size="tiny"
        color-scheme="secondary"
        icon="ion-compose"
        class-names="edit-button"
        @click="onEdit"
      />
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
    label: { type: String, required: true },
    icon: { type: String, default: '' },
    emoji: { type: String, default: '' },
    value: { type: [String, Number], default: '' },
    showEdit: { type: Boolean, default: false },
  },
  methods: {
    onEdit() {
      this.$emit('edit');
    },
  },
};
</script>

<style lang="scss" scoped>
.contact-attribute {
  margin-bottom: var(--space-normal);
}
.title-wrap {
  display: flex;
  align-items: center;
}
.title {
  display: flex;
  align-items: center;
  margin: 0;
}
.title--icon {
  width: var(--space-two);
}
.edit-button {
  display: none;
}
.value-wrap {
  display: flex;

  &:hover {
    .value {
      background: var(--color-background);
    }
    .edit-button {
      display: block;
    }
  }
}
.value {
  display: inline-block;
  border-radius: var(--border-radius-small);
  word-break: break-all;
  margin: 0 var(--space-smaller) 0 var(--space-normal);
  padding: var(--space-micro) var(--space-smaller);
}
</style>
