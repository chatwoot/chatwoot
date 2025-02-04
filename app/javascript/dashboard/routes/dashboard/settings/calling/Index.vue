<template>
  <div
    class="flex-grow flex-shrink w-full min-w-0 pl-0 pr-0 overflow-auto bg-white settings dark:bg-slate-800"
  >
    <setting-intro-banner
      :header-title="'Settings'"
      :header-content="'You can manage your inbound call settings here.'"
    >
      <woot-tabs
        class="settings--tabs"
        :index="selectedTabIndex"
        :border="false"
        @change="onTabChange"
      >
        <woot-tabs-item
          v-for="tab in tabs"
          :key="tab.key"
          :name="tab.name"
          :show-badge="false"
        />
      </woot-tabs>
    </setting-intro-banner>
    <div v-if="selectedTabKey === 'collaborators'" class="mx-8">
      <collaborators-page
        :account-id="accountId"
        @selected-teams-change="handleSelectedTeamsChange"
        @assignment-type-change="handleAssignmentTypeChange"
      />
    </div>

    <div v-if="selectedTabKey === 'businesshours'" :assignment-type="'team'">
      <weekly-availability
        :account-id="accountId"
        :assignment-type="assignmentType"
        :selected-teams="selectedTeams"
      />
    </div>
  </div>
</template>

<script>
import { required, minValue, maxValue } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
import accountMixin from '../../../../mixins/account';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import SettingIntroBanner from 'dashboard/components/widgets/SettingIntroBanner.vue';
import CollaboratorsPage from './components/CollaboratorsPage.vue';
import WeeklyAvailability from './components/WeeklyAvailability.vue';

export default {
  components: {
    SettingIntroBanner,
    CollaboratorsPage,
    WeeklyAvailability,
  },
  mixins: [accountMixin, alertMixin, configMixin, uiSettingsMixin],
  data() {
    return {
      id: '',
      selectedTabIndex: 0,
      assignmentType: 'agent',
      selectedTeams: [],
    };
  },
  validations: {
    name: {
      required,
    },
    locale: {
      required,
    },
    autoResolveDuration: {
      minValue: minValue(1),
      maxValue: maxValue(999),
    },
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      getAccount: 'accounts/getAccount',
      accountId: 'getCurrentAccountId',
      getCallingSettings: 'accounts/getCallingSettings',
    }),
    selectedTabKey() {
      return this.tabs[this.selectedTabIndex]?.key;
    },
    tabs() {
      return [
        {
          key: 'collaborators',
          name: 'Collaborators',
        },
        {
          key: 'businesshours',
          name: 'Business Hours',
        },
      ];
    },

    getAccountId() {
      return this.id.toString();
    },
  },
  mounted() {
    this.initializeAccount();
  },
  methods: {
    onTabChange(selectedTabIndex) {
      this.selectedTabIndex = selectedTabIndex;
    },
    async initializeAccount() {
      try {
        const { custom_attributes } = this.getAccount(this.accountId);
        this.callingSettings = custom_attributes.calling_settings;
        this.assignmentType = this.callingSettings.assignmentType || 'agent';
        this.selectedTeams = this.callingSettings.selectedTeams || [];
      } catch (error) {
        // Ignore error
      }
    },

    handleAssignmentTypeChange(type) {
      this.assignmentType = type;
    },

    handleSelectedTeamsChange(teams) {
      this.selectedTeams = teams;
    },
  },
};
</script>

<style scoped lang="scss">
.settings--tabs {
  ::v-deep .tabs {
    @apply p-0;
  }
}
</style>
