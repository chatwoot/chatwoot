<script>
/* eslint no-console: 0 */
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';

import InboxMembersAPI from '../../../../api/inboxMembers';
import NextButton from 'dashboard/components-next/button/Button.vue';
import router from '../../../index';
import PageHeader from '../SettingsSubPageHeader.vue';
import AddAgent from '../agents/AddAgent.vue';
import { useVuelidate } from '@vuelidate/core';

export default {
  components: {
    PageHeader,
    NextButton,
    AddAgent,
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
      showAddAgentModal: false,
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
          name: 'settings_inbox_finish',
          params: {
            page: 'new',
            inbox_id: this.$route.params.inbox_id,
          },
        });
      } catch (error) {
        useAlert(error.message);
      }
      this.isCreating = false;
    },
    openAddAgentModal() {
      this.showAddAgentModal = true;
    },
    hideAddAgentModal() {
      this.showAddAgentModal = false;
    },
    onAgentCreated(agent) {
      // Add newly created agent to selection (append + dedupe by id)
      const alreadySelected = this.selectedAgents.some(a => a.id === agent.id);
      if (!alreadySelected) {
        this.selectedAgents = [...this.selectedAgents, agent];
      }
      this.hideAddAgentModal();
    },
  },
};
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <form class="flex flex-wrap flex-col mx-0" @submit.prevent="addAgents()">
      <div class="w-full">
        <PageHeader
          :header-title="$t('INBOX_MGMT.ADD.AGENTS.TITLE')"
          :header-content="$t('INBOX_MGMT.ADD.AGENTS.DESC')"
        />
      </div>
      <div>
        <div class="w-full">
          <label :class="{ error: v$.selectedAgents.$error }">
            {{ $t('INBOX_MGMT.ADD.AGENTS.TITLE') }}
            <multiselect
              v-model="selectedAgents"
              :options="agentList"
              track-by="id"
              label="name"
              multiple
              :close-on-select="false"
              :clear-on-select="false"
              hide-selected
              selected-label
              :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
              :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
              :placeholder="$t('INBOX_MGMT.ADD.AGENTS.PICK_AGENTS')"
              @select="v$.selectedAgents.$touch"
            />
            <span v-if="v$.selectedAgents.$error" class="message">
              {{ $t('INBOX_MGMT.ADD.AGENTS.VALIDATION_ERROR') }}
            </span>
          </label>
        </div>
        <div class="w-full flex gap-2 mt-4">
          <NextButton
            type="submit"
            :is-loading="isCreating"
            solid
            blue
            :label="$t('INBOX_MGMT.AGENTS.BUTTON_TEXT')"
          />
          <NextButton
            type="button"
            faded
            slate
            :label="$t('INBOX_MGMT.AGENTS.ONBOARD_NEW_AGENT')"
            @click="openAddAgentModal"
          />
        </div>
      </div>
    </form>

    <woot-modal v-model:show="showAddAgentModal" :on-close="hideAddAgentModal">
      <AddAgent @close="hideAddAgentModal" @agent-created="onAgentCreated" />
    </woot-modal>
  </div>
</template>
