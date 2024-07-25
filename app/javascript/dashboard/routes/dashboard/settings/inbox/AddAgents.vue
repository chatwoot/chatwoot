<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <form class="flex flex-wrap mx-0" @submit.prevent="addAgents()">
      <div class="w-full">
        <page-header
          :header-title="$t('INBOX_MGMT.ADD.AGENTS.TITLE')"
          :header-content="$t('INBOX_MGMT.ADD.AGENTS.DESC')"
        />
      </div>
      <div class="w-3/5">
        <div class="w-full">
          <label :class="{ error: $v.selectedAgents.$error }">
            {{ $t('INBOX_MGMT.ADD.AGENTS.TITLE') }}
            <multiselect
              v-model="selectedAgents"
              :options="agentList"
              track-by="id"
              label="name"
              :multiple="true"
              :close-on-select="false"
              :clear-on-select="false"
              :hide-selected="true"
              selected-label
              :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
              :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
              :placeholder="$t('INBOX_MGMT.ADD.AGENTS.PICK_AGENTS')"
              @select="$v.selectedAgents.$touch"
            />
            <span v-if="$v.selectedAgents.$error" class="message">
              {{ $t('INBOX_MGMT.ADD.AGENTS.VALIDATION_ERROR') }}
            </span>
          </label>
        </div>
        <div class="w-full">
          <woot-submit-button
            :button-text="$t('INBOX_MGMT.AGENTS.BUTTON_TEXT')"
            :loading="isCreating"
          />
        </div>
      </div>
    </form>
  </div>
</template>

<script>
/* eslint no-console: 0 */
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';

import InboxMembersAPI from '../../../../api/inboxMembers';
import router from '../../../index';
import PageHeader from '../SettingsSubPageHeader.vue';

export default {
  components: {
    PageHeader,
  },

  validations: {
    selectedAgents: {
      isEmpty() {
        return !!this.selectedAgents.length;
      },
    },
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
  },
};
</script>
