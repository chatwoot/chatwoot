<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="pageTitle" />
      <form class="w-full" @submit.prevent="editAgent()">
        <div class="w-full">
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

        <div class="w-full">
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

        <div class="w-full">
          <label :class="{ error: $v.agentAvailability.$error }">
            {{ $t('PROFILE_SETTINGS.FORM.AVAILABILITY.LABEL') }}
            <select v-model="agentAvailability">
              <option
                v-for="role in availabilityStatuses"
                :key="role.value"
                :value="role.value"
              >
                {{ role.label }}
              </option>
            </select>
            <span v-if="$v.agentAvailability.$error" class="message">
              {{ $t('AGENT_MGMT.EDIT.FORM.AGENT_AVAILABILITY.ERROR') }}
            </span>
          </label>
        </div>
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <div class="w-[50%]">
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
          <div class="w-[50%] text-right">
            <woot-button
              icon="lock-closed"
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
import { useAlert } from 'dashboard/composables';
import WootSubmitButton from '../../../../components/buttons/FormSubmitButton.vue';
import Modal from '../../../../components/Modal.vue';
import Auth from '../../../../api/auth';
import wootConstants from 'dashboard/constants/globals';

const { AVAILABILITY_STATUS_KEYS } = wootConstants;

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
    availability: {
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
      agentAvailability: this.availability,
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
    agentAvailability: {
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
    availabilityStatuses() {
      return this.$t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUSES_LIST').map(
        (statusLabel, index) => ({
          label: statusLabel,
          value: AVAILABILITY_STATUS_KEYS[index],
          disabled:
            this.currentUserAvailability === AVAILABILITY_STATUS_KEYS[index],
        })
      );
    },
  },
  methods: {
    async editAgent() {
      try {
        await this.$store.dispatch('agents/update', {
          id: this.id,
          name: this.agentName,
          role: this.agentType,
          availability: this.agentAvailability,
        });
        useAlert(this.$t('AGENT_MGMT.EDIT.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        useAlert(this.$t('AGENT_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    async resetPassword() {
      try {
        await Auth.resetPassword(this.agentCredentials);
        useAlert(
          this.$t('AGENT_MGMT.EDIT.PASSWORD_RESET.ADMIN_SUCCESS_MESSAGE')
        );
      } catch (error) {
        useAlert(this.$t('AGENT_MGMT.EDIT.PASSWORD_RESET.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
