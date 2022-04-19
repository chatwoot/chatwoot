<template>
  <div class="announcement-popup">
    <span v-if="popupMessage" class="popup-content">
      {{ popupMessage }}
      <span class="route-url" @click="onClickOpenPath">
        {{ routeText }}
      </span>
    </span>
    <woot-button
      v-if="hasCloseButton"
      class="popup-close"
      color-scheme="primary"
      variant="link"
      size="small"
      @click="onClickClose"
    >
      {{ closeButtonText }}
    </woot-button>
  </div>
</template>
<script>
export default {
  props: {
    popupMessage: {
      type: String,
      default: '',
    },
    routeText: {
      type: String,
      default: '',
    },
    hasCloseButton: {
      type: Boolean,
      default: true,
    },
    closeButtonText: {
      type: String,
      default: '',
    },
  },
  methods: {
    onClickOpenPath() {
      this.$emit('open');
    },
    onClickClose(e) {
      this.$emit('close', e);
    },
  },
};
</script>

<style lang="scss">
.announcement-popup {
  width: 24rem;
  display: flex;
  position: absolute;
  flex-direction: column;
  align-items: flex-start;
  height: fit-content;
  background: var(--white);
  padding: var(--space-slab);
  z-index: var(--z-index-much-higher);
  box-shadow: var(--b-200) var(--space-smaller) var(--space-smaller)
    var(--space-normal) var(--space-smaller);
  border-radius: var(--border-radius-normal);

  &::before {
    content: '';
    position: absolute;
    bottom: var(--space-minus-small);
    border-left: var(--space-small) solid transparent;
    border-right: var(--space-small) solid transparent;
    border-top: var(--space-small) solid var(--white);
  }

  .popup-content {
    font-size: var(--font-size-mini);
    color: var(--s-700);
    padding: 0 var(--space-small) var(--space-small) var(--space-small);
    border-bottom: 1px solid var(--color-border-light);

    .route-url {
      font-size: var(--font-size-mini);
      color: var(--s-600);
      cursor: pointer;
      text-decoration: underline;
    }
  }

  .popup-close {
    padding: var(--space-small) var(--space-small) 0 var(--space-small);
  }
}
</style>
