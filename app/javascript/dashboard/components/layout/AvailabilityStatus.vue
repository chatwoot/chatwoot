<template>
  <div class="status">
    <div class="status-view">
      <availability-status-badge :status="currentUserAvailability" />
      <div class="status-view--title">
        {{ availabilityDisplayLabel }}
      </div>
    </div>

    <div class="status-change">
      <transition name="menu-slide">
        <div
          v-if="isStatusMenuOpened"
          v-on-clickaway="closeStatusMenu"
          class="dropdown-pane dropdowm--top"
        >
          <woot-dropdown-menu>
            <woot-dropdown-item
              v-for="status in availabilityStatuses"
              :key="status.value"
              class="status-items"
            >
              <woot-button
                variant="clear"
                size="small"
                color-scheme="secondary"
                class-names="status-change--dropdown-button"
                :is-disabled="status.disabled"
                @click="
                  changeAvailabilityStatus(status.value, currentAccountId)
                "
              >
                <availability-status-badge :status="status.value" />
                {{ status.label }}
              </woot-button>
            </woot-dropdown-item>
          </woot-dropdown-menu>
        </div>
      </transition>

      <woot-button
        variant="clear"
        color-scheme="secondary"
        class-names="status-change--change-button link"
        @click="openStatusMenu"
      >
        {{ $t('SIDEBAR_ITEMS.CHANGE_AVAILABILITY_STATUS') }}
      </woot-button>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import AvailabilityStatusBadge from '../widgets/conversation/AvailabilityStatusBadge';

const AVAILABILITY_STATUS_KEYS = ['online', 'busy', 'offline'];

export default {
  components: {
    WootDropdownMenu,
    WootDropdownItem,
    AvailabilityStatusBadge,
  },

  mixins: [clickaway],

  data() {
    return {
      isStatusMenuOpened: false,
      isUpdating: false,
    };
  },

  computed: {
    ...mapGetters({
      getCurrentUserAvailability: 'getCurrentUserAvailability',
      getCurrentAccountId: 'getCurrentAccountId',
    }),
    availabilityDisplayLabel() {
      const availabilityIndex = AVAILABILITY_STATUS_KEYS.findIndex(
        key => key === this.currentUserAvailability
      );
      return this.$t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUSES_LIST')[
        availabilityIndex
      ];
    },
    currentAccountId() {
      return this.getCurrentAccountId;
    },
    currentUserAvailability() {
      return this.getCurrentUserAvailability;
    },
    availabilityStatuses() {
      return this.$t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUSES_LIST').map(
        (statusLabel, index) => ({
          label: statusLabel,
          value: AVAILABILITY_STATUS_KEYS[index],
          disabled:
            this.currentUserAvailability ===
            AVAILABILITY_STATUS_KEYS[index],
        })
      );
    },
  },

  methods: {
    openStatusMenu() {
      this.isStatusMenuOpened = true;
    },
    closeStatusMenu() {
      this.isStatusMenuOpened = false;
    },
    changeAvailabilityStatus(availability, accountId) {
      if (this.isUpdating) {
        return;
      }

      this.isUpdating = true;
      this.$store
        .dispatch('updateAvailability', {
          availability: availability,
          account_id: accountId,
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
  },
};
</script>

<style lang="scss">
@import '~dashboard/assets/scss/variables';

.status {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-micro) var(--space-smaller);
}

.status-view {
  display: flex;
  align-items: baseline;

  & &--title {
    color: var(--b-600);
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-medium);
    margin-left: var(--space-small);

    &:first-letter {
      text-transform: capitalize;
    }
  }
}

.status-change {
  .dropdown-pane {
    top: -132px;
    right: var(--space-normal);
  }

  .status-items {
    display: flex;
    align-items: baseline;
  }
}
</style>
