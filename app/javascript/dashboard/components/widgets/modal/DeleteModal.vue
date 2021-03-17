<template>
  <modal :show.sync="show" :on-close="onClose">
    <woot-modal-header :header-title="title" :header-content="message" />
    <div class="modal-footer delete-item">
      <woot-button color-scheme="alert" @click="onConfirm">
        {{ confirmText }}
      </woot-button>
      <woot-button variant="clear" @click="onClose">
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
    show: {
      type: Boolean,
      default: false,
    },
    onClose: {
      type: Function,
      default: () => {},
    },
    onConfirm: {
      type: Function,
      default: () => {},
    },
    title: {
      type: String,
      default: '',
    },
    message: {
      type: String,
      default: '',
    },
    confirmText: {
      type: String,
      default: '',
    },
    rejectText: {
      type: String,
      default: '',
    },
  },
};
</script>
