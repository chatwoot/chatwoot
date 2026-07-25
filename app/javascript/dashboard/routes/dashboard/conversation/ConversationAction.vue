<!-- eslint-disable vue/v-slot-style -->
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import OutlinedAttributeField from 'dashboard/components-next/CustomAttributes/OutlinedAttributeField.vue';
import OutlinedSelectField from 'dashboard/components-next/CustomAttributes/OutlinedSelectField.vue';
import ConversationLabels from './labels/LabelBox.vue';
import { CONVERSATION_PRIORITY } from '../../../../shared/constants/messages';
import { CONVERSATION_EVENTS } from '../../../helper/AnalyticsHelper/events';
import { useTrack } from 'dashboard/composables';
import { useConversationAssignee } from 'dashboard/composables/useConversationAssignee';
import { onMounted, watch } from 'vue';
import { useStore } from 'vuex';

export default {
  components: {
    OutlinedAttributeField,
    OutlinedSelectField,
    ConversationLabels,
  },
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  setup() {
    const store = useStore();
    const { agentsList, assignedAgent, isAssigning, onClickAssignAgent } =
      useConversationAssignee();

    const fetchAssignableAgents = () => {
      const inboxId = store.getters.getSelectedChat?.inbox_id;
      if (inboxId) {
        store.dispatch('inboxAssignableAgents/fetch', [inboxId]);
      }
    };

    onMounted(fetchAssignableAgents);
    watch(
      () => store.getters.getSelectedChat?.inbox_id,
      () => fetchAssignableAgents()
    );

    return {
      agentsList,
      assignedAgent,
      isAssigning,
      onClickAssignAgent,
    };
  },
  data() {
    return {
      priorityOptions: [
        {
          id: null,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.NONE'),
          icon: 'i-woot-priority-empty',
        },
        {
          id: CONVERSATION_PRIORITY.URGENT,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.URGENT'),
          icon: 'i-woot-priority-urgent',
        },
        {
          id: CONVERSATION_PRIORITY.HIGH,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.HIGH'),
          icon: 'i-woot-priority-high',
        },
        {
          id: CONVERSATION_PRIORITY.MEDIUM,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.MEDIUM'),
          icon: 'i-woot-priority-medium',
        },
        {
          id: CONVERSATION_PRIORITY.LOW,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.LOW'),
          icon: 'i-woot-priority-low',
        },
      ],
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
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
        const priority = priorityItem.id;

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
  },
  methods: {
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

      this.assignedPriority = isSamePriority
        ? this.priorityOptions[0]
        : selectedPriorityItem;
    },
  },
};
</script>

<template>
  <div class="flex flex-col gap-1.5 px-1 py-0.5">
    <OutlinedSelectField
      :label="$t('CONVERSATION_SIDEBAR.ASSIGNEE_LABEL')"
      :options="agentsList"
      :selected-item="assignedAgent"
      :placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
      :disabled="isAssigning"
      has-thumbnail
      @select="onClickAssignAgent"
    />

    <OutlinedSelectField
      :label="$t('CONVERSATION_SIDEBAR.TEAM_LABEL')"
      :options="teamsList"
      :selected-item="assignedTeam"
      :placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
      @select="onClickAssignTeam"
    />

    <OutlinedSelectField
      :label="$t('CONVERSATION.PRIORITY.TITLE')"
      :options="priorityOptions"
      :selected-item="assignedPriority"
      :placeholder="
        $t('CONVERSATION.PRIORITY.CHANGE_PRIORITY.SELECT_PLACEHOLDER')
      "
      :show-search="false"
      @select="onClickAssignPriority"
    />

    <OutlinedAttributeField
      :label="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_LABELS')"
      filled
      tall
    >
      <ConversationLabels :conversation-id="conversationId" />
    </OutlinedAttributeField>
  </div>
</template>
