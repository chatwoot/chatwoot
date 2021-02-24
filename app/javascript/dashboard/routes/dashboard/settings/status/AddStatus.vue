<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header
        :header-title="$t('STATUS_MGMT.ADD.TITLE')"
        :header-content="$t('STATUS_MGMT.ADD.DESC')"
      />
      <form class="row" @submit.prevent="saveStatus()">
        <div class="medium-12 columns">
          <label :class="{ error: $v.status.$error }">
            {{ $t('STATUS_MGMT.ADD.FORM.STATUS.LABEL') }}
            <input
              v-model.trim="status"
              type="text"
              :placeholder="$t('STATUS_MGMT.ADD.FORM.STATUS.PLACEHOLDER')"
              @input="$v.status.$touch"
            />
          </label>
        </div>
        <div class="modal-footer">
          <div class="medium-12 columns">
            <woot-submit-button
              :disabled="$v.status.$invalid || addStatus.showLoading"
              :button-text="$t('STATUS_MGMT.ADD.FORM.SUBMIT')"
              :loading="addStatus.showLoading"
            />
            <button class="button clear" @click.prevent="onClose">
              {{ $t('STATUS_MGMT.ADD.CANCEL_BUTTON_TEXT') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </modal>
</template>

<script>
import { required, minLength } from 'vuelidate/lib/validators';

import WootSubmitButton from '../../../../components/buttons/FormSubmitButton';
import Modal from '../../../../components/Modal';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    WootSubmitButton,
    Modal,
  },
  mixins: [alertMixin],
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      status: '',
      vertical: 'bottom',
      horizontal: 'center',
      addStatus: {
        showLoading: false,
        message: '',
      },
      show: true,
    };
  },
  validations: {
    status: {
      required,
      minLength: minLength(2),
    },
  },
  methods: {
    resetForm() {
      this.status = '';
      this.$v.status.$reset();
    },
    saveStatus() {
      // Show loading on button
      this.addStatus.showLoading = true;
      // Make API Calls
      this.$store
        .dispatch('createStatus', {
          name: this.status,
        })
        .then(() => {
          // Reset Form, Show success message
          this.addStatus.showLoading = false;
          this.showAlert(this.$t('STATUS_MGMT.ADD.API.SUCCESS_MESSAGE'));
          this.resetForm();
          this.onClose();
        })
        .catch(() => {
          this.addStatus.showLoading = false;
          this.showAlert(this.$t('STATUS_MGMT.ADD.API.ERROR_MESSAGE'));
        });
    },
  },
};
</script>
