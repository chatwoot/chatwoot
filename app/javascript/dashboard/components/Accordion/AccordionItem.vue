<template>
  <div class="cw-accordion">
    <button class="cw-accordion--title" @click="$emit('click')">
      <div class="cw-accordion--title-wrap">
        <emoji-or-icon class="icon-or-emoji" :icon="icon" :emoji="emoji" />
        <h5>
          {{ title }}
        </h5>
      </div>
      <div class="button-icon--wrap">
        <slot name="button" />
        <div class="chevron-icon__wrap" @click="$emit('click')">
          <i v-if="isOpen" class="ion-minus chevron-icon"></i>
          <i v-else class="ion-plus chevron-icon"></i>
        </div>
      </div>
    </button>
    <div v-if="isOpen" class="cw-accordion--content">
      <slot />
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
    title: {
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
    isOpen: {
      type: Boolean,
      default: true,
    },
  },
};
</script>

<style lang="scss" scoped>
.cw-accordion {
  // This is done to fix contact sidebar border issues
  // If you are using it else, find a fix to remove this hack
  margin-top: -1px;
  font-size: var(--font-size-small);
}
.cw-accordion--title {
  align-items: center;
  background: var(--b-50);
  border-bottom: 1px solid var(--color-border);
  border-top: 1px solid var(--color-border);
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  margin: 0;
  padding: var(--space-small) var(--space-normal);
  user-select: none;
  width: 100%;

  h5 {
    font-size: var(--font-size-normal);
    margin-bottom: 0;
    padding: 0 var(--space-small) 0 0;
  }
}

.cw-accordion--title-wrap {
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

.button-icon--wrap {
  display: flex;
  flex-direction: row;
}

.chevron-icon__wrap {
  display: flex;
  justify-content: flex-end;
  width: var(--space-slab);
  color: var(--w-500);
}

.cw-accordion--content {
  padding: var(--space-normal);
}
</style>
