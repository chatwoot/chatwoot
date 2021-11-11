<template>
  <header class="header-collapsed">
    <div class="header-branding">
      <header-back-button @click="onBackButtonClick" />
      <img
        v-if="avatarUrl"
        class="inbox--avatar mr-3"
        :src="avatarUrl"
        alt="avatar"
      />
      <div>
        <div class="text-black-900 font-medium text-base flex items-center">
          <span class="mr-1" v-html="title" />
          <div
            :class="
              `status-view--badge rounded-full leading-4 ${
                isOnline ? 'bg-green-500' : 'hidden'
              }`
            "
          />
        </div>
        <div class="text-xs mt-1 text-black-700">
          {{ replyWaitMeessage }}
        </div>
      </div>
    </div>
    <header-actions :show-popout-button="showPopoutButton" />
  </header>
</template>

<script>
import { mapGetters } from 'vuex';

import HeaderBackButton from 'widget/components/HeaderBackButton';
import HeaderActions from './HeaderActions';
import availabilityMixin from 'widget/mixins/availability';

export default {
  name: 'ChatHeader',
  components: {
    HeaderActions,
    HeaderBackButton,
  },
  mixins: [availabilityMixin],
  props: {
    avatarUrl: {
      type: String,
      default: '',
    },
    title: {
      type: String,
      default: '',
    },
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
    availableAgents: {
      type: Array,
      default: () => {},
    },
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    isOnline() {
      const { workingHoursEnabled } = this.channelConfig;
      const anyAgentOnline = this.availableAgents.length > 0;

      if (workingHoursEnabled) {
        return this.isInBetweenTheWorkingHours;
      }
      return anyAgentOnline;
    },
    replyWaitMeessage() {
      return this.isOnline
        ? this.replyTimeStatus
        : this.$t('TEAM_AVAILABILITY.OFFLINE');
    },
  },
  methods: {
    onBackButtonClick() {
      this.$router.back();
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';
@import '~widget/assets/scss/mixins.scss';

.header-collapsed {
  @apply flex;
  @apply justify-between;
  @apply py-5 px-4;
  @apply w-full;
  @apply box-border;

  .header-branding {
    display: flex;
    align-items: center;

    img {
      border-radius: 50%;
    }
  }

  .title {
    font-weight: $font-weight-medium;
  }

  .inbox--avatar {
    height: 32px;
    width: 32px;
  }
}

.status-view--badge {
  height: $space-small;
  width: $space-small;
}
</style>
