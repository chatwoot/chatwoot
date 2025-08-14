<!-- eslint-disable vue/no-mutating-props -->
<template>
  <modal :show.sync="show" :on-close="onClose">
    <woot-modal-header
      :header-title="`Unsubscribe - ${displayName}`"
      :header-content="`Are you sure you want to unsubscribe ${contact.phone_number}?`"
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
import alertMixin from 'shared/mixins/alertMixin';

import Modal from '../../../../components/Modal';
import { getContactDisplayName } from 'shared/helpers/contactHelper';
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
    displayName() {
      return getContactDisplayName(this.contact);
    },
  },

  mixins: [alertMixin],

  created() {},

  methods: {
    onClose() {
      this.$emit('cancel');
    },
    showAlert(message) {
      this.$emit('newToastMessage', message);
    },
    async onConfirm() {
      const subscribeQuery = [];
      if (this.contact.phone_number || this.contact.email) {
        if (this.contact.phone_number) {
          subscribeQuery.push({
            channel: 'WHATSAPP',
            accountId: this.currentAccountId,
            channelId: this.contact.phone_number,
            sourceType: 'CHATWOOT',
            subscribe: false,
          });
          subscribeQuery.push({
            channel: 'SMS',
            accountId: this.currentAccountId,
            channelId: this.contact.phone_number,
            sourceType: 'CHATWOOT',
            subscribe: false,
          });
        }
        if (this.contact.email) {
          subscribeQuery.push({
            channel: 'EMAIL',
            accountId: this.currentAccountId,
            channelId: this.contact.email,
            sourceType: 'CHATWOOT',
            subscribe: false,
          });
        }
        const body = {
          subscribeQuery,
        };
        this.onClose();
        this.showAlert('Unsubscribing contact');
        try {
          await axios.put(
            'https://bjzaowfrg4.execute-api.us-east-1.amazonaws.com/contact/update/subscribe',
            body
          );
          this.showAlert('Successfully unsubscribed contact');
        } catch (err) {
          if (err.response && err.response.status === 409) {
            this.showAlert('Contact already unsubscribed');
          } else {
            this.showAlert('Error unsubscribing contact');
          }
        }
      } else {
        this.onClose();
      }
    },
  },
};
</script>
