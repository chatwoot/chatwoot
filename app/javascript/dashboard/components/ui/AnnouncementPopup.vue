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
  emits: ['open', 'close'],
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

<template>
  <div class="announcement-popup">
    <span v-if="popupMessage" class="popup-content">
      {{ popupMessage }}
      <span v-if="routeText" class="route-url" @click="onClickOpenPath">
        {{ routeText }}
      </span>
    </span>
    <div v-if="hasCloseButton" class="popup-close">
      <woot-button
        v-if="hasCloseButton"
        color-scheme="primary"
        variant="link"
        size="small"
        @click="onClickClose"
      >
        {{ closeButtonText }}
      </woot-button>
    </div>
  </div>
</template>

<style lang="scss">
.announcement-popup {
  max-width: 15rem;
  min-width: 10rem;
  display: flex;
  position: absolute;
  flex-direction: column;
  align-items: flex-start;
  height: fit-content;
  background: var(--white);
  padding: 0 var(--space-normal);
  z-index: var(--z-index-much-higher);
  box-shadow: var(--b-200) 4px 4px 16px 4px;
  border-radius: var(--border-radius-normal);

  .popup-content {
    font-size: var(--font-size-mini);
    color: var(--s-700);
    padding: var(--space-one) 0;
    .route-url {
      font-size: var(--font-size-mini);
      color: var(--s-600);
      cursor: pointer;
      text-decoration: underline;
    }
  }

  .popup-close {
    width: 100%;
    display: flex;
    align-items: center;
    padding: var(--space-one) 0;
    border-top: 1px solid var(--color-border-light);
  }
}
</style>
