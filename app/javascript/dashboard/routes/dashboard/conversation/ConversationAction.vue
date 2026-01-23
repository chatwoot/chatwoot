<!-- eslint-disable vue/v-slot-style -->
<template>
  <div class="bg-white dark:bg-slate-900">
    <!-- Show restriction notice for Ugoo account agents -->
    <div
      v-if="canViewAssignedAgent && showAssignmentRestriction"
      class="p-3 bg-yellow-50 border-l-4 border-yellow-400 mb-4"
    >
      <div class="flex">
        <div class="flex-shrink-0">
          <svg
            class="h-5 w-5 text-yellow-400"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path
              fill-rule="evenodd"
              d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
              clip-rule="evenodd"
            />
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm text-yellow-700">
            {{ $t('You can only assign conversations to yourself') }}
          </p>
        </div>
      </div>
    </div>

    <div v-if="canViewAssignedAgent" class="multiselect-wrap--small">
      <contact-details-item
        compact
        :title="$t('CONVERSATION_SIDEBAR.ASSIGNEE_LABEL')"
      >
        <template v-slot:button>
          <woot-button
            v-if="showSelfAssign"
            icon="arrow-right"
            variant="link"
            size="small"
            @click="onSelfAssign"
          >
            {{ $t('CONVERSATION_SIDEBAR.SELF_ASSIGN') }}
          </woot-button>
        </template>
      </contact-details-item>
      <multiselect-dropdown
        :options="filteredAgentsList"
        :selected-item="assignedAgent"
        :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.AGENT')"
        :multiselector-placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
        :no-search-result="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.AGENT')
        "
        :input-placeholder="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
        "
        @click="onClickAssignAgent"
      />
    </div>
    <div class="multiselect-wrap--small">
      <contact-details-item
        compact
        :title="$t('CONVERSATION_SIDEBAR.TEAM_LABEL')"
      />
      <multiselect-dropdown
        :options="teamsList"
        :selected-item="assignedTeam"
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
    <div class="multiselect-wrap--small">
      <contact-details-item
        compact
        :title="$t('CONVERSATION.PRIORITY.TITLE')"
      />
      <multiselect-dropdown
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
        @click="onClickAssignPriority"
      />
    </div>
    <contact-details-item
      compact
      :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_LABELS')"
    />
    <conversation-labels :conversation-id="conversationId" />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import ContactDetailsItem from './ContactDetailsItem.vue';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import ConversationLabels from './labels/LabelBox.vue';
import agentMixin from 'dashboard/mixins/agentMixin';
import teamMixin from 'dashboard/mixins/conversation/teamMixin';
import { CONVERSATION_PRIORITY } from '../../../../shared/constants/messages';
import { CONVERSATION_EVENTS } from '../../../helper/AnalyticsHelper/events';
import { conversationListPageURL } from '../../../helper/URLHelper';

export default {
  components: {
    ContactDetailsItem,
    MultiselectDropdown,
    ConversationLabels,
  },
  mixins: [agentMixin, alertMixin, teamMixin],
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
    inboxId: {
      type: Number,
      default: undefined,
    },
  },
  data() {
    return {
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
      getAccount: 'accounts/getAccount',
    }),
    assignedAgent: {
      get() {
        return this.currentChat.meta.assignee;
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
    currentAccount() {
      return this.getAccount(this.currentAccountId) || {};
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
            this.showAlert(this.$t('CONVERSATION.CHANGE_TEAM'));
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
            this.$track(CONVERSATION_EVENTS.CHANGE_PRIORITY, {
              oldValue,
              newValue: priority,
              from: 'Conversation Sidebar',
            });
            this.showAlert(
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
    showAssignmentRestriction() {
      return (
        this.currentUser.role !== 'administrator' &&
        this.currentAccount?.custom_attributes?.restrict_agent_assignment
      );
    },
    filteredAgentsList() {
      if (this.currentUser.role === 'administrator') {
        return this.agentsList;
      }
      if (this.currentAccount?.custom_attributes?.restrict_agent_assignment) {
        return this.agentsList.filter(
          agent => agent.id === this.currentUser.id
        );
      }

      return this.agentsList;
    },
    canAssignToOthers() {
      return (
        this.currentUser.role === 'administrator' ||
        !this.currentAccount?.custom_attributes?.restrict_agent_assignment
      );
    },
    canViewAssignedAgent() {
      // Check if current user is in the assignable agents list
      // (which only includes assignment_eligible members)
      const assignableAgents = this.assignableAgents || [];
      return assignableAgents.some(agent => agent.id === this.currentUser.id);
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
    async markAsUnread(conversationId, shouldRoute = true) {
      try {
        await this.$store.dispatch('markMessagesUnread', {
          id: conversationId,
        });
        if (shouldRoute) {
          const {
            params: { accountId, inbox_id: inboxId, label, teamId },
          } = this.$route;
          const isFolderView = window.location.pathname.includes('custom_view');
          const customViewId = isFolderView
            ? window.location.pathname
                .split('/')
                .find(
                  (segment, index, array) =>
                    array[index - 1] === 'custom_view' && !Number.isNaN(segment)
                )
            : null;
          this.$router.push(
            conversationListPageURL({
              accountId,
              customViewId,
              inboxId,
              label,
              teamId,
            })
          );
        }
      } catch (error) {
        // Ignore error
      }
    },
    onClickAssignAgent(selectedItem) {
      // Prevent assignment to other agents for Ugoo account agents
      if (!this.canAssignToOthers && selectedItem.id !== this.currentUser.id) {
        this.showAlert(this.$t('CONVERSATION.ASSIGNMENT_RESTRICTED'));
        return;
      }

      if (this.assignedAgent && this.assignedAgent.id === selectedItem.id) {
        this.assignedAgent = null;
      } else {
        this.assignedAgent = selectedItem;
      }
      // TODO: mark conversation as unread
      this.markAsUnread(
        this.currentChat.id,
        selectedItem.id !== this.currentUser.id
      );
    },

    onClickAssignTeam(selectedItemTeam) {
      if (this.assignedTeam && this.assignedTeam.id === selectedItemTeam.id) {
        this.assignedTeam = null;
      } else {
        this.assignedTeam = selectedItemTeam;
      }
      // TODO: mark conversation as unread
      this.markAsUnread(this.currentChat.id);
    },

    onClickAssignPriority(selectedPriorityItem) {
      const isSamePriority =
        this.assignedPriority &&
        this.assignedPriority.id === selectedPriorityItem.id;

      this.assignedPriority = isSamePriority ? null : selectedPriorityItem;
    },
  },
};
</script>
