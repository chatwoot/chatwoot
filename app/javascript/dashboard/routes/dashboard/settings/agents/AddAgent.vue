<template>
  <woot-modal :show.sync="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header
        :header-title="$t('AGENT_MGMT.ADD.TITLE')"
        :header-content="$t('AGENT_MGMT.ADD.DESC')"
      />

      <form
        class="flex flex-col items-start w-full"
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
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
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
import { useAlert } from 'dashboard/composables';

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
      ],
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
      minLength: minLength(1),
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
    async addAgent() {
      try {
        await this.$store.dispatch('agents/create', {
          name: this.agentName,
          email: this.agentEmail,
          role: this.agentType,
        });
        useAlert(this.$t('AGENT_MGMT.ADD.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        const {
          response: {
            data: {
              error: errorResponse = '',
              attributes: attributes = [],
              message: attrError = '',
            } = {},
          } = {},
        } = error;

        let errorMessage = '';
        if (error?.response?.status === 422 && !attributes.includes('base')) {
          errorMessage = this.$t('AGENT_MGMT.ADD.API.EXIST_MESSAGE');
        } else {
          errorMessage = this.$t('AGENT_MGMT.ADD.API.ERROR_MESSAGE');
        }
        useAlert(errorResponse || attrError || errorMessage);
      }
    },
  },
};
</script>
