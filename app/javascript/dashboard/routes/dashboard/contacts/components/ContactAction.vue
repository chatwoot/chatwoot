<!-- eslint-disable vue/v-slot-style -->
<template>
  <div class="bg-white dark:bg-slate-900">
    <div class="break-words mb-0.5 text-right">
      <p
        v-if="contact.stage"
        class="text-slate-800 font-medium dark:text-slate-100 text-sm"
      >
        {{ contact.stage.name }}
      </p>
      <p v-if="contact.initial_channel_type">
        {{
          $t('CONTACTS_PAGE.LIST.TABLE_HEADER.INITIAL_CHANNEL') +
          ' ' +
          contact.initial_channel_type
        }}
      </p>
    </div>
    <contact-details-item
      compact
      :title="$t('CONTACTS_PAGE.LIST.TABLE_HEADER.LAST_NOTE')"
    >
      <template v-slot:button>
        <woot-button
          icon="arrow-right"
          variant="link"
          size="small"
          @click="onToggleAddNote"
        >
          {{ addOrCancelNoteLabel }}
        </woot-button>
      </template>
    </contact-details-item>
    <p v-if="contact.last_note" class="italic">
      {{ contact.last_note }}
    </p>
    <p v-else class="italic">{{ $t('CONTACT_PANEL.ACTIONS.NO_NOTE') }}</p>
    <add-note v-if="showNewNote" @add="onAddNote" />
    <div class="multiselect-wrap--small">
      <contact-details-item
        compact
        :title="$t('CONTACTS_PAGE.LIST.TABLE_HEADER.LEAD_ASSIGNEE')"
      />
      <multiselect-dropdown
        :options="agentsList"
        :selected-item="contact.assignee_in_leads"
        :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.AGENT')"
        :multiselector-placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
        :no-search-result="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.AGENT')
        "
        :input-placeholder="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
        "
      />
    </div>
    <div class="multiselect-wrap--small">
      <contact-details-item
        compact
        :title="$t('CONTACTS_PAGE.LIST.TABLE_HEADER.DEAL_ASSIGNEE')"
      />
      <multiselect-dropdown
        :options="agentsList"
        :selected-item="contact.assignee_in_deals"
        :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.AGENT')"
        :multiselector-placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
        :no-search-result="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.AGENT')
        "
        :input-placeholder="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
        "
      />
    </div>
    <div class="multiselect-wrap--small">
      <contact-details-item
        compact
        :title="$t('CONTACTS_PAGE.LIST.TABLE_HEADER.TEAM_NAME')"
      />
      <multiselect-dropdown
        :options="teamsList"
        :selected-item="contact.team"
        :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.TEAM')"
        :multiselector-placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
        :no-search-result="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.TEAM')
        "
        :input-placeholder="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.INPUT')
        "
        @click="onClickAssignTeam"
      />
    </div>
  </div>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import ContactDetailsItem from 'dashboard/routes/dashboard/conversation/ContactDetailsItem.vue';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import AddNote from 'dashboard/modules/notes/components/AddNote.vue';
import agentMixin from 'dashboard/mixins/agentMixin';
import teamMixin from 'dashboard/mixins/conversation/teamMixin';

export default {
  components: {
    ContactDetailsItem,
    MultiselectDropdown,
    AddNote,
  },
  mixins: [agentMixin, alertMixin, teamMixin],
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      showNewNote: false,
    };
  },
  computed: {
    addOrCancelNoteLabel() {
      return this.showNewNote
        ? this.$t('CONTACT_PANEL.ACTIONS.CANCEL_ADD_NOTE')
        : this.$t('CONTACT_PANEL.ACTIONS.ADD_NOTE');
    },
    initialChannel() {
      return (
        this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.INITIAL_CHANNEL') +
        ' ' +
        this.contact.initial_channel_type
      );
    },
    assignedAgent: {
      get() {
        return this.contact.assignee_in_leads;
      },
      set(agent) {
        const agentId = agent ? agent.id : 0;
        this.$store.dispatch('setCurrentChatAssignee', agent);
        this.$store
          .dispatch('assignAgent', {
            conversationId: this.currentChat.id,
            agentId,
          })
          .then(() => {
            this.showAlert(this.$t('CONVERSATION.CHANGE_AGENT'));
          });
      },
    },
    assignedTeam: {
      get() {
        return this.contact.team_id;
      },
      set(team) {
        const conversationId = this.currentChat.id;
        const teamId = team ? team.id : 0;
        this.$store.dispatch('setCurrentChatTeam', { team, conversationId });
        this.$store
          .dispatch('assignTeam', { conversationId, teamId })
          .then(() => {
            this.showAlert(this.$t('CONVERSATION.CHANGE_TEAM'));
          });
      },
    },
  },
  methods: {
    onToggleAddNote() {
      this.showNewNote = !this.showNewNote;
    },
    onAddNote(content) {
      const contactId = this.contact.id;
      this.$store.dispatch('contactNotes/create', { content, contactId });
      this.$store.dispatch('contacts/show', { id: contactId });
      this.onToggleAddNote();
    },
    onClickAssignAgent(selectedItem) {
      if (this.assignedAgent && this.assignedAgent.id === selectedItem.id) {
        this.assignedAgent = null;
      } else {
        this.assignedAgent = selectedItem;
      }
    },

    onClickAssignTeam(selectedItemTeam) {
      if (this.assignedTeam && this.assignedTeam.id === selectedItemTeam.id) {
        this.assignedTeam = null;
      } else {
        this.assignedTeam = selectedItemTeam;
      }
    },
  },
};
</script>
