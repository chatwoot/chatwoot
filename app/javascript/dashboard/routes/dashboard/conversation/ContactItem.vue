<template>
  <div>
    <div class="contact_info">
      <div class="title_wrap" @click="$emit('click')">
        <div class="title-icon__wrap">
          <emoji-or-icon class="icon-or-emoji" :icon="icon" :emoji="emoji" />
          <span class="item-name text-block-title">
            {{ headerTitle }}
          </span>
        </div>
      </div>
      <div class="button-icon--wrap">
        <slot name="button"></slot>
        <div class="chevron-icon__wrap" @click="$emit('click')">
          <i v-if="enabled" class="ion-chevron-down chevron-icon"></i>
          <i v-else class="ion-chevron-right chevron-icon"></i>
        </div>
      </div>
    </div>
    <slot></slot>
  </div>
</template>

<script>
import EmojiOrIcon from 'shared/components/EmojiOrIcon';

export default {
  components: {
    EmojiOrIcon,
  },
  props: {
    headerTitle: {
      type: String,
      required: true,
    },
    icon: {
      type: String,
      default: '',
    },
    emoji: {
      type: String,
      default: '',
    },
    enabled: {
      type: Boolean,
      default: true,
    },
  },
};
</script>

<style lang="scss" scoped>
.contact_info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  cursor: pointer;
  user-select: none;
  padding: var(--space-micro) 0;
  margin-bottom: var(--space-small);
}

.title_wrap {
  display: flex;
  justify-content: space-between;
}

.title-icon__wrap {
  display: flex;
  align-items: baseline;
}

.icon-or-emoji {
  display: inline-block;
  width: var(--space-medium);
}

.item-name {
  font-weight: var(--font-weight-bold);
  color: var(--color---color-heading);
  padding: 0 var(--space-small) 0 0;
}

.button-icon--wrap {
  display: flex;
  flex-direction: row;
}

.chevron-icon__wrap {
  display: flex;
  justify-content: flex-end;
  width: var(--space-slab);
}
</style>
