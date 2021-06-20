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
            <select v-model="agentType">
              <option v-for="role in roles" :key="role.name" :value="role.name">
                {{ role.label }}
              </option>
            </select>
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
                  uiFlags.isUpdating
              "
              :button-text="$t('AGENT_MGMT.EDIT.FORM.SUBMIT')"
              :loading="uiFlags.isUpdating"
            />
            <button class="button clear" @click.prevent="onClose">
              {{ $t('AGENT_MGMT.EDIT.CANCEL_BUTTON_TEXT') }}
            </button>
          </div>
          <div class="medium-6 columns text-right">
            <woot-button
              icon="ion-locked"
              variant="clear"
              @click.prevent="resetPassword"
            >
              {{ $t('AGENT_MGMT.EDIT.PASSWORD_RESET.ADMIN_RESET_BUTTON') }}
            </woot-button>
          </div>
        </div>
      </form>
    </div>
  </modal>
</template>

<script>
import { required, minLength } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import WootSubmitButton from '../../../../components/buttons/FormSubmitButton';
import Modal from '../../../../components/Modal';
import Auth from '../../../../api/auth';

export default {
  components: {
    WootSubmitButton,
    Modal,
  },
  props: {
    id: {
      type: Number,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    email: {
      type: String,
      default: '',
    },
    type: {
      type: String,
      default: '',
    },
    onClose: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      roles: [
        {
          name: 'administrator',
          label: this.$t('AGENT_MGMT.AGENT_TYPES.ADMINISTRATOR'),
        },
        {
          name: 'agent',
          label: this.$t('AGENT_MGMT.AGENT_TYPES.AGENT'),
        },
      ],
      agentName: this.name,
      agentType: this.type,
      agentCredentials: {
        email: this.email,
      },
      show: true,
    };
  },
  validations: {
    agentName: {
      required,
      minLength: minLength(1),
    },
    agentType: {
      required,
    },
  },
  computed: {
    pageTitle() {
      return `${this.$t('AGENT_MGMT.EDIT.TITLE')} - ${this.name}`;
    },
    ...mapGetters({
      uiFlags: 'agents/getUIFlags',
    }),
  },
  methods: {
    showAlert(message) {
      bus.$emit('newToastMessage', message);
    },
    async editAgent() {
      try {
        await this.$store.dispatch('agents/update', {
          id: this.id,
          name: this.agentName,
          role: this.agentType,
        });
        this.showAlert(this.$t('AGENT_MGMT.EDIT.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        this.showAlert(this.$t('AGENT_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    async resetPassword() {
      try {
        await Auth.resetPassword(this.agentCredentials);
        this.showAlert(
          this.$t('AGENT_MGMT.EDIT.PASSWORD_RESET.ADMIN_SUCCESS_MESSAGE')
        );
      } catch (error) {
        this.showAlert(this.$t('AGENT_MGMT.EDIT.PASSWORD_RESET.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
