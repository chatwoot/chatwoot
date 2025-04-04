<script>
/* eslint no-console: 0 */
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import InboxMembersAPI from '../../../dashboard/api/inboxMembers';
import router from '../../../dashboard/routes/index';

import OnboardingBaseModal from './BaseModal.vue'; // Assuming this is the correct import path
import { useVuelidate } from '@vuelidate/core';

export default {
  components: {
    OnboardingBaseModal,
  },
  validations: {
    selectedAgents: {
      isEmpty() {
        return !!this.selectedAgents.length;
      },
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      selectedAgents: [],
      isCreating: false,
    };
  },
  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
    }),
  },
  mounted() {
    this.$store.dispatch('agents/get');
  },
  methods: {
    async addAgents() {
      this.isCreating = true;
      const inboxId = this.$route.params.inbox_id;
      const selectedAgents = this.selectedAgents.map(x => x.id);

      try {
        await InboxMembersAPI.update({ inboxId, agentList: selectedAgents });
        router.replace({
          name: 'onboarding_setup_inbox_finish',
          params: {
            inbox_id: this.$route.params.inbox_id,
          },
        });
      } catch (error) {
        useAlert(error.message);
      }
      this.isCreating = false;
    },
  },
};
</script>

<template>
  <onboarding-base-modal
    :title="$t('START_ONBOARDING.INBOX_ADD_AGENTS.TITLE')"
    :subtitle="$t('START_ONBOARDING.INBOX_ADD_AGENTS.DESC')"
  >
    <form class="space-y-6" @submit.prevent="addAgents()">
      <div>
        <label>
          {{ $t('INBOX_MGMT.ADD.AGENTS.TITLE') }}
          <multiselect
            v-model="selectedAgents"
            :options="agentList"
            track-by="id"
            label="name"
            multiple
            :close-on-select="false"
            :clear-on-select="false"
            :hide-selected="true"
            :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
            :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
            :placeholder="$t('INBOX_MGMT.ADD.AGENTS.PICK_AGENTS')"
          />
        </label>
      </div>
      <woot-submit-button
        button-class="flex justify-center w-full text-sm text-center"
        :button-text="$t('INBOX_MGMT.AGENTS.BUTTON_TEXT')"
        :disabled="!selectedAgents.length"
      />
    </form>
  </onboarding-base-modal>
</template>

<style scoped>
.multiselect {
  background-color: #333;
  color: #fff;
  border: 1px solid #555;
}
.multiselect__tags {
  background-color: #333;
  border: none;
}
.multiselect__option--highlight {
  background: #667eea;
}
</style>
