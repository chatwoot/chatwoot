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
    <div class="ml-1">
      <p v-if="contact.last_note">
        {{ contact.last_note }}
      </p>
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
      <p v-if="contact.current_action">
        {{ currentActionText(contact.current_action) }}
      </p>
      <p v-else class="italic">{{ $t('CONTACT_PANEL.ACTIONS.NO_ACTION') }}</p>
    </div>
    <contact-new-action
      v-if="contact.id"
      :show="showNewActionModal"
      :contact="contact"
      @cancel="toggleNewActionModal"
    />
    <div class="multiselect-wrap--small">
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
    <div class="multiselect-wrap--small">
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
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import ContactDetailsItem from 'dashboard/routes/dashboard/conversation/ContactDetailsItem.vue';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import AddNote from 'dashboard/modules/notes/components/AddNote.vue';
import ContactNewAction from './ContactNewAction.vue';
import agentMixin from 'dashboard/mixins/agentMixin';
import contactMixin from 'dashboard/mixins/contactMixin';
import teamMixin from 'dashboard/mixins/conversation/teamMixin';
import errorCaptureMixin from 'shared/mixins/errorCaptureMixin';

export default {
  components: {
    ContactDetailsItem,
    MultiselectDropdown,
    AddNote,
    ContactNewAction,
  },
  mixins: [agentMixin, alertMixin, teamMixin, contactMixin, errorCaptureMixin],
  props: {
    contact: {
      type: Object,
      default: () => ({}),
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
      return (
        !this.contact.current_action ||
        this.contact.current_action.status === 'resolved'
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
        this.$store.dispatch('contacts/update', contactItem).then(() => {
          this.showAlert(this.$t('CONTACT_PANEL.ACTIONS.CHANGE_AGENT'));
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
        this.$store.dispatch('contacts/update', contactItem).then(() => {
          this.showAlert(this.$t('CONTACT_PANEL.ACTIONS.CHANGE_TEAM'));
        });
      },
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
