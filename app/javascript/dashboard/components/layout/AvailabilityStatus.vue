<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
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
    }),
    statusList() {
      return [
        this.$t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.ONLINE'),
        this.$t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.BUSY'),
        this.$t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.OFFLINE'),
      ];
    },
    availabilityDisplayLabel() {
      const availabilityIndex = AVAILABILITY_STATUS_KEYS.findIndex(
        key => key === this.currentUserAvailability
      );
      return this.statusList[availabilityIndex];
    },
    currentUserAvailability() {
      return this.getCurrentUserAvailability;
    },
    availabilityStatuses() {
      return this.statusList.map((statusLabel, index) => ({
        label: statusLabel,
        value: AVAILABILITY_STATUS_KEYS[index],
        disabled:
          this.currentUserAvailability === AVAILABILITY_STATUS_KEYS[index],
      }));
    },
  },

  methods: {
    openStatusMenu() {
      this.isStatusMenuOpened = true;
    },
    closeStatusMenu() {
      this.isStatusMenuOpened = false;
    },
    updateAutoOffline(autoOffline) {
      this.$store.dispatch('updateAutoOffline', {
        accountId: this.currentAccountId,
        autoOffline,
      });
    },
    changeAvailabilityStatus(availability) {
      if (this.isUpdating) {
        return;
      }

      this.isUpdating = true;
      try {
        this.$store.dispatch('updateAvailability', {
          availability,
          account_id: this.currentAccountId,
        });
      } catch (error) {
        useAlert(
          this.$t('PROFILE_SETTINGS.FORM.AVAILABILITY.SET_AVAILABILITY_ERROR')
        );
      } finally {
        this.isUpdating = false;
      }
    },
  },
};
</script>

<template>
  <WootDropdownMenu>
    <WootDropdownHeader :title="$t('SIDEBAR.SET_AVAILABILITY_TITLE')" />
    <WootDropdownItem
      v-for="status in availabilityStatuses"
      :key="status.value"
      class="flex items-baseline"
    >
      <woot-button
        size="small"
        :color-scheme="status.disabled ? '' : 'secondary'"
        :variant="status.disabled ? 'smooth' : 'clear'"
        class="status-change--dropdown-button"
        @click="changeAvailabilityStatus(status.value)"
      >
        <AvailabilityStatusBadge :status="status.value" />
        {{ status.label }}
      </woot-button>
    </WootDropdownItem>
    <WootDropdownDivider />
    <WootDropdownItem class="flex items-center justify-between p-2 m-0">
      <div class="flex items-center">
        <fluent-icon
          v-tooltip.right-start="$t('SIDEBAR.SET_AUTO_OFFLINE.INFO_TEXT')"
          icon="info"
          size="14"
          class="mt-px"
        />

        <span
          class="mx-1 my-0 text-xs font-medium text-slate-600 dark:text-slate-100"
        >
          {{ $t('SIDEBAR.SET_AUTO_OFFLINE.TEXT') }}
        </span>
      </div>

      <woot-switch
        size="small"
        class="mx-1 mt-px mb-0"
        :model-value="currentUserAutoOffline"
        @input="updateAutoOffline"
      />
    </WootDropdownItem>
    <WootDropdownDivider />
  </WootDropdownMenu>
</template>
