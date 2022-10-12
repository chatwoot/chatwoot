<template>
  <modal :show.sync="show" :on-close="onClose">
    <woot-modal-header
      :header-title="`Unsubscribe - ${contact.name}`"
      :header-content="
        `Are you sure you want to unsubscribe ${contact.phone_number}?`
      "
    />
    <div class="modal-footer delete-item">
      <woot-button variant="clear" class="action-button" @click="onClose">
        No, Keep
      </woot-button>
      <woot-button
        color-scheme="alert"
        class="action-button"
        variant="smooth"
        @click="onConfirm"
      >
        Unsubscribe
      </woot-button>
      <!-- <h1>HEy</h1> -->
    </div>
  </modal>
</template>
̦
<script>
import { mapGetters } from 'vuex';
import axios from 'axios';

import Modal from '../../../../components/Modal';
export default {
  components: {
    Modal,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    contact: {
      type: Object,
      default: () => ({}),
    },
  },

  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
      currentAccountId: 'getCurrentAccountId',
    }),
  },

  methods: {
    onClose() {
      this.$emit('cancel');
    },
    onConfirm() {
      if (this.contact.phone_number) {
        const body = {
          accountId: this.currentAccountId,
          phoneNumber: this.contact.phone_number,
        };
        axios.post(
          'https://app.bitespeed.co/cxIntegrations/chatwoot/unsubscribe',
          body
        );
        this.onClose();
      } else {
        this.onClose();
      }
    },
  },
};
</script>
