<template>
  <woot-modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header
        :header-title="$t('AGENT_MGMT.ADD.TITLE')"
        :header-content="$t('AGENT_MGMT.ADD.DESC')"
      />

      <form class="row" @submit.prevent="addAgent()">
        <div class="medium-12 columns">
          <label :class="{ error: $v.agentName.$error }">
            {{ $t('AGENT_MGMT.ADD.FORM.NAME.LABEL') }}
            <input
              v-model.trim="agentName"
              type="text"
              :placeholder="$t('AGENT_MGMT.ADD.FORM.NAME.PLACEHOLDER')"
              @input="$v.agentName.$touch"
            />
          </label>
        </div>
        <div class="medium-12 columns">
          <label :class="{ error: $v.agentType.$error }">
            {{ $t('AGENT_MGMT.ADD.FORM.AGENT_TYPE.LABEL') }}
            <multiselect
              v-model="agentType"
              :options="agentTypeList"
              :searchable="false"
              label="label"
              :placeholder="$t('AGENT_MGMT.ADD.FORM.AGENT_TYPE.PLACEHOLDER')"
              :allow-empty="true"
              :close-on-select="true"
              @select="setPageName"
            />
            <span v-if="$v.agentType.$error" class="message">
              {{ $t('AGENT_MGMT.ADD.FORM.AGENT_TYPE.ERROR') }}
            </span>
          </label>
        </div>
        <div class="medium-12 columns">
          <label :class="{ error: $v.agentEmail.$error }">
            {{ $t('AGENT_MGMT.ADD.FORM.EMAIL.LABEL') }}
            <input
              v-model.trim="agentEmail"
              type="text"
              :placeholder="$t('AGENT_MGMT.ADD.FORM.EMAIL.PLACEHOLDER')"
              @input="$v.agentEmail.$touch"
            />
          </label>
        </div>
        <div class="modal-footer">
          <div class="medium-12 columns">
            <woot-submit-button
              :disabled="
                $v.agentEmail.$invalid ||
                  $v.agentName.$invalid ||
                  uiFlags.isCreating
              "
              :button-text="$t('AGENT_MGMT.ADD.FORM.SUBMIT')"
              :loading="uiFlags.isCreating"
            />
            <button class="button clear" @click.prevent="onClose">
              {{ $t('AGENT_MGMT.ADD.CANCEL_BUTTON_TEXT') }}
            </button>
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
import { mapGetters } from 'vuex';

export default {
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      agentName: '',
      agentEmail: '',
      agentType: this.$t('AGENT_MGMT.AGENT_TYPES')[1],
      vertical: 'bottom',
      horizontal: 'center',
      agentTypeList: this.$t('AGENT_MGMT.AGENT_TYPES'),
      show: true,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'agents/getUIFlags',
    }),
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
    showAlert(message) {
      bus.$emit('newToastMessage', message);
    },
    async addAgent() {
      try {
        await this.$store.dispatch('agents/create', {
          name: this.agentName,
          email: this.agentEmail,
          role: this.agentType.name.toLowerCase(),
        });
        this.showAlert(this.$t('AGENT_MGMT.ADD.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        if (error.response.status === 422) {
          this.showAlert(this.$t('AGENT_MGMT.ADD.API.EXIST_MESSAGE'));
        } else {
          this.showAlert(this.$t('AGENT_MGMT.ADD.API.ERROR_MESSAGE'));
        }
      }
    },
  },
};
</script>
