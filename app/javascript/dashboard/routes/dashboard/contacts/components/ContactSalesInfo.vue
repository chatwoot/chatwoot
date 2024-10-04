<!-- eslint-disable vue/v-slot-style -->
<template>
  <div class="bg-white dark:bg-slate-900">
    <div class="break-words mb-0.5 text-right">
      <p
        v-if="contact.stage"
        class="text-slate-800 font-medium dark:text-slate-100 text-sm"
      >
        {{
          $t('CONTACTS_PAGE.LIST.TABLE_HEADER.STAGE_NAME') +
          ': ' +
          contact.stage.name
        }}
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
    <div class="ml-1">
      <p
        v-if="contact.last_note"
        v-dompurify-html="formatMessage(contact.last_note || '')"
        class="note__content"
      />
      <p v-else class="italic">{{ $t('CONTACT_PANEL.ACTIONS.NO_NOTE') }}</p>
    </div>
    <add-note v-if="showAddNote" @add="onAddNote" />
    <contact-details-item
      compact
      :title="$t('CONTACTS_PAGE.LIST.TABLE_HEADER.ACTION_DESCRIPTION')"
    >
      <template v-slot:button>
        <woot-button
          v-if="showAddActionButton"
          icon="arrow-right"
          variant="link"
          size="small"
          @click="toggleNewActionModal"
        >
          {{ $t('CONTACT_PANEL.ACTIONS.ADD_ACTION') }}
        </woot-button>
      </template>
    </contact-details-item>
    <div class="ml-1">
      <contact-conversation-plans v-if="contact.id" :contact-id="contact.id" />
    </div>
    <contact-new-action
      v-if="contact.id"
      :show="showNewActionModal"
      :contact="contact"
      @cancel="toggleNewActionModal"
    />
    <div v-if="showAssigneeInfo" class="multiselect-wrap--small">
      <contact-details-item
        compact
        :title="$t('CONTACTS_PAGE.LIST.TABLE_HEADER.ASSIGNEE')"
      />
      <multiselect-dropdown
        :options="agents"
        :selected-item="assignee"
        :multiselector-placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
        :input-placeholder="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
        "
        @click="onClickAssignee"
      />
    </div>
    <div v-if="showAssigneeInfo" class="multiselect-wrap--small">
      <contact-details-item
        compact
        :title="$t('CONTACTS_PAGE.LIST.TABLE_HEADER.TEAM_NAME')"
      />
      <multiselect-dropdown
        :options="teams"
        :selected-item="assignedTeam"
        :multiselector-placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
        :input-placeholder="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.TEAM')
        "
        @click="onClickAssignTeam"
      />
    </div>
    <contact-label :contact-id="contact.id" class="contact-labels" />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import ContactDetailsItem from 'dashboard/routes/dashboard/conversation/ContactDetailsItem.vue';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import AddNote from 'dashboard/modules/notes/components/AddNote.vue';
import ContactNewAction from './ContactNewAction.vue';
import ContactLabel from 'dashboard/routes/dashboard/contacts/components/ContactLabels.vue';
import ContactConversationPlans from 'dashboard/routes/dashboard/contacts/components/ContactConversationPlans.vue';
import agentMixin from 'dashboard/mixins/agentMixin';
import contactMixin from 'dashboard/mixins/contactMixin';
import teamMixin from 'dashboard/mixins/conversation/teamMixin';
import errorCaptureMixin from 'shared/mixins/errorCaptureMixin';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';

export default {
  components: {
    ContactDetailsItem,
    MultiselectDropdown,
    AddNote,
    ContactNewAction,
    ContactLabel,
    ContactConversationPlans,
  },
  mixins: [
    agentMixin,
    alertMixin,
    teamMixin,
    contactMixin,
    errorCaptureMixin,
    messageFormatterMixin,
  ],
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
    showAssigneeInfo: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      showNewActionModal: false,
      showAddNote: false,
    };
  },
  computed: {
    ...mapGetters({
      agents: 'agents/getAgents',
      teams: 'teams/getTeams',
    }),
    addOrCancelNoteLabel() {
      return this.showAddNote
        ? this.$t('CONTACT_PANEL.ACTIONS.CANCEL_ADD_NOTE')
        : this.$t('CONTACT_PANEL.ACTIONS.ADD_NOTE');
    },
    showAddActionButton() {
      const isResolved = val => val.status === 'resolved';
      return (
        !this.contact.conversation_plans ||
        this.contact.conversation_plans.every(isResolved)
      );
    },
    assignee: {
      get() {
        return this.contact.assignee;
      },
      set(agent) {
        const agentId = agent ? agent.id : null;
        const contactItem = {
          id: this.contact.id,
          assignee_id: agentId,
        };
        this.$store
          .dispatch('contacts/update', contactItem)
          .then(() => {
            this.showAlert(this.$t('CONTACT_PANEL.ACTIONS.CHANGE_AGENT'));
          })
          .catch(error => {
            this.showAlert(error.message);
          });
      },
    },
    assignedTeam: {
      get() {
        return this.contact.team;
      },
      set(team) {
        const teamId = team ? team.id : 0;
        const contactItem = {
          id: this.contact.id,
          team_id: teamId,
        };
        this.$store
          .dispatch('contacts/update', contactItem)
          .then(() => {
            this.showAlert(this.$t('CONTACT_PANEL.ACTIONS.CHANGE_TEAM'));
          })
          .catch(error => {
            this.showAlert(error.message);
          });
      },
    },
  },
  watch: {
    showAddNote() {
      this.$store.dispatch('setReplyBoxCanFocus', !this.showAddNote);
    },
  },
  mounted() {
    this.$store.dispatch('agents/get');
  },
  methods: {
    toggleNewActionModal() {
      this.showNewActionModal = !this.showNewActionModal;
    },
    onToggleAddNote() {
      this.showAddNote = !this.showAddNote;
    },
    onAddNote(content) {
      const contactId = this.contact.id;
      this.$store.dispatch('contactNotes/create', { content, contactId });
      this.$store.dispatch('contacts/show', { id: contactId });
      this.onToggleAddNote();
    },
    onClickAssignee(selectedItem) {
      if (this.assignee && this.assignee.id === selectedItem.id) {
        this.assignee = null;
      } else {
        this.assignee = selectedItem;
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
