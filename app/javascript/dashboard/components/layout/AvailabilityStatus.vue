<template>
  <div class="status">
    <div class="status-view">
      <div
        :class="`status-badge status-badge__${currentUserAvailabilityStatus}`"
      />

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
              <button
                class="button clear status-change--dropdown-button"
                :disabled="status.disabled"
                @click="changeAvailabilityStatus(status.value)"
              >
                <span :class="`status-badge status-badge__${status.value}`" />
                {{ status.label }}
              </button>
            </woot-dropdown-item>
          </woot-dropdown-menu>
        </div>
      </transition>

      <button class="status-change--change-button" @click="openStatusMenu">
        {{ $t('SIDEBAR_ITEMS.CHANGE_AVAILABILITY_STATUS') }}
      </button>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';

const AVAILABILITY_STATUS_KEYS = ['online', 'busy', 'offline'];

export default {
  components: {
    WootDropdownMenu,
    WootDropdownItem,
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
      currentUser: 'getCurrentUser',
    }),
    availabilityDisplayLabel() {
      const availabilityIndex = AVAILABILITY_STATUS_KEYS.findIndex(
        key => key === this.currentUserAvailabilityStatus
      );
      return this.$t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUSES_LIST')[
        availabilityIndex
      ];
    },
    currentUserAvailabilityStatus() {
      return this.currentUser.availability_status;
    },
    availabilityStatuses() {
      return this.$t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUSES_LIST').map(
        (statusLabel, index) => ({
          label: statusLabel,
          value: AVAILABILITY_STATUS_KEYS[index],
          disabled:
            this.currentUserAvailabilityStatus ===
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
    changeAvailabilityStatus(availability) {
      if (this.isUpdating) {
        return;
      }

      this.isUpdating = true;

      this.$store
        .dispatch('updateAvailability', {
          availability,
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

.status-badge {
  width: var(--space-one);
  height: var(--space-one);
  margin-right: var(--space-micro);
  display: inline-block;
  border-radius: 50%;

  &__online {
    background: var(--g-400);
  }

  &__offline {
    background: var(--b-600);
  }

  &__busy {
    background: var(--y-700);
  }
}

.status-change {
  .dropdown-pane {
    top: -132px;
  }

  .status-items {
    display: flex;
    align-items: baseline;
  }
  & &--change-button {
    color: var(--b-600);
    font-size: var(--font-size-small);
    cursor: pointer;
    outline: none;

    &:hover {
      color: var(--w-600);
    }
  }
}
</style>
