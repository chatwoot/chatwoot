<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header :header-title="pageTitle" />
      <form class="row medium-8" @submit.prevent="editAgent()">
        <div class="medium-12 columns">
          <label :class="{ error: $v.agentName.$error }">
            {{ $t('AGENT_MGMT.EDIT.FORM.NAME.LABEL') }}
            <input
              v-model.trim="agentName"
              type="text"
              :placeholder="$t('AGENT_MGMT.EDIT.FORM.NAME.PLACEHOLDER')"
              @input="$v.agentName.$touch"
            />
          </label>
        </div>

        <div class="medium-12 columns">
          <label :class="{ error: $v.agentType.$error }">
            {{ $t('AGENT_MGMT.EDIT.FORM.AGENT_TYPE.LABEL') }}
            <multiselect
              v-model.trim="agentType"
              :options="agentTypeList"
              label="label"
              :placeholder="$t('AGENT_MGMT.EDIT.FORM.AGENT_TYPE.PLACEHOLDER')"
              :searchable="false"
              @select="setPageName"
            />
            <span v-if="$v.agentType.$error" class="message">
              {{ $t('AGENT_MGMT.EDIT.FORM.AGENT_TYPE.ERROR') }}
            </span>
          </label>
        </div>
        <div class="medium-12 modal-footer">
          <div class="medium-6 columns">
            <woot-submit-button
              :disabled="
                $v.agentType.$invalid ||
                  $v.agentName.$invalid ||
                  editAgentsApi.showLoading
              "
              :button-text="$t('AGENT_MGMT.EDIT.FORM.SUBMIT')"
              :loading="editAgentsApi.showLoading"
            />
            <a @click="onClose">
              {{ $t('AGENT_MGMT.EDIT.CANCEL_BUTTON_TEXT') }}
            </a>
          </div>
          <div class="medium-6 columns text-right">
            <a @click="resetPassword">
              <i class="ion-locked"></i>
              {{ $t('AGENT_MGMT.EDIT.PASSWORD_RESET.ADMIN_RESET_BUTTON') }}
            </a>
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
import Auth from '../../../../api/auth';

export default {
  components: {
    WootSubmitButton,
    Modal,
  },
  props: {
    id: Number,
    name: String,
    email: String,
    type: String,
    onClose: Function,
  },
  data() {
    return {
      editAgentsApi: {
        showAlert: false,
        showLoading: false,
        message: '',
      },
      agentTypeList: this.$t('AGENT_MGMT.AGENT_TYPES'),
      agentName: this.name,
      agentType: {
        name: this.type,
        label: this.type,
      },
      agentCredentials: {
        email: this.email,
      },
      show: true,
    };
  },
  validations: {
    agentName: {
      required,
      minLength: minLength(4),
    },
    agentType: {
      required,
    },
  },
  computed: {
    pageTitle() {
      return `${this.$t('AGENT_MGMT.EDIT.TITLE')} - ${this.name}`;
    },
  },
  methods: {
    setPageName({ name }) {
      this.$v.agentType.$touch();
      this.agentType = name;
    },
    showAlert() {
      bus.$emit('newToastMessage', this.editAgentsApi.message);
    },
    resetForm() {
      this.agentName = '';
      this.agentType = '';
      this.$v.agentName.$reset();
      this.$v.agentType.$reset();
    },
    editAgent() {
      // Show loading on button
      this.editAgentsApi.showLoading = true;
      // Make API Calls
      this.$store
        .dispatch('editAgent', {
          id: this.id,
          name: this.agentName,
          role: this.agentType.name.toLowerCase(),
        })
        .then(() => {
          // Reset Form, Show success message
          this.editAgentsApi.showLoading = false;
          this.editAgentsApi.message = this.$t(
            'AGENT_MGMT.EDIT.API.SUCCESS_MESSAGE'
          );
          this.showAlert();
          this.resetForm();
          setTimeout(() => {
            this.onClose();
          }, 10);
        })
        .catch(() => {
          this.editAgentsApi.showLoading = false;
          this.editAgentsApi.message = this.$t(
            'AGENT_MGMT.EDIT.API.ERROR_MESSAGE'
          );
          this.showAlert();
        });
    },
    resetPassword() {
      // Call resetPassword from Auth Service
      Auth.resetPassword(this.agentCredentials)
        .then(() => {
          this.editAgentsApi.message = this.$t(
            'AGENT_MGMT.EDIT.PASSWORD_RESET.ADMIN_SUCCESS_MESSAGE'
          );
          this.showAlert();
        })
        .catch(() => {
          this.editAgentsApi.message = this.$t(
            'AGENT_MGMT.EDIT.PASSWORD_RESET.ERROR_MESSAGE'
          );
          this.showAlert();
        });
    },
  },
};
</script>
