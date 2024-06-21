<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="h-auto overflow-auto flex flex-col">
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

        <div class="w-full mb-4">
          <label>
            {{ $t('AGENT_MGMT.PERMISSIONS.PERMISSIONS_LABEL') }}
            <div v-if="!uiFlags.isFetching" class="permissions-grid">
              <div
                v-for="permission in permissions"
                :key="permission.id"
                class="permission-item"
              >
                <span class="permission-label">{{ permission.label }}</span>
                <vue-toggles
                  checked-bg="#0091ff"
                  :value="permission.status"
                  @click="togglePermission(permission)"
                />
              </div>
            </div>
            <div v-else>
              <spinner class="m-5" size="large" color-scheme="primary" />
            </div>
          </label>
        </div>

        <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
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
import WootSubmitButton from '../../../../components/buttons/FormSubmitButton.vue';
import Modal from '../../../../components/Modal.vue';
import Auth from '../../../../api/auth';
import wootConstants from 'dashboard/constants/globals';
import Spinner from 'shared/components/Spinner.vue';
import VueToggles from 'vue-toggles';

const { AVAILABILITY_STATUS_KEYS } = wootConstants;

export default {
  components: {
    WootSubmitButton,
    Modal,
    Spinner,
    VueToggles,
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
        {
          name: 'supervisor',
          label: this.$t('AGENT_MGMT.AGENT_TYPES.SUPERVISOR'),
        },
      ],
      agentName: this.name,
      agentAvailability: this.availability,
      agentType: this.type,
      agentCredentials: {
        email: this.email,
      },
      show: true,
      permissions: [],
      modifiedPermissions: {},
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
      permissionsByUser: 'accounts/getPermissions',
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
  watch: {
    permissionsByUser: {
      immediate: true,
      handler(newPermissions) {
        this.permissions = Object.keys(newPermissions).map(permission => ({
          id: permission,
          label: this.$t(
            `AGENT_MGMT.PERMISSIONS.FEATURES.${permission.toUpperCase()}`
          ),
          status: newPermissions[permission],
        }));
      },
    },
  },
  mounted() {
    this.$store.dispatch('accounts/getPermissionsByUser', this.id);
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
          availability: this.agentAvailability,
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
    async updatePermissions() {
      try {
        await this.$store.dispatch('accounts/updatePermissionsByUser', {
          userId: this.id,
          permissions: this.modifiedPermissions,
        });
        this.showAlert(this.$t('AGENT_MGMT.PERMISSIONS.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('AGENT_MGMT.PERMISSIONS.API.ERROR_MESSAGE'));
      }
    },
    togglePermission(permission) {
      const updatedPermission = {
        ...permission,
        status: !permission.status,
      };
      this.permissions = this.permissions.map(p =>
        p.id === permission.id ? updatedPermission : p
      );
      this.modifiedPermissions[permission.id] = updatedPermission.status;
      this.$store.dispatch('accounts/updatePermission', {
        permission: updatedPermission,
      });
      this.updatePermissions();
    },
  },
};
</script>

<style scoped>
.permissions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 16px;
}
.permission-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
}
.permission-label {
  flex: 1;
  margin-right: 8px;
}
</style>
