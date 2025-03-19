<template>
  <div
    class="rounded-md w-full flex flex-1 flex-col justify-center items-center pt-4 gap-2"
    :class="{ 'pb-2': showArticles, 'justify-end': !showArticles }"
  >
    <div
      v-if="
        channelConfig &&
        channelConfig.faqs &&
        JSON.parse(channelConfig.faqs.length) > 0
      "
      class="faq-card h-['fit-content'] max-h-[180px] overflow-y-auto bg-white rounded-lg flex flex-col w-[95%] p-2.5 mt-6 shadow-md"
    >
      <h2 class="mb-2 text-[14px] font-medium">FAQs</h2>
      <div
        v-for="(faq, index) in JSON.parse(channelConfig.faqs)"
        :key="index"
        class="faq-card-main w-full flex flex-col gap-1"
      >
        <div
          v-if="index !== 0"
          style="border-top: 1px solid #e0e0e0; margin-top: 2px"
        />
        <div
          role="button"
          class="p-2.5 w-full flex justify-between items-center cursor-pointer"
          @click="handleFaqClick(faq)"
        >
          <h3 class="m-0 text-[12px] text-gray-800 font-medium">
            {{ faq.question }}
          </h3>
          <fluent-icon icon="chevron-right" size="14" />
        </div>
      </div>
    </div>
    <form
      class="h-[fit-content] bg-white rounded-lg flex flex-col w-[95%] p-4 shadow-[0px_2px_10px_rgba(0,0,0,0.1)] gap-2.5"
      @submit.prevent="handleAskQuestion"
    >
      <h2 class="text-[14px] font-medium">Ask a question</h2>
      <form
        class="flex flex-row justify-between items-center"
        @submit.prevent="handleMessageInput"
      >
        <input
          v-model="question"
          class="border border-[#D9D9D9] p-2 w-[85%] m-0 rounded-md font-[12px]"
          type="text"
          placeholder="Ask a question"
        />
        <button
          type="submit"
          class="m-0 bg-[#F0F0F0] shadow-[0px_1.25px_0px_rgba(0,0,0,0.05)] p-2 rounded-md"
        >
          <img src="~dashboard/assets/images/send-icon.svg" alt="send" />
        </button>
      </form>
    </form>
    <!-- <div class="px-4 pt-4 w-full">
      <team-availability
        :available-agents="availableAgents"
        :has-conversation="!!conversationSize"
        :unread-count="unreadMessageCount"
        @start-conversation="startConversation"
      />
    </div> -->
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import darkModeMixin from 'widget/mixins/darkModeMixin';
import routerMixin from 'widget/mixins/routerMixin';
import configMixin from 'widget/mixins/configMixin';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { mapActions } from 'vuex';

export default {
  name: 'Home',
  components: {
    FluentIcon,
  },
  mixins: [configMixin, routerMixin, darkModeMixin],
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
      question: '',
    };
  },
  computed: {
    ...mapGetters({
      availableAgents: 'agent/availableAgents',
      activeCampaign: 'campaign/getActiveCampaign',
      conversationSize: 'conversation/getConversationSize',
      unreadMessageCount: 'conversation/getUnreadMessageCount',
      popularArticles: 'article/popularArticles',
      articleUiFlags: 'article/uiFlags',
    }),
    widgetLocale() {
      return this.$i18n.locale || 'en';
    },
    portal() {
      return window.chatwootWebChannel.portal;
    },
    showArticles() {
      return (
        this.portal &&
        !this.articleUiFlags.isFetching &&
        this.popularArticles.length
      );
    },
    defaultLocale() {
      const widgetLocale = this.widgetLocale;
      const { allowed_locales: allowedLocales, default_locale: defaultLocale } =
        this.portal.config;

      // IMPORTANT: Variation strict locale matching, Follow iso_639_1_code
      // If the exact match of a locale is available in the list of portal locales, return it
      // Else return the default locale. Eg: `es` will not work if `es_ES` is available in the list
      if (allowedLocales.includes(widgetLocale)) {
        return widgetLocale;
      }
      return defaultLocale;
    },
  },
  mounted() {
    if (this.portal && this.popularArticles.length === 0) {
      const locale = this.defaultLocale;
      this.$store.dispatch('article/fetch', {
        slug: this.portal.slug,
        locale,
      });
    }
  },
  methods: {
    ...mapActions('conversation', ['sendMessage']),
    ...mapActions('conversationAttributes', ['getAttributes']),
    handleMessage(message) {
      this.sendMessage({
        content: message,
      });
      if (this.conversationSize === 0) {
        this.getAttributes();
      }
      return this.replaceRoute('messages');
    },
    handleFaqClick(faq) {
      this.handleMessage(faq.question);
    },
    handleMessageInput() {
      this.handleMessage(this.question);
    },
    startConversation() {
      if (this.preChatFormEnabled && !this.conversationSize) {
        return this.replaceRoute('prechat-form');
      }
      return this.replaceRoute('messages');
    },
    openArticleInArticleViewer(link) {
      let linkToOpen = `${link}?show_plain_layout=true`;
      const isDark = this.prefersDarkMode;
      if (isDark) {
        linkToOpen = `${linkToOpen}&theme=dark`;
      }
      this.$router.push({
        name: 'article-viewer',
        params: { link: linkToOpen },
      });
    },
    handleAskQuestion() {
      this.$router.push({
        name: 'messages',
        query: {
          question: this.question,
        },
      });
    },
    viewAllArticles() {
      const locale = this.defaultLocale;
      const {
        portal: { slug },
      } = window.chatwootWebChannel;
      this.openArticleInArticleViewer(`/hc/${slug}/${locale}`);
    },
  },
};
</script>
