<!-- eslint-disable vue/v-slot-style -->
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useAgentsList } from 'dashboard/composables/useAgentsList';
import ContactDetailsItem from './ContactDetailsItem.vue';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import ConversationLabels from './labels/LabelBox.vue';
import { CONVERSATION_PRIORITY } from '../../../../shared/constants/messages';
import { CONVERSATION_EVENTS } from '../../../helper/AnalyticsHelper/events';
import { useTrack } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    ContactDetailsItem,
    MultiselectDropdown,
    ConversationLabels,
    NextButton,
  },
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  setup() {
    const { agentsList } = useAgentsList();
    return {
      agentsList,
    };
  },
  data() {
    return {
      transferAction: 'assign_agent',
      transferReason: '',
      transferPriority: 'normal',
      transferActionOptions: [
        {
          id: 'assign_self',
          name: this.$t('CONVERSATION_SIDEBAR.TRANSFER.ACTIONS.ASSIGN_SELF'),
        },
        {
          id: 'assign_agent',
          name: this.$t('CONVERSATION_SIDEBAR.TRANSFER.ACTIONS.ASSIGN_AGENT'),
        },
        {
          id: 'assign_team',
          name: this.$t('CONVERSATION_SIDEBAR.TRANSFER.ACTIONS.ASSIGN_TEAM'),
        },
        {
          id: 'queue_team',
          name: this.$t('CONVERSATION_SIDEBAR.TRANSFER.ACTIONS.QUEUE_TEAM'),
        },
      ],
      transferPriorityOptions: [
        { id: 'low', name: this.$t('CONVERSATION.PRIORITY.OPTIONS.LOW') },
        { id: 'normal', name: this.$t('CONVERSATION.PRIORITY.OPTIONS.NONE') },
        { id: 'high', name: this.$t('CONVERSATION.PRIORITY.OPTIONS.HIGH') },
        { id: 'urgent', name: this.$t('CONVERSATION.PRIORITY.OPTIONS.URGENT') },
      ],
      priorityOptions: [
        {
          id: null,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.NONE'),
          thumbnail: `/assets/images/dashboard/priority/none.svg`,
        },
        {
          id: CONVERSATION_PRIORITY.URGENT,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.URGENT'),
          thumbnail: `/assets/images/dashboard/priority/${CONVERSATION_PRIORITY.URGENT}.svg`,
        },
        {
          id: CONVERSATION_PRIORITY.HIGH,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.HIGH'),
          thumbnail: `/assets/images/dashboard/priority/${CONVERSATION_PRIORITY.HIGH}.svg`,
        },
        {
          id: CONVERSATION_PRIORITY.MEDIUM,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.MEDIUM'),
          thumbnail: `/assets/images/dashboard/priority/${CONVERSATION_PRIORITY.MEDIUM}.svg`,
        },
        {
          id: CONVERSATION_PRIORITY.LOW,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.LOW'),
          thumbnail: `/assets/images/dashboard/priority/${CONVERSATION_PRIORITY.LOW}.svg`,
        },
      ],
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      currentUser: 'getCurrentUser',
      teams: 'teams/getTeams',
    }),
    hasAnAssignedTeam() {
      return !!this.currentChat?.meta?.team;
    },
    teamsList() {
      if (this.hasAnAssignedTeam) {
        return [
          { id: 0, name: this.$t('TEAMS_SETTINGS.LIST.NONE') },
          ...this.teams,
        ];
      }
      return this.teams;
    },
    assignedAgent: {
      get() {
        return this.currentChat.meta.assignee;
      },
      set(agent) {
        const agentId = agent ? agent.id : null;
        this.$store.dispatch('setCurrentChatAssignee', {
          conversationId: this.currentChat.id,
          assignee: agent,
        });
        this.$store
          .dispatch('assignAgent', {
            conversationId: this.currentChat.id,
            agentId,
          })
          .then(() => {
            useAlert(this.$t('CONVERSATION.CHANGE_AGENT'));
          });
      },
    },
    assignedTeam: {
      get() {
        return this.currentChat.meta.team;
      },
      set(team) {
        const conversationId = this.currentChat.id;
        const teamId = team ? team.id : 0;
        this.$store.dispatch('setCurrentChatTeam', { team, conversationId });
        this.$store
          .dispatch('assignTeam', { conversationId, teamId })
          .then(() => {
            useAlert(this.$t('CONVERSATION.CHANGE_TEAM'));
          });
      },
    },
    assignedPriority: {
      get() {
        const selectedOption = this.priorityOptions.find(
          opt => opt.id === this.currentChat.priority
        );

        return selectedOption || this.priorityOptions[0];
      },
      set(priorityItem) {
        const conversationId = this.currentChat.id;
        const oldValue = this.currentChat?.priority;
        const priority = priorityItem ? priorityItem.id : null;

        this.$store.dispatch('setCurrentChatPriority', {
          priority,
          conversationId,
        });
        this.$store
          .dispatch('assignPriority', { conversationId, priority })
          .then(() => {
            useTrack(CONVERSATION_EVENTS.CHANGE_PRIORITY, {
              oldValue,
              newValue: priority,
              from: 'Conversation Sidebar',
            });
            useAlert(
              this.$t('CONVERSATION.PRIORITY.CHANGE_PRIORITY.SUCCESSFUL', {
                priority: priorityItem.name,
                conversationId,
              })
            );
          });
      },
    },
    showSelfAssign() {
      if (!this.assignedAgent) {
        return true;
      }
      if (this.assignedAgent.id !== this.currentUser.id) {
        return true;
      }
      return false;
    },
  },
  methods: {
    onSelfAssign() {
      const {
        account_id,
        availability_status,
        available_name,
        email,
        id,
        name,
        role,
        avatar_url,
      } = this.currentUser;
      const selfAssign = {
        account_id,
        availability_status,
        available_name,
        email,
        id,
        name,
        role,
        thumbnail: avatar_url,
      };
      this.assignedAgent = selfAssign;
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

    onClickAssignPriority(selectedPriorityItem) {
      const isSamePriority =
        this.assignedPriority &&
        this.assignedPriority.id === selectedPriorityItem.id;

      this.assignedPriority = isSamePriority ? null : selectedPriorityItem;
    },

    async createHandoffNote({ actionLabel }) {
      const assignee =
        this.assignedAgent?.name ||
        this.$t('CONVERSATION_SIDEBAR.TRANSFER.NO_AGENT');
      const team =
        this.assignedTeam?.name ||
        this.$t('CONVERSATION_SIDEBAR.TRANSFER.NO_TEAM');
      const note = this.$t('CONVERSATION_SIDEBAR.TRANSFER.HANDOFF_NOTE', {
        action: actionLabel,
        reason: this.transferReason,
        priority: this.transferPriority,
        assignee,
        team,
      });

      try {
        await this.$store.dispatch('createPendingMessageAndSend', {
          conversationId: this.currentChat.id,
          message: note,
          private: true,
        });
      } catch (_error) {
        // noop in happy-path MVP
      }
    },
    async executeTransferAction() {
      if (!this.transferReason) {
        useAlert(this.$t('CONVERSATION_SIDEBAR.TRANSFER.REASON_REQUIRED'));
        return;
      }

      if (this.transferAction === 'assign_self') {
        this.onSelfAssign();
      } else if (this.transferAction === 'assign_agent') {
        if (!this.assignedAgent) {
          useAlert(this.$t('CONVERSATION_SIDEBAR.TRANSFER.AGENT_REQUIRED'));
          return;
        }
      } else if (this.transferAction === 'assign_team') {
        if (!this.assignedTeam) {
          useAlert(this.$t('CONVERSATION_SIDEBAR.TRANSFER.TEAM_REQUIRED'));
          return;
        }
      } else if (this.transferAction === 'queue_team') {
        this.assignedAgent = null;
      }

      await this.createHandoffNote({
        actionLabel:
          this.transferActionOptions.find(
            action => action.id === this.transferAction
          )?.name || this.transferAction,
      });

      useAlert(this.$t('CONVERSATION_SIDEBAR.TRANSFER.SUCCESS'));
      this.transferReason = '';
    },
  },
};
</script>

<template>
  <div>
    <div>
      <ContactDetailsItem
        compact
        :title="$t('CONVERSATION_SIDEBAR.ASSIGNEE_LABEL')"
      >
        <template #button>
          <NextButton
            v-if="showSelfAssign"
            link
            xs
            icon="i-lucide-arrow-right"
            class="!gap-1"
            :label="$t('CONVERSATION_SIDEBAR.SELF_ASSIGN')"
            @click="onSelfAssign"
          />
        </template>
      </ContactDetailsItem>
      <MultiselectDropdown
        :options="agentsList"
        :selected-item="assignedAgent"
        :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.AGENT')"
        :multiselector-placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
        :no-search-result="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.AGENT')
        "
        :input-placeholder="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
        "
        @select="onClickAssignAgent"
      />
    </div>
    <div>
      <ContactDetailsItem
        compact
        :title="$t('CONVERSATION_SIDEBAR.TEAM_LABEL')"
      />
      <MultiselectDropdown
        :options="teamsList"
        :selected-item="assignedTeam"
        :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.TEAM')"
        :multiselector-placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
        :no-search-result="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.TEAM')
        "
        :input-placeholder="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.TEAM')
        "
        @select="onClickAssignTeam"
      />
    </div>
    <div>
      <ContactDetailsItem compact :title="$t('CONVERSATION.PRIORITY.TITLE')" />
      <MultiselectDropdown
        :options="priorityOptions"
        :selected-item="assignedPriority"
        :multiselector-title="$t('CONVERSATION.PRIORITY.TITLE')"
        :multiselector-placeholder="
          $t('CONVERSATION.PRIORITY.CHANGE_PRIORITY.SELECT_PLACEHOLDER')
        "
        :no-search-result="
          $t('CONVERSATION.PRIORITY.CHANGE_PRIORITY.NO_RESULTS')
        "
        :input-placeholder="
          $t('CONVERSATION.PRIORITY.CHANGE_PRIORITY.INPUT_PLACEHOLDER')
        "
        @select="onClickAssignPriority"
      />
    </div>

    <div class="rounded-lg border border-n-weak p-3 mt-3">
      <ContactDetailsItem
        compact
        :title="$t('CONVERSATION_SIDEBAR.TRANSFER.TITLE')"
      />
      <MultiselectDropdown
        :options="transferActionOptions"
        :selected-item="
          transferActionOptions.find(item => item.id === transferAction)
        "
        :multiselector-title="$t('CONVERSATION_SIDEBAR.TRANSFER.ACTION_LABEL')"
        :multiselector-placeholder="
          $t('CONVERSATION_SIDEBAR.TRANSFER.ACTION_LABEL')
        "
        :no-search-result="$t('CONVERSATION_SIDEBAR.TRANSFER.NO_ACTION')"
        :input-placeholder="$t('CONVERSATION_SIDEBAR.TRANSFER.ACTION_LABEL')"
        @select="item => (transferAction = item.id)"
      />
      <MultiselectDropdown
        :options="transferPriorityOptions"
        :selected-item="
          transferPriorityOptions.find(item => item.id === transferPriority)
        "
        :multiselector-title="
          $t('CONVERSATION_SIDEBAR.TRANSFER.PRIORITY_LABEL')
        "
        :multiselector-placeholder="
          $t('CONVERSATION_SIDEBAR.TRANSFER.PRIORITY_LABEL')
        "
        :no-search-result="$t('CONVERSATION_SIDEBAR.TRANSFER.NO_ACTION')"
        :input-placeholder="$t('CONVERSATION_SIDEBAR.TRANSFER.PRIORITY_LABEL')"
        @select="item => (transferPriority = item.id)"
      />
      <textarea
        v-model="transferReason"
        class="w-full mt-2 rounded-md border border-n-weak bg-n-solid-1 px-3 py-2 text-sm text-n-slate-12"
        rows="3"
        :placeholder="$t('CONVERSATION_SIDEBAR.TRANSFER.REASON_PLACEHOLDER')"
      />
      <NextButton
        class="mt-2"
        size="sm"
        :label="$t('CONVERSATION_SIDEBAR.TRANSFER.EXECUTE')"
        @click="executeTransferAction"
      />
    </div>
    <ContactDetailsItem
      compact
      :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_LABELS')"
    />
    <ConversationLabels :conversation-id="conversationId" />
  </div>
</template>
