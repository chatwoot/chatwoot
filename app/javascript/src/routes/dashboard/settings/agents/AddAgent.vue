<template>
  <woot-modal :show.sync="show" :on-close="onClose">

    <div class="column content-box">
      <woot-modal-header
        :header-image="headerImage"
        :header-title="$t('AGENT_MGMT.ADD.TITLE')"
        :header-content="$t('AGENT_MGMT.ADD.DESC')"
      />

      <form class="row" v-on:submit.prevent="addAgent()">
        <div class="medium-12 columns">
          <label :class="{ 'error': $v.agentName.$error }">
            {{ $t('AGENT_MGMT.ADD.FORM.NAME.LABEL') }}
            <input type="text" v-model.trim="agentName" @input="$v.agentName.$touch" :placeholder="$t('AGENT_MGMT.ADD.FORM.NAME.PLACEHOLDER')">
          </label>
        </div>
        <div class="medium-12 columns">
          <label :class="{ 'error': $v.agentType.$error }">
            {{ $t('AGENT_MGMT.ADD.FORM.AGENT_TYPE.LABEL') }}
            <multiselect
              v-model="agentType"
              :options="agentTypeList"
              :searchable="false"
              label="label"
              :placeholder="$t('AGENT_MGMT.ADD.FORM.AGENT_TYPE.PLACEHOLDER')"
              @select="setPageName"
              :allow-empty="true"
              :close-on-select="true"
            />
            <span class="message" v-if="$v.agentType.$error">
              {{ $t('AGENT_MGMT.ADD.FORM.AGENT_TYPE.ERROR') }}
            </span>
          </label>
        </div>
        <div class="medium-12 columns">
          <label :class="{ 'error': $v.agentEmail.$error }">
            {{ $t('AGENT_MGMT.ADD.FORM.EMAIL.LABEL') }}
            <input type="text" v-model.trim="agentEmail" @input="$v.agentEmail.$touch" :placeholder="$t('AGENT_MGMT.ADD.FORM.EMAIL.PLACEHOLDER')">
          </label>
        </div>
        <div class="modal-footer">
          <div class="medium-12 columns">
            <woot-submit-button
              :disabled="$v.agentEmail.$invalid || $v.agentName.$invalid || addAgentsApi.showLoading"
              :button-text="$t('AGENT_MGMT.ADD.FORM.SUBMIT')"
              :loading="addAgentsApi.showLoading"
            />
            <a @click="onClose">Cancel</a>
          </div>
        </div>
      </form>
    </div>
  </woot-modal>
</template>

<script>
/* global bus */
/* eslint no-console: 0 */
import { required, minLength, email } from 'vuelidate/lib/validators';

import PageHeader from '../SettingsSubPageHeader';

const agentImg = require('assets/images/agent.svg');

export default {
  props: [
    'onClose',
  ],
  components: {
    PageHeader,
  },
  data() {
    return {
      agentName: '',
      agentEmail: '',
      agentType: this.$t('AGENT_MGMT.AGENT_TYPES')[1],
      vertical: 'bottom',
      horizontal: 'center',
      addAgentsApi: {
        showAlert: false,
        showLoading: false,
        message: '',
      },
      agentTypeList: this.$t('AGENT_MGMT.AGENT_TYPES'),
      show: true,
    };
  },
  computed: {
    headerImage() {
      return agentImg;
    },
  },
  validations: {
    agentName: {
      required,
      minLength: minLength(4),
    },
    agentEmail: {
      required,
      email,
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
      bus.$emit('newToastMessage', this.addAgentsApi.message);
    },
    resetForm() {
      this.agentName = this.agentEmail = '';
      this.$v.agentName.$reset();
      this.$v.agentEmail.$reset();
    },
    addAgent() {
      // Show loading on button
      this.addAgentsApi.showLoading = true;
      // Make API Calls
      this.$store.dispatch('addAgent', {
        name: this.agentName,
        email: this.agentEmail,
        role: this.agentType.name.toLowerCase(),
      })
      .then(() => {
        // Reset Form, Show success message
        this.addAgentsApi.showLoading = false;
        this.addAgentsApi.message = this.$t('AGENT_MGMT.ADD.API.SUCCESS_MESSAGE');
        this.showAlert();
        this.resetForm();
        this.onClose();
      })
      .catch(() => {
        this.addAgentsApi.showLoading = false;
        this.addAgentsApi.message = this.$t('AGENT_MGMT.ADD.API.ERROR_MESSAGE');
        this.showAlert();
      });
    },
  },
};
</script>
