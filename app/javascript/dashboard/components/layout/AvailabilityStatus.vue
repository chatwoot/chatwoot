<template>
  <div class="status">
    <div class="status-view">
      <div
        :class="`status-badge status-badge__${currentUserAvailabilityStatus}`"
      />

      <div class="status-view--title">
        {{ currentUserAvailabilityStatus }}
      </div>
    </div>

    <div class="status-change">
      <transition name="menu-slide">
        <div
          v-if="isStatusMenuOpened"
          v-on-clickaway="closeStatusMenu"
          class="dropdown-pane top"
        >
          <ul class="vertical dropdown menu">
            <li
              v-for="status in availabilityStatuses"
              :key="status.value"
              class="status-items"
            >
              <div :class="`status-badge status-badge__${status.value}`" />

              <button
                class="button clear status-change--dropdown-button"
                :disabled="status.disabled"
                @click="changeAvailabilityStatus(status.value)"
              >
                {{ status.label }}
              </button>
            </li>
          </ul>
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

export default {
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
    currentUserAvailabilityStatus() {
      return this.currentUser.availability_status;
    },
    availabilityStatuses() {
      return this.$t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUSES_LIST').map(
        status => ({
          ...status,
          disabled: this.currentUserAvailabilityStatus === status.value,
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
  padding: $space-micro $space-smaller;
}

.status-view {
  display: flex;
  align-items: baseline;

  & &--title {
    color: $color-gray;
    font-size: $font-size-small;
    font-weight: $font-weight-medium;
    margin-left: $space-small;

    &:first-letter {
      text-transform: capitalize;
    }
  }
}

.status-change {
  .dropdown-pane {
    top: -130px;
  }

  .status-items {
    display: flex;
    align-items: baseline;
  }

  & &--change-button {
    color: $color-gray;
    font-size: $font-size-small;
    border-bottom: 1px solid $color-gray;
    cursor: pointer;

    &:hover {
      border-bottom: none;
    }
  }

  & &--dropdown-button {
    font-weight: $font-weight-normal;
    font-size: $font-size-small;
    padding: $space-small $space-one;
    text-align: left;
    width: 100%;
  }
}

.status-badge {
  width: $space-one;
  height: $space-one;
  border-radius: 50%;

  &__online {
    background: $success-color;
  }

  &__offline {
    background: $color-gray;
  }

  &__busy {
    background: $warning-color;
  }
}
</style>
