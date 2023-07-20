<template>
  <div class="flex flex-col brand-bg relative flex-1">
    <elevated-sheet
      is-collapsed
      class="flex flex-col absolute top-0 flex-1 h-custom w-full z-10"
    >
      <div class="flex flex-col h-full py-4 flex-1 bg-white">
        <chat-header
          :title="channelConfig.websiteName"
          :avatar-url="channelConfig.avatarUrl"
          :show-popout-button="appConfig.showPopoutButton"
          :available-agents="availableAgents"
          @back="onBackButtonClick"
        />
        <conversation-wrap :grouped-messages="groupedMessages" />
        <chat-footer />
      </div>
    </elevated-sheet>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import ChatHeader from '../components/ChatHeader.vue';
import ChatFooter from '../components/ChatFooter.vue';
import ConversationWrap from '../components/ConversationWrap.vue';

import routerMixin from 'widget/mixins/routerMixin';
import availabilityMixin from 'widget/mixins/availability';
import nextAvailabilityTime from 'widget/mixins/nextAvailabilityTime';
import configMixin from '../mixins/configMixin';
import darkMixin from 'widget/mixins/darkModeMixin.js';
import ElevatedSheet from '../components/ElevatedSheet.vue';

export default {
  components: {
    ChatFooter,
    ConversationWrap,
    ChatHeader,
    ElevatedSheet,
  },
  mixins: [
    configMixin,
    availabilityMixin,
    nextAvailabilityTime,
    darkMixin,
    routerMixin,
  ],
  computed: {
    ...mapGetters({
      groupedMessages: 'conversation/getGroupedConversation',
      availableAgents: 'agent/availableAgents',
      appConfig: 'appConfig/getAppConfig',
    }),
  },
  mounted() {
    this.$store.dispatch('conversation/setUserLastSeen');
  },
  methods: {
    onBackButtonClick() {
      this.replaceRoute('home');
    },
  },
};
</script>
<style scoped lang="scss">
.brand-bg {
  background: var(--brand-primary);
}

.h-custom {
  /* Height of container minus peek a boo height enough to show bottom branding ; */
  height: calc(100% - 0.5rem);
}
</style>
