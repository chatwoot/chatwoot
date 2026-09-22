<!-- eslint-disable vue/v-slot-style -->
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { computed, reactive, ref, watch } from 'vue';
import { useTimeoutFn } from '@vueuse/core';
import { useAgentsList } from 'dashboard/composables/useAgentsList';
import { useConversationLabels } from 'dashboard/composables/useConversationLabels';
import { useConversationSuggestions } from 'dashboard/composables/useConversationSuggestions';
import { useStoreGetters } from 'dashboard/composables/store';
import ContactDetailsItem from './ContactDetailsItem.vue';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import ConversationLabels from './labels/LabelBox.vue';
import SuggestionSkeleton from 'dashboard/components-next/captain/classifier/SuggestionSkeleton.vue';
import SuggestButton from 'dashboard/components-next/captain/classifier/SuggestButton.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
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
    SuggestionSkeleton,
    SuggestButton,
    Icon,
  },
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  setup() {
    const { agentsList } = useAgentsList(true, {
      includeAIAssignees: true,
    });
    const getters = useStoreGetters();
    const conversation = computed(() => getters.getSelectedChat.value);
    const { accountLabels, savedLabels, onUpdateLabels } =
      useConversationLabels();

    const prioritySuggestion = reactive(
      useConversationSuggestions('priority', conversation)
    );
    const labelSuggestion = reactive(
      useConversationSuggestions('labels', conversation)
    );
    const rejectedLabels = ref([]);

    const suggestedLabels = computed(() => {
      const titles = (labelSuggestion.suggestions?.labels || []).map(
        ({ title }) => title
      );
      return accountLabels.value.filter(
        ({ title }) =>
          titles.includes(title) &&
          !savedLabels.value.includes(title) &&
          !rejectedLabels.value.includes(title)
      );
    });

    const EMPTY_NOTE_DURATION = 2500;
    const { start: hideEmptyNote, stop: cancelHideEmptyNote } = useTimeoutFn(
      () => labelSuggestion.dismiss(),
      EMPTY_NOTE_DURATION,
      { immediate: false }
    );

    // Nothing left to show: close right away when the user handled every
    // suggestion, or after a short "no new suggestions" note otherwise.
    watch(
      () => [
        labelSuggestion.isActive,
        labelSuggestion.isLoading,
        suggestedLabels.value.length,
      ],
      ([isActive, isLoading, remaining], [, , previous]) => {
        cancelHideEmptyNote();
        if (!isActive || isLoading || remaining) return;

        if (previous) labelSuggestion.dismiss();
        else hideEmptyNote();
      }
    );

    const suggestLabels = () => {
      rejectedLabels.value = [];
      labelSuggestion.toggleSuggestions();
    };

    const acceptSuggestedLabels = labels => {
      onUpdateLabels([
        ...savedLabels.value,
        ...labels.map(({ title }) => title),
      ]);
    };

    return {
      agentsList,
      isSuggestionsEnabled: labelSuggestion.isEnabled,
      prioritySuggestion,
      labelSuggestion,
      suggestedLabels,
      rejectedLabels,
      suggestLabels,
      acceptSuggestedLabels,
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
        const assignee = this.currentChat.meta.assignee;
        return (
          assignee && {
            ...assignee,
            assignee_type: this.currentChat.meta.assignee_type || 'User',
          }
        );
      },
      set(agent) {
        const agentId = agent ? agent.id : null;
        const assigneeType = agent ? agent.assignee_type || 'User' : null;
        this.$store.dispatch('setCurrentChatAssignee', {
          conversationId: this.currentChat.id,
          assignee: agent,
          assigneeType,
        });
        this.$store
          .dispatch('assignAgent', {
            conversationId: this.currentChat.id,
            agentId,
            assigneeType,
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
    suggestedPriority() {
      const priority = this.prioritySuggestion.suggestions?.priority;
      if (priority === this.currentChat.priority) return undefined;
      return this.priorityOptions.find(opt => opt.id === priority);
    },
    showSelfAssign() {
      if (!this.assignedAgent) {
        return true;
      }
      if (
        this.assignedAgent.id !== this.currentUser.id ||
        (this.assignedAgent.assignee_type || 'User') !== 'User'
      ) {
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
      if (
        this.assignedAgent?.id === selectedItem.id &&
        (this.assignedAgent?.assignee_type || 'User') ===
          (selectedItem.assignee_type || 'User')
      ) {
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

    acceptSuggestedPriority() {
      this.assignedPriority = this.suggestedPriority;
      this.prioritySuggestion.dismiss();
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
        show-emoji-icon
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
      <ContactDetailsItem compact :title="$t('CONVERSATION.PRIORITY.TITLE')">
        <template #button>
          <SuggestButton
            v-if="isSuggestionsEnabled"
            :is-active="prioritySuggestion.isActive"
            :is-loading="prioritySuggestion.isLoading"
            @click="prioritySuggestion.toggleSuggestions()"
          />
        </template>
      </ContactDetailsItem>
      <Transition
        mode="out-in"
        enter-active-class="transition duration-200 ease-out"
        enter-from-class="opacity-0 scale-[0.98]"
        leave-active-class="transition duration-150 ease-in"
        leave-to-class="opacity-0 scale-[0.98]"
      >
        <SuggestionSkeleton
          v-if="prioritySuggestion.isLoading"
          class="w-full h-10 mb-2 rounded-lg"
        />
        <NextButton
          v-else-if="prioritySuggestion.isActive && suggestedPriority"
          v-tooltip.top="$t('CONVERSATION.SUGGESTIONS.APPLY_HINT')"
          slate
          outline
          class="relative w-full mb-2 overflow-hidden !px-2 !outline-n-iris-6 bg-n-iris-2 hover:enabled:!bg-n-iris-3 group before:absolute before:inset-0 before:bg-gradient-to-r before:from-transparent before:via-white/50 dark:before:via-white/5 before:to-transparent before:animate-shimmer before:pointer-events-none"
          @click="acceptSuggestedPriority"
        >
          <div class="flex items-center w-full min-w-0 gap-2 text-sm">
            <Icon
              icon="i-ph-sparkle-fill"
              class="flex-shrink-0 text-n-iris-9"
            />
            <template v-if="assignedPriority.id">
              <span class="inline-flex items-center gap-1.5 text-n-slate-10">
                <Icon :icon="assignedPriority.icon" class="opacity-60" />
                <span class="line-through decoration-n-slate-9">
                  {{ assignedPriority.name }}
                </span>
              </span>
              <Icon
                icon="i-lucide-arrow-right"
                class="flex-shrink-0 text-n-iris-9 transition-transform group-hover:translate-x-0.5"
              />
            </template>
            <span
              class="inline-flex items-center gap-1.5 font-semibold !text-n-slate-12"
            >
              <Icon :icon="suggestedPriority.icon" />
              {{ suggestedPriority.name }}
            </span>
          </div>
          <span
            v-tooltip.top="$t('CONVERSATION.SUGGESTIONS.REJECT')"
            role="button"
            class="flex items-center justify-center flex-shrink-0 text-sm transition-all rounded-md opacity-0 size-6 text-n-slate-11 group-hover:opacity-100 focus-visible:opacity-100 hover:bg-n-iris-4 hover:text-n-slate-12"
            @click.stop="prioritySuggestion.dismiss()"
          >
            <Icon icon="i-lucide-x" />
          </span>
        </NextButton>
        <MultiselectDropdown
          v-else
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
      </Transition>
      <span
        v-if="
          prioritySuggestion.isActive &&
          !prioritySuggestion.isLoading &&
          !suggestedPriority
        "
        class="inline-flex items-center gap-1 mb-2 -mt-1 text-xs text-n-slate-11 animate-fade-in-up"
      >
        <Icon icon="i-ph-sparkle-fill" class="text-n-iris-9" />
        {{ $t('CONVERSATION.SUGGESTIONS.EMPTY') }}
      </span>
    </div>
    <ContactDetailsItem
      compact
      :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_LABELS')"
    >
      <template #button>
        <SuggestButton
          v-if="isSuggestionsEnabled"
          :is-active="labelSuggestion.isActive"
          :is-loading="labelSuggestion.isLoading"
          @click="suggestLabels"
        />
      </template>
    </ContactDetailsItem>
    <ConversationLabels
      :conversation-id="conversationId"
      :suggested-labels="suggestedLabels"
      :is-suggestion-active="labelSuggestion.isActive"
      :is-suggesting="labelSuggestion.isLoading"
      @accept-suggestion="acceptSuggestedLabels([$event])"
      @reject-suggestion="rejectedLabels.push($event.title)"
      @accept-all-suggestions="acceptSuggestedLabels(suggestedLabels)"
    />
  </div>
</template>
