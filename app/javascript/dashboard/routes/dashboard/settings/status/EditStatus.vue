<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header :header-title="pageTitle" />
      <form class="row medium-8" @submit.prevent="saveStatus()">
        <div class="medium-12 columns">
          <label :class="{ error: $v.status.$error }">
            {{ $t('STATUS_MGMT.EDIT.FORM.SHORT_CODE.LABEL') }}
            <input
              v-model.trim="status"
              type="text"
              :placeholder="$t('STATUS_MGMT.EDIT.FORM.STATUS.PLACEHOLDER')"
              @input="$v.status.$touch"
            />
          </label>
        </div>
        <div class="modal-footer">
          <div class="medium-12 columns">
            <woot-submit-button
              :disabled="$v.status.$invalid || editStatus.showLoading"
              :button-text="$t('STATUS_MGMT.EDIT.FORM.SUBMIT')"
              :loading="editStatus.showLoading"
            />
            <button class="button clear" @click.prevent="onClose">
              {{ $t('STATUS_MGMT.EDIT.CANCEL_BUTTON_TEXT') }}
            </button>
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

export default {
  components: {
    WootSubmitButton,
    Modal,
  },
  props: {
    id: Number,
    edstatus: String,
    onClose: Function,
  },
  data() {
    return {
      editStatus: {
        showAlert: false,
        showLoading: false,
        message: '',
      },
      status: this.edstatus,
      show: true,
    };
  },
  validations: {
    status: {
      required,
      minLength: minLength(2),
    },
  },
  computed: {
    pageTitle() {
      return `${this.$t('STATUS_MGMT.EDIT.TITLE')} - ${this.edstatus}`;
    },
  },
  methods: {
    setPageName({ name }) {
      this.$v.content.$touch();
      this.content = name;
    },
    showAlert() {
      bus.$emit('newToastMessage', this.editStatus.message);
    },
    resetForm() {
      this.status = '';
      this.$v.status.$reset();
    },
    saveStatus() {
      // Show loading on button
      this.editStatus.showLoading = true;
      // Make API Calls
      this.$store
        .dispatch('updateStatus', {
          id: this.id,
          status: this.status,
        })
        .then(() => {
          // Reset Form, Show success message
          this.editStatus.showLoading = false;
          this.editStatus.message = this.$t(
            'STATUS_MGMT.EDIT.API.SUCCESS_MESSAGE'
          );
          this.showAlert();
          this.resetForm();
          setTimeout(() => {
            this.onClose();
          }, 10);
        })
        .catch(() => {
          this.editStatus.showLoading = false;
          this.editStatus.message = this.$t(
            'STATUS_MGMT.EDIT.API.ERROR_MESSAGE'
          );
          this.showAlert();
        });
    },
  },
};
</script>
