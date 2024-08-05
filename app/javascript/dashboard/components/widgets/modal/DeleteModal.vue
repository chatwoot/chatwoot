<script>
import Modal from '../../Modal.vue';

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
    messageValue: { type: String, default: '' },
    confirmText: { type: String, default: '' },
    rejectText: { type: String, default: '' },
  },
};
</script>

<!-- eslint-disable vue/no-mutating-props -->
<template>
  <Modal :show.sync="show" :on-close="onClose">
    <woot-modal-header
      :header-title="title"
      :header-content="message"
      :header-content-value="messageValue"
    />
    <div class="flex items-center justify-end gap-2 p-8">
      <woot-button variant="clear" class="action-button" @click="onClose">
        {{ rejectText }}
      </woot-button>
      <woot-button
        color-scheme="alert"
        class="action-button"
        variant="smooth"
        @click="onConfirm"
      >
        {{ confirmText }}
      </woot-button>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
.action-button {
  max-width: var(--space-giga);
}
</style>
