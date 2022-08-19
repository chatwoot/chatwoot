<template>
  <modal :show.sync="show" :on-close="onClose">
    <woot-modal-header :header-title="title" :header-content="message" />
    <div class="modal-footer delete-item">
      <woot-button
        color-scheme="alert"
        class="action-button"
        @click="onConfirm"
      >
        {{ confirmText }}
      </woot-button>
      <woot-button variant="clear" class="action-button" @click="onClose">
        {{ rejectText }}
      </woot-button>
    </div>
  </modal>
</template>

<script>
import Modal from '../../Modal';

export default {
  components: {
    Modal,
  },
  props: {
    show: Boolean,
    onClose: { type: Function, default: () => {} },
    onConfirm: { type: Function, default: () => {} },
    title: { type: String, default: '' },
    message: { type: String, default: '' },
    confirmText: { type: String, default: '' },
    rejectText: { type: String, default: '' },
  },
};
</script>
<style lang="scss" scoped>
.action-button {
  max-width: var(--space-giga);
}
</style>
