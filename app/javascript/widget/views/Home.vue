<template>
  <div class="flex flex-1 flex-col justify-end brand-bg">
    <div class="relative flex flex-col">
      <hero-intro
        :title="channelConfig.welcomeTitle"
        :body="channelConfig.welcomeTagline"
        :agents="availableAgents"
        :is-online="isOnline"
        :reply-wait-message="replyWaitMessage"
        @start="startConversation"
      />
      <div class="-mt-4 sticky top-2">
        <article-hero :articles="articles" @search="onSearch" />
      </div>
      <div ref="stickyElement" class="relative h-0 w-full" />
      <div
        ref="chatSheetWrap"
        class="group -mt-8 self-end -bottom-custom w-full sticky"
        :class="{ 'is-collapsed': isCollapsed }"
      >
        <chat-hero
          :is-collapsed="isCollapsed"
          :has-conversation="conversationSize > 0"
          @start="startConversation"
        >
          {{
            agentNamesToDisplay ||
              `We are offline but we will answer once we are back. Can't wait? ask Lisa, our ai bot 🤖 for faster replies.`
          }}
        </chat-hero>
      </div>
    </div>
  </div>
</template>

<script>
import HeroIntro from 'widget/components/HeroIntro';
import ArticleHero from '../components/ArticleHero';
import ChatHero from '../components/ChatHero';

import availabilityMixin from 'widget/mixins/availability';
import nextAvailabilityTime from 'widget/mixins/nextAvailabilityTime';
import configMixin from '../mixins/configMixin';

import { mapGetters } from 'vuex';
import routerMixin from 'widget/mixins/routerMixin';
export default {
  name: 'Home',
  components: {
    HeroIntro,
    ArticleHero,
    ChatHero,
  },
  mixins: [configMixin, routerMixin, availabilityMixin, nextAvailabilityTime],
  props: {
    hasFetched: {
      type: Boolean,
      default: false,
    },
    isCampaignViewClicked: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      isCollapsed: true,
      articles: [
        {
          name: 'How to Troubleshoot Common Product Issues',
          href: '/article1',
        },
        {
          name: 'Guide to Setting Up Your Product',
          href: '/article2',
        },
        {
          name: 'Understanding Error Codes and Resolving Them',
          href: '/article3',
        },
        {
          name: 'Frequently Asked Questions about Product',
          href: '/article4',
        },
        {
          name: 'Optimizing Performance: Tips and Tricks',
          href: '/article5',
        },
        // Add more articles as needed
      ],
    };
  },
  computed: {
    ...mapGetters({
      availableAgents: 'agent/availableAgents',
      activeCampaign: 'campaign/getActiveCampaign',
      conversationSize: 'conversation/getConversationSize',
    }),
    isOnline() {
      const { workingHoursEnabled } = this.channelConfig;
      const anyAgentOnline = this.availableAgents.length > 0;

      if (workingHoursEnabled) {
        return this.isInBetweenTheWorkingHours;
      }
      return anyAgentOnline;
    },
    chatBodyText() {
      if (this.isOnline && this.availableAgents.length > 3) {
        return `Agatha, Hari and ${this.availableAgents.length} others online to answer your questions.`;
      }
      return this.channelConfig.welcomeTagline;
    },
  },
  watch: {
    hasConversation() {
      this.setChatSheetBottom();
    },
  },
  mounted() {
    this.checkMoving();
    this.setChatSheetBottom();
  },
  beforeDestroy() {
    window.removeEventListener('scroll', this.checkMoving);
  },
  methods: {
    startConversation() {
      if (this.preChatFormEnabled && !this.conversationSize) {
        return this.replaceRoute('prechat-form');
      }
      return this.replaceRoute('messages');
    },
    onSearch(query) {},
    checkMoving() {
      const jockeyElement = this.$refs.stickyElement;

      let options = {
        margin: '0 0 100px',
        root: null,
        threshold: 1,
      };

      const callback = entries => {
        entries.forEach(entry => {
          this.isCollapsed = !entry.isIntersecting;
        });
      };

      const observer = new IntersectionObserver(callback, options);
      observer.observe(jockeyElement);
    },
    setChatSheetBottom() {
      const chatSheetWrap = this.$refs.chatSheetWrap;
      const chatHeroHeight = chatSheetWrap.offsetHeight;
      const bottomSpace = this.conversationSize > 0 ? 80 : 64;

      chatSheetWrap.style.bottom = `-${chatHeroHeight - bottomSpace}px`;
    },
  },
};
</script>
<style scoped lang="scss">
.brand-bg {
  background: var(--brand-primary);
}
</style>
