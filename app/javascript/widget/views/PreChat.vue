<template>
  <div class="home" @keydown.esc="closeChat">
    <div class="header-wrap bg-white  collapsed">
      <chat-header
        :title="channelConfig.websiteName"
        :avatar-url="channelConfig.avatarUrl"
        :show-popout-button="false"
        :available-agents="availableAgents"
      />
    </div>
    <banner />
    <div class="flex flex-1 overflow-auto">
      <pre-chat-form :options="preChatFormOptions" />
    </div>
    <div class="footer-wrap">
      <branding></branding>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import Branding from 'shared/components/Branding';
import ChatHeader from 'widget/components/ChatHeader';
import PreChatForm from 'widget/components/PreChat/Form';
import Banner from 'widget/components/Banner';

import configMixin from '../mixins/configMixin';

export default {
  name: 'Home',
  components: {
    Branding,
    ChatHeader,
    PreChatForm,
    Banner,
  },
  mixins: [configMixin],
  computed: {
    ...mapGetters({
      availableAgents: 'agent/availableAgents',
      currentUser: 'contactV2/getCurrentUser',
    }),
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables';
@import '~widget/assets/scss/mixins';

.home {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap;
  overflow: hidden;
  background: $color-background;

  .header-wrap {
    border-radius: $space-normal $space-normal 0 0;
    flex-shrink: 0;
    transition: max-height 300ms;
    max-height: 4.5rem;
    z-index: 99;
    @include shadow-large;

    @media only screen and (min-device-width: 320px) and (max-device-width: 667px) {
      border-radius: 0;
    }
  }

  .footer-wrap {
    flex-shrink: 0;
    width: 100%;
    display: flex;
    flex-direction: column;
    position: relative;

    &:before {
      content: '';
      position: absolute;
      top: -$space-normal;
      left: 0;
      width: 100%;
      height: $space-normal;
      opacity: 0.1;
      background: linear-gradient(
        to top,
        $color-background,
        rgba($color-background, 0)
      );
    }
  }

  .input-wrap {
    padding: 0 $space-two;
  }
}
</style>
