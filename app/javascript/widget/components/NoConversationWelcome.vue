<script>
import { mapGetters, mapActions } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import GroupedAvatars from 'widget/components/GroupedAvatars.vue';
import configMixin from 'widget/mixins/configMixin';
import routerMixin from 'widget/mixins/routerMixin';

export default {
  name: 'NoConversationWelcome',
  components: {
    GroupedAvatars,
  },
  mixins: [configMixin, routerMixin],
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
      availableAgents: 'agent/availableAgents',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    promotionalMessage() {
      return (
        this.channelConfig.greetingMessage ||
        this.channelConfig.greeting_message ||
        this.$t('NO_CONVERSATION_WELCOME.DEFAULT_MESSAGE')
      );
    },
    dealerName() {
      return (
        this.channelConfig.dealerName || this.channelConfig.websiteName || ''
      );
    },
    // Show channel avatar if no agents available
    channelAvatarUrl() {
      return this.channelConfig.avatarUrl || '';
    },
    channelAvatarName() {
      return (
        this.channelConfig.avatarName || this.channelConfig.websiteName || ''
      );
    },
    shouldShowAvatars() {
      return this.availableAgents && this.availableAgents.length > 0;
    },
    // Default avatar paths
    defaultAvatars() {
      return [
        '/assets/images/default-avatars/default-avatar-1.jpeg',
        '/assets/images/default-avatars/default-avatar-2.jpeg',
        '/assets/images/default-avatars/default-avatar-3.jpeg',
      ];
    },
    // Always return exactly 3 avatars for display
    displayAvatars() {
      const avatarsToShow = [];
      const agents = this.availableAgents || [];
      const defaultAvatars = this.defaultAvatars;

      // If we have agents, show them (up to 3)
      if (agents.length > 0) {
        const agentsToShow = agents.slice(0, 3);
        avatarsToShow.push(...agentsToShow);

        // Fill remaining slots with default avatars if needed
        if (avatarsToShow.length < 3) {
          const remaining = 3 - avatarsToShow.length;
          for (let i = 0; i < remaining; i += 1) {
            avatarsToShow.push({
              id: `default-avatar-${avatarsToShow.length + 1}`,
              name: 'Agent',
              avatar_url: defaultAvatars[avatarsToShow.length],
            });
          }
        }
      } else {
        // No agents available, show all 3 default avatars
        for (let i = 0; i < 3; i += 1) {
          avatarsToShow.push({
            id: `default-avatar-${i + 1}`,
            name: 'Agent',
            avatar_url: defaultAvatars[i],
          });
        }
      }

      return avatarsToShow.slice(0, 3);
    },
  },
  mounted() {
    // Fetch agents if not already fetched
    const { websiteToken } = window.chatwootWebChannel;
    if (
      websiteToken &&
      (!this.availableAgents || this.availableAgents.length === 0)
    ) {
      this.fetchAvailableAgents(websiteToken);
    }
  },
  methods: {
    ...mapActions('agent', ['fetchAvailableAgents']),
  },
};
</script>

<template>
  <div class="flex flex-col flex-1 overflow-auto px-4 py-6">
    <div
      class="flex flex-col gap-4 max-w-full items-center justify-center flex-1"
    >
      <!-- Avatars Section - Centered (Always 3 avatars) -->
      <div class="flex justify-center">
        <GroupedAvatars :users="displayAvatars" :limit="3" />
      </div>

      <!-- Promotional Message - Centered -->
      <div class="text-center">
        <p
          v-dompurify-html="promotionalMessage"
          class="text-lg font-medium text-n-slate-12 leading-relaxed"
        />
      </div>
    </div>
  </div>
</template>
