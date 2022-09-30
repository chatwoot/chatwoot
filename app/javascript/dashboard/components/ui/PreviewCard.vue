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
  border-radius: var(--border-radius-normal);
  border: 1px solid var(--color-border);
  display: flex;
  flex-direction: column;
  max-height: 34rem;
  max-width: 38rem;
  min-width: 24rem;

  .header--wrap {
    background: var(--s-50);
    border-bottom: 1px solid var(--color-border);
    border-top-left-radius: var(--border-radius-normal);
    border-top-right-radius: var(--border-radius-normal);
    display: flex;
    height: 4rem;
    justify-content: space-between;
    padding: var(--space-small);
    width: 100%;
  }

  .active {
    background: var(--w-50);
    border-bottom: 1px solid var(--w-75);
  }

  .heading-wrap {
    align-items: center;
    display: flex;
    font-weight: var(--font-weight-medium);
    padding: var(--space-smaller);
  }

  .checkmark {
    color: var(--w-500);
  }

  .content-wrap {
    color: var(--s-700);
    font-size: var(--font-size-mini);
    line-height: 1.4;
    padding: var(--space-slab) var(--space-slab) 0 var(--space-slab);
    text-align: start;
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
  background: var(--w-25);
  border: 1px solid var(--w-300);
}
</style>
