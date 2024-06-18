<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="h-auto overflow-auto flex flex-col">
      <woot-modal-header :header-title="$t('AGENT_MGMT.PERMISSIONS.TITLE')" />
      <form class="w-full" @submit.prevent="updatePermissions">
        <div class="w-full mb-4">
          <label>
            {{ $t('AGENT_MGMT.PERMISSIONS.AGENT_NAME') }}
            <input v-model="localAgent.name" type="text" disabled />
          </label>
        </div>
        <div class="w-full mb-4">
          <label>
            {{ $t('AGENT_MGMT.PERMISSIONS.AGENT_EMAIL') }}
            <input v-model="localAgent.email" type="text" disabled />
          </label>
        </div>
        <div class="w-full mb-4">
          <label>
            {{ $t('AGENT_MGMT.PERMISSIONS.AGENT_TYPE') }}
            <select v-model="localAgent.role" disabled>
              <option v-for="role in roles" :key="role.name" :value="role.name">
                {{ role.label }}
              </option>
            </select>
          </label>
        </div>
        <div class="w-full mb-4">
          <label>
            {{ $t('AGENT_MGMT.PERMISSIONS.PERMISSIONS_LABEL') }}
            <select
              v-if="!uiFlags.isFetching"
              v-model="selectedPermissions"
              multiple
            >
              <option
                v-for="permission in permissions"
                :key="permission.id"
                :value="permission.id"
              >
                {{ permission.label }} - {{ permission.status }}
              </option>
            </select>
            <div v-else>
              <spinner class="m-5" size="large" color-scheme="primary" />
            </div>
          </label>
        </div>
        <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
          <div class="w-full">
            <woot-submit-button
              :disabled="uiFlags.isUpdating"
              :button-text="$t('AGENT_MGMT.PERMISSIONS.SUBMIT')"
              :loading="uiFlags.isUpdating"
            />
            <button class="button clear" @click.prevent="onClose">
              {{ $t('AGENT_MGMT.PERMISSIONS.CANCEL_BUTTON_TEXT') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </modal>
</template>

<script>
import { mapGetters } from 'vuex';
import WootSubmitButton from '../../../../components/buttons/FormSubmitButton.vue';
import Modal from '../../../../components/Modal.vue';
import Spinner from 'shared/components/Spinner.vue';

export default {
  name: 'EditPermissionAgent',
  components: {
    WootSubmitButton,
    Spinner,
    Modal,
  },
  props: {
    agent: {
      type: Object,
      required: true,
    },
    onClose: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      localAgent: { ...this.agent },
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
      selectedPermissions: [],
      show: true,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'accounts/getUIFlags',
      permissionsByUser: 'accounts/getPermissions',
    }),
    permissions() {
      return Object.keys(this.permissionsByUser).map(permission => ({
        id: permission,
        label: this.$t(
          `AGENT_MGMT.PERMISSIONS.FEATURES.${permission.toUpperCase()}`
        ),
        status: this.permissionsByUser[permission],
      }));
    },
  },
  mounted() {
    this.$store.dispatch('accounts/getPermissionsByUser', this.localAgent.id);
  },
  methods: {
    async updatePermissions() {
      try {
        await this.$store.dispatch('accounts/updatePermissionsByUser', {
          id: this.localAgent.id,
          permissions: this.selectedPermissions,
        });
        this.showAlert(this.$t('AGENT_MGMT.PERMISSIONS.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        this.showAlert(this.$t('AGENT_MGMT.PERMISSIONS.API.ERROR_MESSAGE'));
      }
    },
    showAlert(message) {
      bus.$emit('newToastMessage', message);
    },
  },
};
</script>
