<template>
  <div>
    <settings-section
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS_SUB_TEXT')"
    >
      <multiselect
        v-model="selectedAgents"
        :options="agentList"
        track-by="id"
        label="name"
        :multiple="true"
        :close-on-select="false"
        :clear-on-select="false"
        :hide-selected="true"
        placeholder="Pick some"
        selected-label
        :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
        :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
        @select="$v.selectedAgents.$touch"
      />

      <woot-submit-button
        :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
        :loading="isAgentListUpdating"
        @click="updateAgents"
      />
    </settings-section>

    <settings-section
      v-if="savedAgents.length > 0"
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.ASSIGNMENT_ELIGIBILITY.TITLE')"
      :sub-title="
        $t('INBOX_MGMT.SETTINGS_POPUP.ASSIGNMENT_ELIGIBILITY.SUB_TEXT')
      "
    >
      <div class="agent-eligibility-list">
        <div
          v-for="agent in savedAgents"
          :key="agent.id"
          class="agent-eligibility-item"
        >
          <div class="agent-info">
            <thumbnail
              :src="agent.thumbnail"
              :username="agent.name"
              size="32px"
            />
            <div class="agent-details">
              <span class="agent-name">{{ agent.name }}</span>
              <span class="agent-email">{{ agent.email }}</span>
            </div>
          </div>
          <div class="eligibility-controls">
            <span
              class="agent-status-badge"
              :class="{
                'agent-status-badge--eligible':
                  agent.assignment_eligible !== false,
                'agent-status-badge--view-only':
                  agent.assignment_eligible === false,
              }"
            >
              {{
                agent.assignment_eligible !== false
                  ? $t(
                      'INBOX_MGMT.SETTINGS_POPUP.ASSIGNMENT_ELIGIBILITY.BADGE_ASSIGNABLE'
                    )
                  : $t(
                      'INBOX_MGMT.SETTINGS_POPUP.ASSIGNMENT_ELIGIBILITY.BADGE_VIEW_ONLY'
                    )
              }}
            </span>
            <label class="toggle-switch">
              <input
                type="checkbox"
                :checked="agent.assignment_eligible !== false"
                :disabled="eligibilityUpdating[agent.id]"
                @change="
                  handleAssignmentEligibilityChange(
                    agent,
                    $event.target.checked
                  )
                "
              />
              <span class="toggle-slider" />
            </label>
          </div>
        </div>
      </div>
    </settings-section>

    <settings-section
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.AGENT_ASSIGNMENT')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.AGENT_ASSIGNMENT_SUB_TEXT')"
    >
      <label class="w-3/4 settings-item">
        <div class="flex items-center gap-2">
          <input
            id="enableAutoAssignment"
            v-model="enableAutoAssignment"
            type="checkbox"
            @change="handleEnableAutoAssignment"
          />
          <label for="enableAutoAssignment">
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.AUTO_ASSIGNMENT') }}
          </label>
        </div>

        <p class="pb-1 text-sm not-italic text-slate-600 dark:text-slate-400">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.AUTO_ASSIGNMENT_SUB_TEXT') }}
        </p>
      </label>

      <label class="w-3/4 settings-item">
        <div class="flex items-center gap-2">
          <input
            id="assignEvenIfOffline"
            v-model="assignEvenIfOffline"
            type="checkbox"
            @change="handleAssignEvenIfOffline"
          />
          <label for="assignEvenIfOffline">Assign even if offline</label>
        </div>

        <p class="pb-1 text-sm not-italic text-slate-600 dark:text-slate-400">
          Assign conversations to agents even when they are offline
        </p>
      </label>

      <label class="w-3/4 settings-item">
        <div class="flex items-center gap-2">
          <input
            id="reassignOnResolve"
            v-model="reassignOnResolve"
            type="checkbox"
            @change="handleReassignOnResolve"
          />
          <label for="reassignOnResolve">
            Reassign unassigned conversations on resolve
          </label>
        </div>

        <p class="pb-1 text-sm not-italic text-slate-600 dark:text-slate-400">
          When a conversation is resolved, automatically attempt to assign other
          unassigned conversations to available agents
        </p>
      </label>

      <label class="w-3/4 settings-item">
        <div class="flex items-center gap-2">
          <input
            id="noAgentMessageEnabled"
            v-model="noAgentMessageEnabled"
            type="checkbox"
            @change="handleNoAgentMessageEnabled"
          />
          <label for="noAgentMessageEnabled">
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.NO_AGENT_MESSAGE.LABEL') }}
          </label>
        </div>

        <p class="pb-1 text-sm not-italic text-slate-600 dark:text-slate-400">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.NO_AGENT_MESSAGE.HELP_TEXT') }}
        </p>
      </label>

      <div v-if="noAgentMessageEnabled" class="w-3/4 settings-item">
        <label>
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.NO_AGENT_MESSAGE.MESSAGE_LABEL') }}
        </label>
        <textarea
          v-model="noAgentMessage"
          class="w-full min-h-[80px] p-2 border border-slate-200 dark:border-slate-600 rounded-md dark:bg-slate-800"
          :placeholder="
            $t('INBOX_MGMT.SETTINGS_POPUP.NO_AGENT_MESSAGE.MESSAGE_PLACEHOLDER')
          "
          @blur="handleNoAgentMessageChange"
        />
      </div>

      <div v-if="isEnterprise" class="max-assignment-container">
        <woot-input
          v-model.trim="maxAssignmentLimit"
          type="number"
          :class="{ error: $v.maxAssignmentLimit.$error }"
          :error="maxAssignmentLimitErrors"
          :label="$t('INBOX_MGMT.AUTO_ASSIGNMENT.MAX_ASSIGNMENT_LIMIT')"
          @blur="$v.maxAssignmentLimit.$touch"
        />

        <p class="pb-1 text-sm not-italic text-slate-600 dark:text-slate-400">
          {{ $t('INBOX_MGMT.AUTO_ASSIGNMENT.MAX_ASSIGNMENT_LIMIT_SUB_TEXT') }}
        </p>

        <woot-submit-button
          :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
          :disabled="$v.maxAssignmentLimit.$invalid"
          @click="updateInbox"
        />
      </div>
    </settings-section>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { minValue } from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
import SettingsSection from '../../../../../components/SettingsSection.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import InboxMembersAPI from 'dashboard/api/inboxMembers';

export default {
  components: {
    SettingsSection,
    Thumbnail,
  },
  mixins: [alertMixin, configMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      selectedAgents: [],
      savedAgents: [],
      isAgentListUpdating: false,
      enableAutoAssignment: false,
      assignEvenIfOffline: false,
      reassignOnResolve: false,
      noAgentMessageEnabled: false,
      noAgentMessage: '',
      maxAssignmentLimit: null,
      eligibilityUpdating: {},
    };
  },
  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
    }),
    maxAssignmentLimitErrors() {
      if (this.$v.maxAssignmentLimit.$error) {
        return this.$t(
          'INBOX_MGMT.AUTO_ASSIGNMENT.MAX_ASSIGNMENT_LIMIT_RANGE_ERROR'
        );
      }
      return '';
    },
  },
  watch: {
    inbox() {
      this.setDefaults();
    },
  },
  mounted() {
    this.setDefaults();
  },
  methods: {
    setDefaults() {
      this.enableAutoAssignment = this.inbox.enable_auto_assignment;
      this.assignEvenIfOffline =
        this.inbox?.auto_assignment_config?.assign_even_if_offline || false;
      this.reassignOnResolve =
        this.inbox?.auto_assignment_config?.reassign_on_resolve || false;
      this.noAgentMessageEnabled =
        this.inbox?.auto_assignment_config?.no_agent_message_enabled || false;
      this.noAgentMessage =
        this.inbox?.auto_assignment_config?.no_agent_message || '';
      this.maxAssignmentLimit =
        this.inbox?.auto_assignment_config?.max_assignment_limit || null;
      this.fetchAttachedAgents();
    },
    async fetchAttachedAgents() {
      try {
        const response = await this.$store.dispatch('inboxMembers/get', {
          inboxId: this.inbox.id,
        });
        const {
          data: { payload: inboxMembers },
        } = response;
        this.selectedAgents = inboxMembers;
        this.savedAgents = [...inboxMembers];
      } catch (error) {
        //  Handle error
      }
    },
    handleEnableAutoAssignment() {
      this.updateInbox();
    },
    handleAssignEvenIfOffline() {
      this.updateInbox();
    },
    handleReassignOnResolve() {
      this.updateInbox();
    },
    handleNoAgentMessageEnabled() {
      this.updateInbox();
    },
    handleNoAgentMessageChange() {
      this.updateInbox();
    },
    async handleAssignmentEligibilityChange(agent, isEligible) {
      this.$set(this.eligibilityUpdating, agent.id, true);
      try {
        await InboxMembersAPI.updateAssignmentEligibility({
          inboxId: this.inbox.id,
          userId: agent.id,
          assignmentEligible: isEligible,
        });
        // Update local state for savedAgents
        const agentIndex = this.savedAgents.findIndex(a => a.id === agent.id);
        if (agentIndex !== -1) {
          this.$set(this.savedAgents, agentIndex, {
            ...this.savedAgents[agentIndex],
            assignment_eligible: isEligible,
          });
        }
        this.showAlert(
          this.$t(
            'INBOX_MGMT.SETTINGS_POPUP.ASSIGNMENT_ELIGIBILITY.UPDATE_SUCCESS'
          )
        );
      } catch (error) {
        this.showAlert(
          this.$t(
            'INBOX_MGMT.SETTINGS_POPUP.ASSIGNMENT_ELIGIBILITY.UPDATE_ERROR'
          )
        );
      } finally {
        this.$set(this.eligibilityUpdating, agent.id, false);
      }
    },
    async updateAgents() {
      const agentList = this.selectedAgents.map(el => el.id);
      this.isAgentListUpdating = true;
      try {
        const response = await this.$store.dispatch('inboxMembers/create', {
          inboxId: this.inbox.id,
          agentList,
        });
        const {
          data: { payload: inboxMembers },
        } = response;
        // Update savedAgents with the response from server (includes assignment_eligible)
        this.savedAgents = inboxMembers;
        this.selectedAgents = inboxMembers;
        this.showAlert(this.$t('AGENT_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('AGENT_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
      this.isAgentListUpdating = false;
    },
    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          enable_auto_assignment: this.enableAutoAssignment,
          assign_even_if_offline: this.assignEvenIfOffline,
          reassign_on_resolve: this.reassignOnResolve,
          no_agent_message_enabled: this.noAgentMessageEnabled,
          no_agent_message: this.noAgentMessage,
          auto_assignment_config: {
            max_assignment_limit: this.maxAssignmentLimit,
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
  },
  validations: {
    selectedAgents: {
      isEmpty() {
        return !!this.selectedAgents.length;
      },
    },
    maxAssignmentLimit: {
      minValue: minValue(1),
    },
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';

.max-assignment-container {
  padding-top: var(--space-slab);
  padding-bottom: var(--space-slab);
}

.agent-eligibility-list {
  display: flex;
  flex-direction: column;
  width: 100%;
  max-width: 100%;
  @apply border border-solid border-slate-50 dark:border-slate-700/30;
  border-radius: var(--border-radius-normal);
  overflow: hidden;
}

.agent-eligibility-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-small) var(--space-normal);
  @apply border-b border-solid border-slate-50 dark:border-slate-700/30;

  &:last-child {
    border-bottom: none;
  }
}

.agent-info {
  display: flex;
  align-items: center;
  gap: var(--space-small);
  flex: 1;
  min-width: 0;
}

.agent-details {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.agent-name {
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
  color: var(--s-900);

  .dark & {
    color: var(--s-100);
  }
}

.agent-email {
  font-size: var(--font-size-mini);
  color: var(--s-600);

  .dark & {
    color: var(--s-400);
  }
}

.eligibility-controls {
  display: flex;
  align-items: center;
  gap: var(--space-normal);
  flex-shrink: 0;
}

.agent-status-badge {
  font-size: var(--font-size-micro);
  font-weight: var(--font-weight-medium);
  padding: var(--space-micro) var(--space-small);
  border-radius: var(--border-radius-small);
  white-space: nowrap;

  &--eligible {
    background-color: var(--g-100);
    color: var(--g-800);

    .dark & {
      background-color: var(--g-800);
      color: var(--g-100);
    }
  }

  &--view-only {
    background-color: var(--s-200);
    color: var(--s-700);

    .dark & {
      background-color: var(--s-700);
      color: var(--s-200);
    }
  }
}

// Toggle switch styles
.toggle-switch {
  position: relative;
  display: inline-block;
  width: 40px;
  height: 22px;
  cursor: pointer;

  input {
    opacity: 0;
    width: 0;
    height: 0;

    &:checked + .toggle-slider {
      background-color: var(--g-500);
    }

    &:checked + .toggle-slider::before {
      transform: translateX(18px);
    }

    &:disabled + .toggle-slider {
      opacity: 0.5;
      cursor: not-allowed;
    }
  }
}

.toggle-slider {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: var(--s-300);
  border-radius: 22px;
  transition: 0.3s;

  .dark & {
    background-color: var(--s-600);
  }

  &::before {
    position: absolute;
    content: '';
    height: 16px;
    width: 16px;
    left: 3px;
    bottom: 3px;
    background-color: white;
    border-radius: 50%;
    transition: 0.3s;
  }
}
</style>
