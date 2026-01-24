<template>
  <woot-dropdown-menu>
    <woot-dropdown-header :title="$t('SIDEBAR.SET_AVAILABILITY_TITLE')" />
    <woot-dropdown-item
      v-for="status in availabilityStatuses"
      :key="status.value"
      class="flex items-baseline"
    >
      <woot-button
        size="small"
        :color-scheme="status.disabled ? '' : 'secondary'"
        :variant="status.disabled ? 'smooth' : 'clear'"
        class-names="status-change--dropdown-button"
        @click="changeAvailabilityStatus(status.value)"
      >
        <availability-status-badge :status="status.value" />
        {{ status.label }}
      </woot-button>
    </woot-dropdown-item>
    <woot-dropdown-divider v-if="shouldRestrictAvailability" />
    <template v-if="!shouldRestrictAvailability">
      <woot-dropdown-divider />
      <woot-dropdown-item class="m-0 flex items-center justify-between p-2">
        <div class="flex items-center">
          <fluent-icon
            v-tooltip.right-start="$t('SIDEBAR.SET_AUTO_OFFLINE.INFO_TEXT')"
            icon="info"
            size="14"
            class="mt-px"
          />

          <span
            class="my-0 mx-1 text-xs font-medium text-slate-600 dark:text-slate-100"
          >
            {{ $t('SIDEBAR.SET_AUTO_OFFLINE.TEXT') }}
          </span>
        </div>

        <woot-switch
          size="small"
          class="mt-px mx-1 mb-0"
          :value="currentUserAutoOffline"
          @input="updateAutoOffline"
        />
      </woot-dropdown-item>
      <woot-dropdown-item
        v-if="showCallAvailabilityToggle"
        class="m-0 flex items-center justify-between p-2"
      >
        <div class="flex items-center">
          <fluent-icon
            v-tooltip.right-start="
              $t('SIDEBAR.SET_CALL_AVAILABILITY.INFO_TEXT')
            "
            icon="info"
            size="14"
            class="mt-px"
          />

          <span
            class="my-0 mx-1 text-xs font-medium text-slate-600 dark:text-slate-100"
          >
            {{ $t('SIDEBAR.SET_CALL_AVAILABILITY.TEXT') }}
          </span>
        </div>

        <woot-switch
          size="small"
          class="mt-px mx-1 mb-0"
          :value="currentUserCallAvailable"
          @input="updateCallAvailability"
        />
      </woot-dropdown-item>
      <woot-dropdown-divider />
    </template>
  </woot-dropdown-menu>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import WootDropdownHeader from 'shared/components/ui/dropdown/DropdownHeader.vue';
import WootDropdownDivider from 'shared/components/ui/dropdown/DropdownDivider.vue';
import AvailabilityStatusBadge from '../widgets/conversation/AvailabilityStatusBadge.vue';
import wootConstants from 'dashboard/constants/globals';

const { AVAILABILITY_STATUS_KEYS } = wootConstants;

export default {
  components: {
    WootDropdownHeader,
    WootDropdownDivider,
    WootDropdownMenu,
    WootDropdownItem,
    AvailabilityStatusBadge,
  },

  mixins: [alertMixin],

  data() {
    return {
      isStatusMenuOpened: false,
      isUpdating: false,
    };
  },
  computed: {
    ...mapGetters({
      getCurrentUserAvailability: 'getCurrentUserAvailability',
      currentAccountId: 'getCurrentAccountId',
      currentUserAutoOffline: 'getCurrentUserAutoOffline',
      currentUserCallAvailable: 'getCurrentUserCallAvailable',
      currentRole: 'getCurrentRole',
      currentUserId: 'getCurrentUserID',
    }),
    currentAccount() {
      return this.$store.getters['accounts/getAccount'](this.currentAccountId);
    },
    isCallingEnabled() {
      return !!this.currentAccount?.custom_attributes?.call_config;
    },
    isCurrentUserCallingAgent() {
      const callingSettings =
        this.currentAccount?.custom_attributes?.calling_settings;
      if (!callingSettings) return false;

      const selectedAgents = callingSettings.selectedAgents || [];
      return selectedAgents.some(agent => agent.id === this.currentUserId);
    },
    showCallAvailabilityToggle() {
      return this.isCallingEnabled && this.isCurrentUserCallingAgent;
    },
    isAdmin() {
      return this.currentRole === 'administrator';
    },
    isAgentBusinessHoursActive() {
      return this.currentAccount?.agent_business_hours_active || false;
    },
    shouldRestrictAvailability() {
      // Only restrict non-admin users during business hours
      return this.isAgentBusinessHoursActive && !this.isAdmin;
    },
    availabilityDisplayLabel() {
      const availabilityIndex = AVAILABILITY_STATUS_KEYS.findIndex(
        key => key === this.currentUserAvailability
      );
      return this.$t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUSES_LIST')[
        availabilityIndex
      ];
    },
    currentUserAvailability() {
      return this.getCurrentUserAvailability;
    },
    availabilityStatuses() {
      const statuses = this.$t(
        'PROFILE_SETTINGS.FORM.AVAILABILITY.STATUSES_LIST'
      ).map((statusLabel, index) => ({
        label: statusLabel,
        value: AVAILABILITY_STATUS_KEYS[index],
        disabled:
          this.currentUserAvailability === AVAILABILITY_STATUS_KEYS[index],
      }));

      // During business hours, hide the offline option for non-admin users
      if (this.shouldRestrictAvailability) {
        return statuses.filter(status => status.value !== 'offline');
      }

      return statuses;
    },
  },

  mounted() {
    this.checkAndDisableAutoOfflineInBusinessHours();
  },

  methods: {
    openStatusMenu() {
      this.isStatusMenuOpened = true;
    },
    closeStatusMenu() {
      this.isStatusMenuOpened = false;
    },
    checkAndDisableAutoOfflineInBusinessHours() {
      // If in business hours and auto_offline is enabled, disable it automatically (only for non-admins)
      if (this.shouldRestrictAvailability && this.currentUserAutoOffline) {
        this.updateAutoOffline(false);
      }
    },
    updateAutoOffline(autoOffline) {
      this.$store.dispatch('updateAutoOffline', {
        accountId: this.currentAccountId,
        autoOffline,
      });
    },
    updateCallAvailability(callAvailable) {
      this.$store.dispatch('updateCallAvailability', {
        accountId: this.currentAccountId,
        callAvailable,
      });
    },
    changeAvailabilityStatus(availability) {
      if (this.isUpdating) {
        return;
      }

      // Prevent non-admin agents from going offline during business hours
      if (availability === 'offline' && this.shouldRestrictAvailability) {
        this.showAlert('Cannot mark offline during business hours');
        return;
      }

      this.isUpdating = true;
      try {
        this.$store.dispatch('updateAvailability', {
          availability,
          account_id: this.currentAccountId,
        });
      } catch (error) {
        this.showAlert(
          error?.response?.data?.error ||
            this.$t('PROFILE_SETTINGS.FORM.AVAILABILITY.SET_AVAILABILITY_ERROR')
        );
      } finally {
        this.isUpdating = false;
      }
    },
  },
};
</script>
