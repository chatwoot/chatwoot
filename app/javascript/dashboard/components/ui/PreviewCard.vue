<template>
  <div class="preview-card--wrap" :class="{ activecard: active }">
    <div class="header--wrap" :class="{ active: active }">
      <div class="heading-wrap text-block-title">{{ heading }}</div>
      <fluent-icon
        v-if="active"
        icon="checkmark-circle"
        type="solid"
        size="24"
        class="checkmark"
      />
    </div>
    <div class="content-wrap">
      {{ content }}
    </div>
    <div class="image-wrap">
      <img :src="src" class="image" :class="{ activeimage: active }" />
    </div>
  </div>
</template>

<script>
export default {
  props: {
    heading: {
      type: String,
      default: '',
    },
    content: {
      type: String,
      default: '',
    },
    active: {
      type: Boolean,
      default: false,
    },
    buttonText: {
      type: String,
      default: 'Active',
    },
    src: {
      type: String,
      default: '',
    },
  },
};
</script>

<style lang="scss" scoped>
.preview-card--wrap {
  display: flex;
  flex-direction: column;
  min-width: 24rem;
  max-width: 38rem;
  max-height: 34rem;
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-normal);

  .header--wrap {
    display: flex;
    justify-content: space-between;
    height: 4rem;
    border-top-left-radius: var(--border-radius-normal);
    border-top-right-radius: var(--border-radius-normal);
    background: var(--s-50);
    border-bottom: 1px solid var(--color-border);
    padding: var(--space-small);
    width: 100%;
  }
  .active {
    background: var(--w-50);
    border-bottom: 1px solid var(--w-75);
  }
  .heading-wrap {
    display: flex;
    align-items: center;
    font-weight: var(--font-weight-medium);
    padding: var(--space-smaller);
  }
  .checkmark {
    color: var(--w-500);
  }
  .content-wrap {
    text-align: start;
    padding: var(--space-slab) var(--space-slab) 0 var(--space-slab);
    font-size: var(--font-size-mini);
    line-height: 1.4;
    color: var(--s-700);
  }
  .image-wrap {
    padding: var(--space-slab);
  }
  .image {
    border: 1px solid var(--color-border);
    border-radius: var(--border-radius-normal);
  }
  .activeimage {
    border: 1px solid var(--w-75);
  }
}
.activecard {
  border: 1px solid var(--w-300);
  background: var(--w-25);
}
</style>
