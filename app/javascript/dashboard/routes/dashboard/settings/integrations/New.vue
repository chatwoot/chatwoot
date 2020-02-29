<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header
        :header-title="$t('INTEGRATION_SETTINGS.WEBHOOK.ADD.TITLE')"
        :header-content="$t('INTEGRATION_SETTINGS.WEBHOOK.ADD.DESC')"
      />
      <form class="row" @submit.prevent="addWebhook()">
        <div class="medium-12 columns">
          <label :class="{ error: $v.endPoint.$error }">
            {{ $t('INTEGRATION_SETTINGS.WEBHOOK.ADD.FORM.END_POINT.LABEL') }}
            <input
              v-model.trim="endPoint"
              type="text"
              name="endPoint"
              :placeholder="
                $t(
                  'INTEGRATION_SETTINGS.WEBHOOK.ADD.FORM.END_POINT.PLACEHOLDER'
                )
              "
              @input="$v.endPoint.$touch"
            />
          </label>
        </div>

        <div class="modal-footer">
          <div class="medium-12 columns">
            <woot-submit-button
              :disabled="$v.endPoint.$invalid || addWebHook.showLoading"
              :button-text="$t('INTEGRATION_SETTINGS.WEBHOOK.ADD.FORM.SUBMIT')"
              :loading="addWebHook.showLoading"
            />
            <a @click="onClose">Cancel</a>
          </div>
        </div>
      </form>
    </div>
  </modal>
</template>

<script>
/* global bus */
/* eslint no-console: 0 */
import { required, minLength } from 'vuelidate/lib/validators';

import WootSubmitButton from '../../../../components/buttons/FormSubmitButton';
import Modal from '../../../../components/Modal';

const cannedImg = require('assets/images/canned.svg');

export default {
  components: {
    WootSubmitButton,
    Modal,
  },
  props: ['onClose'],
  data() {
    return {
      endPoint: '',
      agentType: '',
      vertical: 'bottom',
      horizontal: 'center',
      addWebHook: {
        showAlert: false,
        showLoading: false,
        message: '',
      },
      agentTypeList: this.$t('INTEGRATION_SETTINGS.WEBHOOK.AGENT_TYPES'),
      show: true,
    };
  },
  computed: {
    headerImage() {
      return cannedImg;
    },
  },
  validations: {
    endPoint: {
      required,
      minLength: minLength(2),
    },
    agentType: {
      required,
    },
  },

  methods: {
    setPageName({ name }) {
      this.$v.agentType.$touch();
      this.agentType = name;
    },
    showAlert() {
      bus.$emit('newToastMessage', this.addWebHook.message);
    },
    resetForm() {
      this.endPoint = '';
      this.$v.endPoint.$reset();
    },
    addWebhook() {
      // Show loading on button
      this.addWebHook.showLoading = true;
      // Make API Calls
      this.$store
        .dispatch('createWebHook', {
          webhook: { url: this.endPoint },
        })
        .then(() => {
          // Reset Form, Show success message
          this.addWebHook.showLoading = false;
          this.addWebHook.message = this.$t(
            'INTEGRATION_SETTINGS.WEBHOOK.ADD.API.SUCCESS_MESSAGE'
          );
          this.showAlert();
          this.resetForm();
          this.onClose();
        })
        .catch(() => {
          this.addWebHook.showLoading = false;
          this.addWebHook.message = this.$t(
            'INTEGRATION_SETTINGS.WEBHOOK.ADD.API.ERROR_MESSAGE'
          );
          this.showAlert();
        });
    },
  },
};
</script>
