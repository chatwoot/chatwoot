<template>
  <modal :show.sync="show" :on-close="onClose">
    <woot-modal-header :header-title="title" :header-content="message" />
    <div class="modal-footer delete-item">
      <button class="alert button nice text-truncate" @click="onConfirm">
        {{ confirmText }}
      </button>
      <button class="button clear text-truncate" @click="onClose">
        {{ rejectText }}
      </button>
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
