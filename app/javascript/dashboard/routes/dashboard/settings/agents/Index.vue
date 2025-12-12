<template>
  <div class="flex-1 overflow-auto p-4">
    <!-- Tabs -->
    <woot-tabs :index="selectedTabIndex" @change="onTabChange">
      <woot-tabs-item
        :name="$t('AGENT_MGMT.AGENT_LIST_TAB')"
        :show-badge="false"
      />
      <woot-tabs-item
        :name="$t('AGENT_MGMT.BUSINESS_HOURS_TAB')"
        :show-badge="false"
      />
    </woot-tabs>

    <!-- Tab 1: Agent List -->
    <div v-if="selectedTabIndex === 0">
      <woot-button
        color-scheme="success"
        class-names="button--fixed-top"
        icon="add-circle"
        @click="openAddPopup()"
      >
        {{ $t('AGENT_MGMT.HEADER_BTN_TXT') }}
      </woot-button>

      <!-- Business Hours Active Badge -->
      <banner
        v-if="isAgentBusinessHoursActive"
        color-scheme="secondary"
        :banner-message="$t('AGENT_MGMT.BUSINESS_HOURS_ACTIVE')"
        class="mb-4"
      />

      <!-- List Agents -->
      <div class="flex flex-row gap-4">
        <div class="w-full lg:w-3/5">
          <woot-loading-state
            v-if="uiFlags.isFetching"
            :message="$t('AGENT_MGMT.LOADING')"
          />
          <div v-else>
            <p v-if="!agentList.length">
              {{ $t('AGENT_MGMT.LIST.404') }}
            </p>
            <table v-else class="woot-table">
              <tbody>
                <tr v-for="(agent, index) in agentList" :key="agent.email">
                  <!-- Gravtar Image -->
                  <td>
                    <thumbnail
                      :src="agent.thumbnail"
                      :username="agent.name"
                      size="40px"
                      :status="agent.availability_status"
                    />
                  </td>
                  <!-- Agent Name + Email -->
                  <td>
                    <span class="agent-name">
                      {{ agent.name }}
                    </span>
                    <span>{{ agent.email }}</span>
                  </td>
                  <!-- Agent Role + Verification Status -->
                  <td>
                    <span class="agent-name">
                      {{
                        $t(`AGENT_MGMT.AGENT_TYPES.${agent.role.toUpperCase()}`)
                      }}
                    </span>
                    <span v-if="agent.confirmed">
                      {{ $t('AGENT_MGMT.LIST.VERIFIED') }}
                    </span>
                    <span v-if="!agent.confirmed">
                      {{ $t('AGENT_MGMT.LIST.VERIFICATION_PENDING') }}
                    </span>
                  </td>
                  <!-- Actions -->
                  <td>
                    <div class="button-wrapper">
                      <woot-button
                        v-if="showEditAction(agent)"
                        v-tooltip.top="$t('AGENT_MGMT.EDIT.BUTTON_TEXT')"
                        variant="smooth"
                        size="tiny"
                        color-scheme="secondary"
                        icon="edit"
                        class-names="grey-btn"
                        @click="openEditPopup(agent)"
                      />
                      <woot-button
                        v-if="showDeleteAction(agent)"
                        v-tooltip.top="$t('AGENT_MGMT.DELETE.BUTTON_TEXT')"
                        variant="smooth"
                        color-scheme="alert"
                        size="tiny"
                        icon="dismiss-circle"
                        class-names="grey-btn"
                        :is-loading="loading[agent.id]"
                        @click="openDeletePopup(agent, index)"
                      />
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
        <div class="w-1/3 hidden lg:block">
          <span
            v-dompurify-html="
              useInstallationName(
                $t('AGENT_MGMT.SIDEBAR_TXT'),
                globalConfig.installationName
              )
            "
          />
        </div>
      </div>

      <!-- Modals for Agent List Tab -->
      <!-- Add Agent -->
      <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
        <add-agent :on-close="hideAddPopup" />
      </woot-modal>
      <!-- Edit Agent -->
      <woot-modal :show.sync="showEditPopup" :on-close="hideEditPopup">
        <edit-agent
          v-if="showEditPopup"
          :id="currentAgent.id"
          :name="currentAgent.name"
          :type="currentAgent.role"
          :email="currentAgent.email"
          :availability="currentAgent.availability_status"
          :on-close="hideEditPopup"
        />
      </woot-modal>
      <!-- Delete Agent -->
      <woot-delete-modal
        :show.sync="showDeletePopup"
        :on-close="closeDeletePopup"
        :on-confirm="confirmDeletion"
        :title="$t('AGENT_MGMT.DELETE.CONFIRM.TITLE')"
        :message="$t('AGENT_MGMT.DELETE.CONFIRM.MESSAGE')"
        :message-value="deleteMessage"
        :confirm-text="deleteConfirmText"
        :reject-text="deleteRejectText"
      />
    </div>

    <!-- Tab 2: Business Hours -->
    <div v-if="selectedTabIndex === 1">
      <agent-weekly-availability :account-id="accountId" />
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import Thumbnail from '../../../../components/widgets/Thumbnail.vue';
import Banner from '../../../../components/ui/Banner.vue';
import AddAgent from './AddAgent.vue';
import EditAgent from './EditAgent.vue';
import AgentWeeklyAvailability from './components/AgentWeeklyAvailability.vue';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    AddAgent,
    EditAgent,
    AgentWeeklyAvailability,
    Thumbnail,
    Banner,
  },
  mixins: [globalConfigMixin, alertMixin],
  data() {
    return {
      loading: {},
      showAddPopup: false,
      showDeletePopup: false,
      showEditPopup: false,
      agentAPI: {
        message: '',
      },
      currentAgent: {},
      selectedTabIndex: 0,
    };
  },
  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
      uiFlags: 'agents/getUIFlags',
      currentUserId: 'getCurrentUserID',
      globalConfig: 'globalConfig/get',
      accountId: 'getCurrentAccountId',
    }),
    account() {
      return this.$store.getters['accounts/getAccount'](this.accountId);
    },
    isAgentBusinessHoursActive() {
      return this.account?.agent_business_hours_active || false;
    },
    deleteConfirmText() {
      return `${this.$t('AGENT_MGMT.DELETE.CONFIRM.YES')} ${
        this.currentAgent.name
      }`;
    },
    deleteRejectText() {
      return `${this.$t('AGENT_MGMT.DELETE.CONFIRM.NO')} ${
        this.currentAgent.name
      }`;
    },
    deleteMessage() {
      return ` ${this.currentAgent.name}?`;
    },
  },
  mounted() {
    this.$store.dispatch('agents/get');
  },
  methods: {
    onTabChange(index) {
      this.selectedTabIndex = index;
    },
    showEditAction(agent) {
      return (
        this.currentUserId !== agent.id &&
        agent.available_name.toLowerCase() !== 'bitespeed bot'
      );
    },
    showDeleteAction(agent) {
      if (
        agent.available_name.toLowerCase() === 'bitespeed bot' ||
        this.currentUserId === agent.id
      )
        return false;

      if (!agent.confirmed) {
        return true;
      }

      if (agent.role === 'administrator') {
        return this.verifiedAdministrators().length !== 1;
      }
      return true;
    },
    verifiedAdministrators() {
      return this.agentList.filter(
        agent => agent.role === 'administrator' && agent.confirmed
      );
    },
    // Edit Function
    openAddPopup() {
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
    },

    // Edit Function
    openEditPopup(agent) {
      this.showEditPopup = true;
      this.currentAgent = agent;
    },
    hideEditPopup() {
      this.showEditPopup = false;
    },

    // Delete Function
    openDeletePopup(agent) {
      this.showDeletePopup = true;
      this.currentAgent = agent;
    },
    closeDeletePopup() {
      this.showDeletePopup = false;
    },
    confirmDeletion() {
      this.loading[this.currentAgent.id] = true;
      this.closeDeletePopup();
      this.deleteAgent(this.currentAgent.id);
    },
    async deleteAgent(id) {
      try {
        await this.$store.dispatch('agents/delete', id);
        this.showAlertMessage(this.$t('AGENT_MGMT.DELETE.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlertMessage(this.$t('AGENT_MGMT.DELETE.API.ERROR_MESSAGE'));
      }
    },
    // Show SnackBar
    showAlertMessage(message) {
      // Reset loading, current selected agent
      this.loading[this.currentAgent.id] = false;
      this.currentAgent = {};
      // Show message
      this.agentAPI.message = message;
      this.showAlert(message);
    },
  },
};
</script>
