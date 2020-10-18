<template>
  <header class="header-collapsed">
    <div class="header-branding">
      <img
        v-if="avatarUrl"
        class="inbox--avatar mr-3"
        :src="avatarUrl"
        alt="avatar"
      />
      <div class="text-black-700">
        <div class="font-medium text-base" v-html="title" />
        <div class="text-xs leading-4 mt-1">
          {{ `${teamAvailabilityStatus}. ${replyTimeStatus}` }}
        </div>
      </div>
    </div>
    <header-actions :show-popout-button="showPopoutButton" />
  </header>
</template>

<script>
import { mapGetters } from 'vuex';
import HeaderActions from './HeaderActions';
import configMixin from 'widget/mixins/configMixin';
import teamAvailabilityMixin from 'widget/mixins/teamAvailabilityMixin';

export default {
  name: 'ChatHeader',
  components: {
    HeaderActions,
  },
  mixins: [configMixin, teamAvailabilityMixin],
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
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';
@import '~widget/assets/scss/mixins.scss';

.header-collapsed {
  display: flex;
  justify-content: space-between;
  padding: $space-two $space-medium;
  width: 100%;
  box-sizing: border-box;
  background: white;
  @include shadow-large;

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
</style>
