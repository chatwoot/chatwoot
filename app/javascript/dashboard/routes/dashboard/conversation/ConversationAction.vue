<!-- eslint-disable vue/v-slot-style -->
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useAgentsList } from 'dashboard/composables/useAgentsList';
import ContactDetailsItem from './ContactDetailsItem.vue';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import ConversationLabels from './labels/LabelBox.vue';
import LabelItem from 'dashboard/components-next/label/LabelItem.vue';
import { CONVERSATION_PRIORITY } from '../../../../shared/constants/messages';
import { CONVERSATION_EVENTS } from '../../../helper/AnalyticsHelper/events';
import { useTrack } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import CrmKanbanAPI from 'dashboard/api/crmKanban';
import CrmConversationStageBadge from './CrmConversationStageBadge.vue';
import CrmCopilotPanel from 'dashboard/routes/dashboard/crm/components/CrmCopilotPanel.vue';
import { useCrmPermissions } from 'dashboard/routes/dashboard/crm/composables/useCrmPermissions';

export default {
  components: {
    ContactDetailsItem,
    MultiselectDropdown,
    ConversationLabels,
    LabelItem,
    NextButton,
    CrmConversationStageBadge,
    CrmCopilotPanel,
  },
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  setup() {
    const { agentsList } = useAgentsList();
    const { canViewCrm } = useCrmPermissions();
    return {
      agentsList,
      canViewCrm,
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
      crmPipelineId: '',
      crmStageId: '',
      crmStages: [],
      crmIsLoadingPipelines: false,
      crmIsLoadingStages: false,
      crmIsCreatingCard: false,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      currentUser: 'getCurrentUser',
      teams: 'teams/getTeams',
      globalConfig: 'globalConfig/get',
      crmPipelines: 'crmKanban/getPipelines',
      allLabels: 'labels/getLabels',
      contactLabelTitlesFor: 'contactLabels/getContactLabels',
    }),
    contactId() {
      return this.currentChat?.meta?.sender?.id;
    },
    // Campaign import labels live only on the Contact (never synced onto the
    // conversation, see CampaignImports::Importer#apply_labels!) — read-only
    // here, editing stays on the Contact profile's own label manager.
    contactLabelItems() {
      if (!this.contactId) return [];
      const titles = this.contactLabelTitlesFor(this.contactId) || [];
      return this.allLabels.filter(({ title }) => titles.includes(title));
    },
    crmKanbanEnabled() {
      return (
        this.globalConfig?.crmKanbanEnabled === true ||
        window.globalConfig?.CRM_KANBAN_ENABLED === 'true'
      );
    },
    crmPipelineOptions() {
      return this.crmPipelines.map(pipeline => ({
        value: pipeline.id,
        label: pipeline.name,
      }));
    },
    crmStageOptions() {
      return this.crmStages.map(stage => ({
        value: stage.id,
        label: stage.name,
      }));
    },
    canCreateCrmCard() {
      return (
        this.crmKanbanEnabled &&
        this.currentChat?.id &&
        this.crmPipelineId &&
        this.crmStageId &&
        !this.crmIsCreatingCard &&
        !this.crmIsLoadingPipelines &&
        !this.crmIsLoadingStages
      );
    },
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
  watch: {
    crmKanbanEnabled: {
      immediate: true,
      handler(enabled) {
        if (enabled) this.loadCrmPipelines();
      },
    },
    crmPipelineId(newPipelineId) {
      if (newPipelineId) this.loadCrmStages(newPipelineId);
    },
    contactId: {
      immediate: true,
      handler(newContactId) {
        if (!newContactId) return;
        if (this.contactLabelTitlesFor(newContactId)?.length) return;
        this.$store.dispatch('contactLabels/get', newContactId);
      },
    },
  },
  methods: {
    async loadCrmPipelines() {
      if (!this.crmKanbanEnabled || this.crmIsLoadingPipelines) return;
      this.crmIsLoadingPipelines = true;
      try {
        const pipelines = await this.$store.dispatch(
          'crmKanban/fetchPipelines'
        );
        if (!this.crmPipelineId && pipelines.length) {
          this.crmPipelineId = pipelines[0].id;
        }
      } catch {
        useAlert(this.$t('CRM_KANBAN.CONVERSATION.LOAD_ERROR'));
      } finally {
        this.crmIsLoadingPipelines = false;
      }
    },
    async loadCrmStages(pipelineId) {
      this.crmIsLoadingStages = true;
      try {
        const response = await CrmKanbanAPI.getStages(pipelineId);
        this.crmStages = response.data.payload || [];
        const stillAvailable = this.crmStages.some(
          stage => String(stage.id) === String(this.crmStageId)
        );
        if (!stillAvailable) {
          this.crmStageId = this.crmStages[0]?.id || '';
        }
      } catch {
        this.crmStages = [];
        this.crmStageId = '';
        useAlert(this.$t('CRM_KANBAN.CONVERSATION.LOAD_ERROR'));
      } finally {
        this.crmIsLoadingStages = false;
      }
    },
    async createCrmCardFromConversation() {
      if (!this.canCreateCrmCard) return;
      this.crmIsCreatingCard = true;
      try {
        await this.$store.dispatch('crmKanban/createCardFromConversation', {
          conversation_display_id: this.currentChat.id,
          pipeline_id: this.crmPipelineId,
          stage_id: this.crmStageId,
        });
        useAlert(this.$t('CRM_KANBAN.CONVERSATION.CARD_READY'));
      } catch {
        useAlert(this.$t('CRM_KANBAN.CONVERSATION.CREATE_ERROR'));
      } finally {
        this.crmIsCreatingCard = false;
      }
    },
    openCrmKanban() {
      this.$router.push({
        name: 'crm_kanban_index',
        params: { accountId: this.currentChat.account_id },
      });
    },
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

      this.assignedPriority = isSamePriority
        ? this.priorityOptions[0]
        : selectedPriorityItem;
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
    <CrmCopilotPanel
      v-if="crmKanbanEnabled && currentChat && currentChat.id"
      :conversation-id="currentChat.id"
    />
    <section
      v-if="crmKanbanEnabled"
      class="my-3 rounded-lg border border-n-weak bg-n-alpha-black2 p-3"
    >
      <div class="mb-3 flex items-start justify-between gap-3">
        <div class="min-w-0">
          <p class="mb-1 text-sm font-medium text-n-slate-12">
            {{ $t('CRM_KANBAN.CONVERSATION.TITLE') }}
          </p>
          <p class="mb-0 text-xs leading-5 text-n-slate-11">
            {{ $t('CRM_KANBAN.CONVERSATION.DESCRIPTION') }}
          </p>
        </div>
        <NextButton
          icon="i-lucide-kanban"
          xs
          slate
          ghost
          :title="$t('CRM_KANBAN.CONVERSATION.OPEN_CRM')"
          @click="openCrmKanban"
        />
      </div>

      <div v-if="canViewCrm && conversationId" class="mb-3">
        <span class="mb-1 block text-xs font-medium text-n-slate-11">
          {{ $t('CRM_KANBAN.CONVERSATION.STAGE_BADGE_LABEL') }}
        </span>
        <CrmConversationStageBadge :conversation-id="conversationId" />
      </div>

      <div v-if="crmPipelineOptions.length" class="grid gap-2">
        <label class="grid gap-1">
          <span class="text-xs font-medium text-n-slate-11">
            {{ $t('CRM_KANBAN.CONVERSATION.PIPELINE') }}
          </span>
          <select
            v-model="crmPipelineId"
            class="reset-base !mb-0 h-9 w-full rounded-lg border-0 bg-n-alpha-black2 px-2.5 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
          >
            <option
              v-for="pipeline in crmPipelineOptions"
              :key="pipeline.value"
              :value="pipeline.value"
            >
              {{ pipeline.label }}
            </option>
          </select>
        </label>

        <label class="grid gap-1">
          <span class="text-xs font-medium text-n-slate-11">
            {{ $t('CRM_KANBAN.CONVERSATION.STAGE') }}
          </span>
          <select
            v-model="crmStageId"
            class="reset-base !mb-0 h-9 w-full rounded-lg border-0 bg-n-alpha-black2 px-2.5 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
            :disabled="crmIsLoadingStages"
          >
            <option
              v-for="stage in crmStageOptions"
              :key="stage.value"
              :value="stage.value"
            >
              {{ stage.label }}
            </option>
          </select>
        </label>

        <NextButton
          :label="$t('CRM_KANBAN.CONVERSATION.CREATE_CARD')"
          icon="i-lucide-plus"
          sm
          class="w-full justify-center"
          :disabled="!canCreateCrmCard"
          :is-loading="crmIsCreatingCard"
          @click="createCrmCardFromConversation"
        />
      </div>
      <p v-else class="mb-0 text-xs leading-5 text-n-slate-11">
        {{ $t('CRM_KANBAN.CONVERSATION.NO_PIPELINES') }}
      </p>
    </section>
    <ContactDetailsItem
      compact
      :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_LABELS')"
    />
    <ConversationLabels :conversation-id="conversationId" />
    <div v-if="contactLabelItems.length" class="mt-3">
      <ContactDetailsItem
        compact
        :title="$t('CRM_KANBAN.CONVERSATION.CONTACT_LABELS_TITLE')"
      />
      <div class="flex flex-wrap items-center gap-2">
        <LabelItem
          v-for="label in contactLabelItems"
          :key="label.id"
          :label="label"
        />
      </div>
    </div>
  </div>
</template>
