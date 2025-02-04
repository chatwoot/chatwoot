<template>
  <div>
    <settings-section
      :title="'Assign calls to'"
      :sub-title="'Pick the agents or teams to assign calls'"
    >
      <div class="flex items-center gap-4 mb-4">
        <label class="flex items-center gap-2">
          <input
            v-model="assignmentType"
            type="radio"
            value="agent"
            name="assignmentType"
            @change="onAssignmentTypeChange"
          />
          {{ 'Agent' }}
        </label>
        <label class="flex items-center gap-2">
          <input
            v-model="assignmentType"
            type="radio"
            value="team"
            name="assignmentType"
            @change="onAssignmentTypeChange"
          />
          {{ 'Team' }}
        </label>
      </div>
      <p class="pb-1 text-sm not-italic text-slate-600 dark:text-slate-400">
        {{ 'Attempt connecting inbound calls to either agents or teams' }}
      </p>
    </settings-section>

    <settings-section
      v-if="assignmentType === 'agent'"
      :title="'Agents'"
      :sub-title="'Add or remove agents'"
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

      <p class="pb-1 text-sm not-italic text-slate-600 dark:text-slate-400">
        {{
          'Make sure agents are also added to the inboxes where call conversations happen'
        }}
      </p>
    </settings-section>
    <settings-section
      v-if="assignmentType === 'team'"
      :title="'Teams'"
      :sub-title="'Add or remove teams'"
    >
      <multiselect
        v-model="selectedTeams"
        :options="teamsList"
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
        @select="onTeamsChange"
        @remove="onTeamsChange"
      />

      <p class="pb-1 text-sm not-italic text-slate-600 dark:text-slate-400">
        {{
          'Make sure agents in the teams are also added to the inboxes where call conversations happen'
        }}
      </p>
    </settings-section>

    <settings-section
      :title="'Assignment Method'"
      :sub-title="'Pick the method with which calls are attempted to connect'"
    >
      <div class="flex items-center gap-4 mb-4">
        <label class="flex items-center gap-2">
          <input
            v-model="assignmentRule"
            type="radio"
            value="sequential"
            name="assignmentRule"
          />
          {{ 'Sequential Ringing' }}
        </label>
        <label class="flex items-center gap-2">
          <input
            v-model="assignmentRule"
            type="radio"
            value="parallel"
            name="assignmentRule"
          />
          {{ 'Parallel Ringing' }}
        </label>
      </div>
      <p class="pb-1 text-sm not-italic text-slate-600 dark:text-slate-400">
        {{
          'In sequential mode, calls are attempted to connect to available agents in order of round-robin. In parallel mode, calls are attempted to connect to available agents in parallel.'
        }}
      </p>
    </settings-section>

    <settings-section
      :title="'Call Playback Messages'"
      :sub-title="'Messages that will be played when a call is connected or missed'"
      :show-border="false"
    >
      <div class="max-w-[37.5rem]">
        <label class="unavailable-input-wrap">
          {{ 'Welcome message' }}
        </label>
        <p class="pb-1 text-sm not-italic text-slate-600 dark:text-slate-400">
          {{ 'This message will play automatically when a call is received' }}
        </p>
        <textarea v-model="welcomeMessage" type="text" style="height: 8rem" />
      </div>
      <div class="max-w-[37.5rem]">
        <label class="unavailable-input-wrap">
          {{ 'Missed Call Message' }}
        </label>
        <p class="pb-1 text-sm not-italic text-slate-600 dark:text-slate-400">
          {{
            'This message will be played when all agents are busy or unavailable to take the call.'
          }}
        </p>
        <textarea
          v-model="missedCallMessage"
          type="text"
          style="height: 8rem"
        />
      </div>
    </settings-section>

    <settings-section :show-border="false">
      <woot-submit-button
        :button-text="'Update Settings'"
        :loading="isCallSettingsUpdating"
        @click="updateCallSettings"
      />
    </settings-section>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
import SettingsSection from '../../../../../components/SettingsSection.vue';

export default {
  components: {
    SettingsSection,
  },
  mixins: [alertMixin, configMixin],
  props: {
    accountId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      callingSettings: {},
      selectedAgents: [],
      selectedTeams: [],
      assignmentType: 'agent',
      assignmentRule: 'sequential',
      isCallSettingsUpdating: false,
      welcomeMessage: '',
      missedCallMessage: '',
    };
  },
  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
      teamsList: 'teams/getTeams',
      getAccount: 'accounts/getAccount',
      uiFlags: 'accounts/getUIFlags',
    }),
    isUpdating() {
      return this.uiFlags.isUpdating;
    },
  },
  mounted() {
    this.initializeData();
  },
  methods: {
    initializeData() {
      const { custom_attributes } = this.getAccount(this.accountId);
      this.callingSettings = custom_attributes.calling_settings;
      this.selectedAgents = this.callingSettings.selectedAgents || [];
      this.selectedTeams = this.callingSettings.selectedTeams || [];
      this.assignmentType = this.callingSettings.assignmentType || 'agent';
      this.assignmentRule = this.callingSettings.assignmentRule || 'sequential';
      this.welcomeMessage = this.callingSettings.welcomeMessage || '';
      this.missedCallMessage = this.callingSettings.missedCallMessage || '';

      this.onAssignmentTypeChange();
      this.onTeamsChange();
    },
    async updateCallSettings() {
      try {
        const payload = {
          selectedAgents: this.selectedAgents,
          selectedTeams: this.selectedTeams,
          assignmentType: this.assignmentType,
          assignmentRule: this.assignmentRule,
          welcomeMessage: this.welcomeMessage,
          missedCallMessage: this.missedCallMessage,
        };
        await this.$store.dispatch('accounts/update', {
          calling_settings: payload,
        });
        this.initializeData();
        this.showAlert(this.$t('Call Settings Updated Successfully'));
      } catch (error) {
        this.showAlert('Error Updating Call Settings');
      }
    },
    onTeamsChange() {
      this.$emit('selected-teams-change', this.selectedTeams);
    },
    onAssignmentTypeChange() {
      this.$emit('assignment-type-change', this.assignmentType);
    },
  },
  validations: {
    selectedAgents: {
      isEmpty() {
        return !!this.selectedAgents.length && this.assignmentType === 'agent';
      },
    },
    selectedTeams: {
      isEmpty() {
        return !!this.selectedTeams.length && this.assignmentType === 'team';
      },
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
</style>
