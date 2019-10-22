<template>
  <modal
    :show.sync="show"
    :on-close="onClose"
  >
    <woot-modal-header
      :header-title="title"
      :header-content="message"
    />
    <div class="modal-footer delete-item">
      <button class="button" @click="onClose">
        {{ rejectText }}
      </button>
      <button class="alert button" @click="onConfirm">
        {{ confirmText }}
      </button>
    </div>
  </modal>
</template>

<script>
import PageHeader from '../SettingsSubPageHeader';
import Modal from '../../../../components/Modal';

export default {
  components: {
    Modal,
    PageHeader,
  },
  props: {
    show: Boolean,
    onClose: Function,
    onConfirm: Function,
    title: String,
    message: String,
    confirmText: String,
    rejectText: String,
  },
};
</script>
