<template>
  <div
    class="rounded-md w-full flex flex-1 flex-col items-center gap-4 px-4 z-10"
    :class="{ 'pb-2': showArticles }"
    :style="`--widget-color: ${widgetColor}; --text-color: ${textColor};`"
  >
    <div
      v-if="
        channelConfig &&
        channelConfig.faqs &&
        JSON.parse(channelConfig.faqs.length) > 0
      "
      :style="{
        boxShadow: '0px 2px 8px 0px #00000014, 0px 0px 2px 0px #00000029',
      }"
      class="faq-card h-['fit-content'] max-h-[180px] overflow-y-auto bg-white rounded-lg flex flex-col w-full p-4 pb-2 mt-14 mb-[0.5rem] shadow-md"
    >
      <h2 class="mb-2 text-[14px] font-medium">FAQs</h2>
      <div
        v-for="(faq, index) in JSON.parse(channelConfig.faqs)"
        :key="index"
        class="faq-card-main w-full flex flex-col justify-center hover:bg-[#F0F0F0] group hover:rounded-lg"
        :class="{ 'border-t border-solid border-[#e0e0e0]': index !== 0 }"
      >
        <div
          role="button"
          class="p-2 w-full flex justify-between items-center relative"
          @click="handleFaqClick(faq, index + 1)"
        >
          <h3 class="m-0 text-[12px] text-gray-800 font-medium">
            {{ faq.question }}
          </h3>
          <div
            v-if="isFAQLoading.index === index + 1 && isFAQLoading.loading"
            style="backdrop-filter: blur(2px)"
            class="absolute w-full h-full flex justify-center items-center"
          >
            <spinner size="medium" :color-scheme="'primary'" />
          </div>
          <fluent-icon icon="chevron-right" size="14" />
        </div>
      </div>
    </div>
    <form
      class="h-[fit-content] bg-white rounded-lg flex flex-col w-full p-4 gap-2"
      :style="{
        boxShadow: '0px 2px 8px 0px #00000014, 0px 0px 2px 0px #00000029',
      }"
      @submit.prevent="handleAskQuestion"
    >
      <h2 class="text-[14px] font-medium">{{ askQuestionText }}</h2>
      <form
        v-if="!messageCount"
        class="flex flex-row justify-between items-center"
        @submit.prevent="handleMessageInput"
      >
        <input
          v-model="question"
          class="border border-solid border-[#D9D9D9] py-2.5 px-4 w-[85%] m-0 rounded-md text-xs message-input focus-visible:outline-none"
          type="text"
          :placeholder="askQuestionText"
        />
        <button
          type="submit"
          class="m-0 bg-[#F0F0F0] shadow-[0px_1.25px_0px_rgba(0,0,0,0.05)] p-2 rounded-md ask-question transition-all duration-300"
        >
          <fluent-icon
            icon="chevron-right"
            :style="'color: #808080'"
            class="icon-color"
          />
        </button>
      </form>
      <div v-else class="flex flex-col gap-2">
        <div class="flex flex-col px-2">
          <div class="text-xs text-[#8C8C8C] text-left flex gap-1.5">
            Sent at {{ readableTimeStamp(lastMessage) }}
            <span
              v-if="isSentByBot && showAiMessageIndicators"
              class="flex items-center gap-1.5"
            >
              <span class="w-1 h-1 bg-[#999999] rounded-full" />
              Answered by AI ✨
            </span>
          </div>
          <div class="text-sm truncate max-w-full">
            {{ lastMessage.content }}
          </div>
        </div>
        <button
          class="bg-[#1A1A1A] text-white flex justify-center items-center gap-2 text-xs py-2 px-3 shadow-[0px_1.25px_0px_rgba(0,0,0,0.05)] rounded-md transition-all duration-300 continue-to-chat"
          @click.prevent="redirectToChat"
        >
          Continue to Chat
          <fluent-icon
            size="14"
            icon="chevron-right"
            :style="'color: white'"
            class="icon-color"
          />
        </button>
      </div>
    </form>
    <div
      v-if="channelConfig.chatOnWhatsappSettings.enabled"
      role="button"
      class="bg-white rounded-lg max-w-full p-3 overflow-hidden cursor-pointer w-full hover:bg-[#F0F0F0]"
      :style="{
        boxShadow: '0px 2px 8px 0px #00000014, 0px 0px 2px 0px #00000029',
      }"
      @click="handleRedirectToWhatsapp"
    >
      <div class="flex items-center gap-2 relative">
        <!-- <div
          v-if="isHandleRedirectToWhatsapp"
          style="backdrop-filter: blur(2px)"
          class="absolute w-full h-full flex justify-center items-center"
        >
          <spinner size="medium" :color-scheme="'primary'" />
        </div> -->
        <img
          class="w-8 h-8"
          src="~dashboard/assets/images/WA_icon.svg"
          alt="Whatsapp Icon"
        />
        <p class="text-[14px] font-medium mr-auto">
          {{ channelConfig.chatOnWhatsappSettings.button_text }}
        </p>
        <spinner
          v-if="isHandleRedirectToWhatsapp"
          size="medium"
          :color-scheme="'primary'"
        />
        <fluent-icon
          v-else
          icon="chevron-right"
          size="14"
          class="text-slate-900 dark:text-slate-50 mr-2"
        />
      </div>
    </div>
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
import timeMixin from 'dashboard/mixins/time';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { mapActions } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import Spinner from 'shared/components/Spinner.vue';
import ContactsAPI from '../api/contacts';

export default {
  name: 'Home',
  components: {
    FluentIcon,
    Spinner,
  },
  mixins: [configMixin, routerMixin, darkModeMixin, timeMixin],
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
      isFAQLoading: {},
      isHandleRedirectToWhatsapp: false,
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
      widgetColor: 'appConfig/getWidgetColor',
      messageCount: 'conversation/getMessageCount',
      lastMessage: 'conversation/getLastMessage',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    isLastMessageCSATAndIsSubmitted() {
      return {
        isCAST: this.lastMessage.content_type === 'input_csat',
        isSubmitted:
          this.lastMessage.content_attributes?.submitted_values
            ?.csat_survey_response?.rating,
      };
    },
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
    isSentByBot() {
      return this.lastMessage?.sender?.name
        ?.toLowerCase()
        .includes('bitespeed');
    },
    askQuestionText() {
      return (
        this.channelConfig?.widgetTextSettings?.ask_question_text ||
        'Ask a question'
      );
    },
    showAiMessageIndicators() {
      return this.channelConfig?.aiMessageSettings?.show_indicators ?? true;
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
    ...mapActions('conversation', ['sendMessage', 'createNewConversation']),
    ...mapActions('conversationAttributes', ['getAttributes']),
    readableTimeStamp(message) {
      const { created_at: createdAt = '' } = message;
      return this.messageStamp(createdAt);
    },
    handleMessage(message) {
      if (message.trim() !== '') {
        this.sendMessage({
          content: message,
        });
        if (this.conversationSize === 0) {
          this.getAttributes();
        }
        return this.replaceRoute('messages');
      }
      return '';
    },
    redirectToChat() {
      return this.replaceRoute('messages');
    },
    async handleFaqClick(faq, index) {
      this.isFAQLoading = {
        index,
        loading: true,
      };
      try {
        const { isCAST, isSubmitted } = this.isLastMessageCSATAndIsSubmitted;
        if (isCAST && isSubmitted) {
          await this.createNewConversation(faq.question);
          if (this.conversationSize === 0) {
            this.getAttributes();
          }
          this.replaceRoute('messages');
        } else if (isCAST && !isSubmitted) {
          this.replaceRoute('messages');
        } else {
          this.handleMessage(faq.question);
        }
      } catch (error) {
        // eslint-disable-next-line no-console
        console.error(error);
      } finally {
        this.isFAQLoading = {
          index,
          loading: false,
        };
      }
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
      if (this.question.trim() !== '') {
        this.$router.push({
          name: 'messages',
          query: {
            question: this.question,
          },
        });
      }
    },
    viewAllArticles() {
      const locale = this.defaultLocale;
      const {
        portal: { slug },
      } = window.chatwootWebChannel;
      this.openArticleInArticleViewer(`/hc/${slug}/${locale}`);
    },
    async handleRedirectToWhatsapp() {
      this.isHandleRedirectToWhatsapp = true;
      try {
        const data = await ContactsAPI.getWhatsappWidgetUrl();
        if (data.data?.whatsappUrl) {
          window.open(data.data?.whatsappUrl, '_blank');
        }
      } catch (error) {
        // eslint-disable-next-line no-console
        console.log(error);
      } finally {
        this.isHandleRedirectToWhatsapp = false;
      }
    },
  },
};
</script>

<style scoped>
.ask-question:hover {
  background-color: var(--widget-color);
}

.message-input {
  transition: border 0.3s;
}

.message-input:hover,
.message-input:focus-visible {
  border: 1px solid var(--widget-color);
}

.ask-question:hover svg {
  color: var(--text-color) !important;
}

.continue-to-chat:hover {
  background-color: var(--widget-color);
  color: var(--text-color) !important;
}

.continue-to-chat:hover svg {
  color: var(--text-color) !important;
}
.faq-card-main:hover {
  color: var(--text-color) !important;
  background: var(--widget-color) !important;
  border-color: transparent !important;
}
.faq-card-main {
  transition:
    background 0.3s,
    color 0.3s;
}
.faq-card-main:hover + .faq-card-main {
  border-color: transparent;
}
</style>
