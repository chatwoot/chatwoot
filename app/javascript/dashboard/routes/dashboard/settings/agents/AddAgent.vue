<template>
  <woot-modal :show.sync="show" :on-close="onClose">
    <div class="h-auto overflow-auto flex flex-col">
      <woot-modal-header
        :header-title="$t('AGENT_MGMT.ADD.TITLE')"
        :header-content="$t('AGENT_MGMT.ADD.DESC')"
      />

      <form
        class="flex flex-col w-full items-start"
        @submit.prevent="addAgent()"
      >
        <div class="w-full">
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
        <div class="w-full">
          <label :class="{ error: $v.agentType.$error }">
            {{ $t('AGENT_MGMT.ADD.FORM.AGENT_TYPE.LABEL') }}
            <select v-model="agentType">
              <option v-for="role in roles" :key="role.name" :value="role.name">
                {{ role.label }}
              </option>
            </select>
            <span v-if="$v.agentType.$error" class="message">
              {{ $t('AGENT_MGMT.ADD.FORM.AGENT_TYPE.ERROR') }}
            </span>
          </label>
        </div>
        <div class="w-full">
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
        <div v-if="agentType === 'supervisor'" class="w-full">
          {{ $t('AGENT_MGMT.ADD.FORM.INBOX.LABEL') }}
          <multiselect
            v-model="selectInboxes"
            :options="inboxes"
            :multiple="true"
            :placeholder="$t('AGENT_MGMT.ADD.FORM.INBOX.PLACEHOLDER')"
            label="name"
            track-by="id"
            :allow-empty="true"
            :searchable="false"
            :close-on-select="false"
            @input="$v.selectInboxes.$touch"
          />
        </div>
        <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
          <div class="w-full">
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
      selectInboxes: [],
      agentName: '',
      agentEmail: '',
      agentType: 'agent',
      vertical: 'bottom',
      horizontal: 'center',
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
      show: true,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'agents/getUIFlags',
      agents: 'agents/getAgents',
      inboxes: 'inboxes/getInboxes',
    }),
  },
  validations: {
    agentName: {
      required,
      minLength: minLength(1),
    },
    agentEmail: {
      required,
      email,
    },
    agentType: {
      required,
    },
    selectInboxes: {},
  },
  mounted() {
    this.$store.dispatch('inboxes/get');
  },
  methods: {
    showAlert(message) {
      bus.$emit('newToastMessage', message);
    },
    async addAgent() {
      try {
        await this.$store.dispatch('agents/create', {
          name: this.agentName,
          email: this.agentEmail,
          role: this.agentType,
          inbox_ids: this.selectInboxes.map(inbox => inbox.id),
        });

        this.showAlert(this.$t('AGENT_MGMT.ADD.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        const { response: { data: { error: errorResponse = '' } = {} } = {} } =
          error;
        let errorMessage = '';
        if (error.response.status === 422) {
          errorMessage = this.$t('AGENT_MGMT.ADD.API.EXIST_MESSAGE');
        } else {
          errorMessage = this.$t('AGENT_MGMT.ADD.API.ERROR_MESSAGE');
        }
        this.showAlert(errorResponse || errorMessage);
      }
    },
  },
};
</script>
