<template>
  <div class="sidebar-item--collapsible">
    <div class="contact_info" @click="$emit('click')">
      <div class="title-wrap">
        <div class="title-icon__wrap">
          <emoji-or-icon class="icon-or-emoji" :icon="icon" :emoji="emoji" />
          <h5 class="item-name sub-block-title">
            {{ headerTitle }}
          </h5>
        </div>
      </div>
      <div class="button-icon--wrap">
        <slot name="button"></slot>
        <div class="chevron-icon__wrap" @click="$emit('click')">
          <i v-if="enabled" class="ion-minus chevron-icon"></i>
          <i v-else class="ion-plus chevron-icon"></i>
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
.sidebar-item--collapsible {
  border-bottom: 1px solid var(--color-border-light);
  padding: 0 var(--space-normal);
}
.contact_info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  cursor: pointer;
  user-select: none;
  padding: var(--space-micro) 0;
  margin: var(--space-slab) 0;
}

.title-wrap {
  display: flex;
  justify-content: space-between;
  margin-bottom: var(--space-micro);
}

.title-icon__wrap {
  display: flex;
  align-items: baseline;
}

.icon-or-emoji {
  display: inline-block;
  width: var(--space-two);
}

.item-name {
  margin-bottom: 0;
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
