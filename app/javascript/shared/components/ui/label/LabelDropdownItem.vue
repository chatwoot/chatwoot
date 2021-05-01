<template>
  <woot-dropdown-item>
    <div class="item-wrap">
      <button class="button clear" @click="onclick">
        <div class="name-label-wrap">
          <div
            v-if="color"
            class="label-color--display"
            :style="{ backgroundColor: color }"
          />
          <span>{{ title }}</span>
        </div>
        <i v-if="selected" class="icon ion-checkmark-round" />
      </button>
    </div>
  </woot-dropdown-item>
</template>

<script>
export default {
  props: {
    title: {
      type: String,
      default: '',
    },
    color: {
      type: String,
      default: '',
    },
    selected: {
      type: Boolean,
      default: false,
    },
  },

  methods: {
    onclick() {
      this.$emit('click', this.title);
    },
  },
};
</script>

<style lang="scss" scoped>
.item-wrap {
  display: flex;

  .button {
    display: flex;
    justify-content: space-between;

    &.active {
      display: flex;
      font-weight: var(--font-weight-bold);
      color: #1a4d8f;
    }

    .name-label-wrap {
      display: flex;
    }

    .label-color--display {
      margin-right: var(--space-small);
    }

    .icon {
      font-size: var(--font-size-small);
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
