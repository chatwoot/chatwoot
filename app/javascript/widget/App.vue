<script>
import { mapGetters, mapActions } from 'vuex';
import { setHeader } from 'widget/helpers/axios';
import addHours from 'date-fns/addHours';
import { IFrameHelper, RNHelper } from 'widget/helpers/utils';
import configMixin from './mixins/configMixin';
import { getLocale } from './helpers/urlParamsHelper';
import { getLanguageDirection } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import { isEmptyObject } from 'widget/helpers/utils';
import Spinner from 'shared/components/Spinner.vue';
import {
  getExtraSpaceToScroll,
  loadedEventConfig,
} from './helpers/IframeEventHelper';
import {
  ON_AGENT_MESSAGE_RECEIVED,
  ON_CAMPAIGN_MESSAGE_CLICK,
  ON_UNREAD_MESSAGE_CLICK,
} from './constants/widgetBusEvents';
import { useDarkMode } from 'widget/composables/useDarkMode';
import { useRouter } from 'vue-router';
import { useAvailability } from 'widget/composables/useAvailability';
import { SDK_SET_BUBBLE_VISIBILITY } from '../shared/constants/sharedFrameEvents';
import { emitter } from 'shared/helpers/mitt';
import { LocalStorage } from 'shared/helpers/localStorage';
import { loadGA, trackEvent } from 'widget/helpers/analyticsHelper';

const SMS_STORAGE_KEY = 'chatwoot_sms_state';

export default {
  name: 'App',
  components: {
    Spinner,
  },
  mixins: [configMixin],
  setup() {
    const { prefersDarkMode } = useDarkMode();
    const router = useRouter();
    const { isInWorkingHours } = useAvailability();

    return { prefersDarkMode, router, isInWorkingHours };
  },
  data() {
    return {
      isMobile: false,
      campaignsSnoozedTill: undefined,
    };
  },
  computed: {
    ...mapGetters({
      activeCampaign: 'campaign/getActiveCampaign',
      conversationSize: 'conversation/getConversationSize',
      hideMessageBubble: 'appConfig/getHideMessageBubble',
      isFetchingList: 'conversation/getIsFetchingList',
      isRightAligned: 'appConfig/isRightAligned',
      isWidgetOpen: 'appConfig/getIsWidgetOpen',
      messageCount: 'conversation/getMessageCount',
      unreadMessageCount: 'conversation/getUnreadMessageCount',
      isWidgetStyleFlat: 'appConfig/isWidgetStyleFlat',
      showUnreadMessagesDialog: 'appConfig/getShowUnreadMessagesDialog',
    }),
    isIFrame() {
      return IFrameHelper.isIFrame();
    },
    isRNWebView() {
      return RNHelper.isRNWebView();
    },
    isRTL() {
      return this.$root.$i18n.locale
        ? getLanguageDirection(this.$root.$i18n.locale)
        : false;
    },
  },
  watch: {
    activeCampaign() {
      this.setCampaignView();
    },
    // Ensure full-height iframe on SMS pages regardless of unread/campaign events
    $route: {
      immediate: false,
      handler(newRoute) {
        const routeName = newRoute?.name;
        if (['terms-and-conditions', 'sms-form'].includes(routeName)) {
          this.setIframeHeight(false);
        }
      },
    },
    isRTL: {
      immediate: true,
      handler(value) {
        document.documentElement.dir = value ? 'rtl' : 'ltr';
      },
    },
  },
  mounted() {
    const { websiteToken, locale, widgetColor, widgetPosition } =
      window.chatwootWebChannel;
    this.setLocale(locale);
    this.setWidgetColor(widgetColor);
    if (widgetPosition) {
      this.setAppConfig({ position: widgetPosition });
    }
    setHeader(window.authToken);

    const { googleAnalyticsToken } = window.chatwootWebChannel;
    if (googleAnalyticsToken) {
      loadGA(googleAnalyticsToken);
    }

    if (this.isIFrame) {
      this.registerListeners();
      this.sendLoadedEvent();
      // For iframe, check SMS state after config is set (handled in registerListeners)
    } else {
      // For non-iframe, check SMS state after conversations are loaded
      this.fetchOldConversations().then(() => {
        this.checkSmsState();
      });
      this.fetchAvailableAgents(websiteToken);
      this.setLocale(getLocale(window.location.search));
    }
    if (this.isRNWebView) {
      this.registerListeners();
      this.sendRNWebViewLoadedEvent();
    }
    this.$store.dispatch('conversationAttributes/getAttributes');
    this.registerUnreadEvents();
    this.registerCampaignEvents();
  },
  methods: {
    ...mapActions('appConfig', [
      'setAppConfig',
      'setReferrerHost',
      'setWidgetColor',
      'setBubbleVisibility',
      'setColorScheme',
    ]),
    ...mapActions('conversation', ['fetchOldConversations']),
    ...mapActions('campaign', [
      'initCampaigns',
      'executeCampaign',
      'resetCampaign',
    ]),
    ...mapActions('agent', ['fetchAvailableAgents']),
    checkSmsState() {
      // Check if there are conversations (which includes SMS conversations)
      // This works across logout/login because conversations are fetched from server
      const conversationSize =
        this.$store.getters['conversation/getConversationSize'];

      // Check localStorage for SMS state FIRST (before sending has-conversations)
      const storedSmsState = LocalStorage.get(SMS_STORAGE_KEY);
      if (storedSmsState) {
        // Check if state is older than 24 hours, if so clear it
        const oneDayAgo = Date.now() - 24 * 60 * 60 * 1000;
        if (storedSmsState.timestamp && storedSmsState.timestamp < oneDayAgo) {
          LocalStorage.remove(SMS_STORAGE_KEY);
        } else if (storedSmsState.sent) {
          // Set flag BEFORE opening widget to prevent navigation to messages
          if (window.$chatwoot) {
            window.$chatwoot.openingForSms = true;
          }
          // If SMS was sent, navigate to Terms & Conditions page with success state
          // Open widget if it's not already open
          if (!this.isWidgetOpen) {
            this.$store.dispatch('appConfig/toggleWidgetOpen', true);
          }

          // Wait for widget to open, then navigate to Terms & Conditions with success
          this.$nextTick(() => {
            setTimeout(() => {
              this.$router.push({
                name: 'terms-and-conditions',
                query: {
                  phoneNumber: storedSmsState.phoneNumber,
                  message: storedSmsState.message,
                  success: 'true', // Flag to show success message
                },
              });
              // Clear SMS opening flag after navigating to success page
              if (window.$chatwoot) {
                window.$chatwoot.openingForSms = false;
              }
            }, 300);
          });
        } else if (
          !storedSmsState.sent &&
          (storedSmsState.phoneNumber || storedSmsState.message)
        ) {
          // If form was filled but not sent, navigate to SMS form
          // Set flag to prevent navigation to messages
          if (window.$chatwoot) {
            window.$chatwoot.openingForSms = true;
          }
          // Open widget if it's not already open
          if (!this.isWidgetOpen) {
            this.$store.dispatch('appConfig/toggleWidgetOpen', true);
          }

          // Wait for widget to open, then navigate to SMS form
          this.$nextTick(() => {
            setTimeout(() => {
              this.replaceRoute('sms-form');
              // Clear flag after navigation
              if (window.$chatwoot) {
                window.$chatwoot.openingForSms = false;
              }
            }, 300);
          });
        }
      }

      if (this.isIFrame) {
        IFrameHelper.sendMessage('has-conversations', {
          hasConversations: conversationSize > 0,
        });
      }
    },
    scrollConversationToBottom() {
      const container = this.$el.querySelector('.conversation-wrap');
      container.scrollTop = container.scrollHeight;
    },
    setBubbleLabel() {
      IFrameHelper.sendMessage({
        event: 'setBubbleLabel',
        label: this.$t('BUBBLE.LABEL'),
      });
    },
    setIframeHeight(isFixedHeight) {
      this.$nextTick(() => {
        const extraHeight = getExtraSpaceToScroll();
        IFrameHelper.sendMessage({
          event: 'updateIframeHeight',
          isFixedHeight,
          extraHeight,
        });
      });
    },
    setLocale(localeWithVariation) {
      if (!localeWithVariation) return;
      const { enabledLanguages } = window.chatwootWebChannel;
      const localeWithoutVariation = localeWithVariation.split('_')[0];
      const hasLocaleWithoutVariation = enabledLanguages.some(
        lang => lang.iso_639_1_code === localeWithoutVariation
      );
      const hasLocaleWithVariation = enabledLanguages.some(
        lang => lang.iso_639_1_code === localeWithVariation
      );

      if (hasLocaleWithVariation) {
        this.$root.$i18n.locale = localeWithVariation;
      } else if (hasLocaleWithoutVariation) {
        this.$root.$i18n.locale = localeWithoutVariation;
      }
    },
    registerUnreadEvents() {
      emitter.on(ON_AGENT_MESSAGE_RECEIVED, () => {
        const { name: routeName } = this.$route;
        if ((this.isWidgetOpen || !this.isIFrame) && routeName === 'messages') {
          this.$store.dispatch('conversation/setUserLastSeen');
        }
        this.setUnreadView();
      });
      emitter.on(ON_UNREAD_MESSAGE_CLICK, () => {
        this.router
          .replace({ name: 'messages' })
          .then(() => this.unsetUnreadView());
      });
    },
    registerCampaignEvents() {
      emitter.on(ON_CAMPAIGN_MESSAGE_CLICK, () => {
        if (this.shouldShowPreChatForm) {
          this.router.replace({ name: 'prechat-form' });
        } else {
          this.router.replace({ name: 'messages' });
          emitter.emit('execute-campaign', {
            campaignId: this.activeCampaign.id,
          });
        }
        this.unsetUnreadView();
      });
      emitter.on('execute-campaign', campaignDetails => {
        const { customAttributes, campaignId } = campaignDetails;
        const { websiteToken } = window.chatwootWebChannel;
        this.executeCampaign({ campaignId, websiteToken, customAttributes });
        this.router.replace({ name: 'messages' });
      });
      emitter.on('snooze-campaigns', () => {
        const expireBy = addHours(new Date(), 1);
        this.campaignsSnoozedTill = Number(expireBy);
      });
    },
    setCampaignView() {
      const { messageCount, activeCampaign } = this;
      const shouldSnoozeCampaign =
        this.campaignsSnoozedTill && this.campaignsSnoozedTill > Date.now();
      const isCampaignReadyToExecute =
        !isEmptyObject(activeCampaign) &&
        !messageCount &&
        !shouldSnoozeCampaign;
      if (this.isIFrame && isCampaignReadyToExecute) {
        this.router.replace({ name: 'campaigns' }).then(() => {
          this.setIframeHeight(true);
          IFrameHelper.sendMessage({ event: 'setUnreadMode' });
        });
      }
    },
    setUnreadView() {
      // Avoid unread auto-open/routing during SMS flow
      if (window.$chatwoot?.openingForSms) {
        return;
      }
      // Never alter height or route when on SMS-related pages
      const currentRouteName = this.$route?.name;
      if (['terms-and-conditions', 'sms-form'].includes(currentRouteName)) {
        return;
      }
      // Check if there's an active SMS conversation
      // If SMS was sent recently (within 24 hours), don't shrink the widget
      // This prevents widget from minimizing when user is actively using SMS
      const storedSmsState = LocalStorage.get(SMS_STORAGE_KEY);
      if (storedSmsState && storedSmsState.sent) {
        const oneDayAgo = Date.now() - 24 * 60 * 60 * 1000;
        if (storedSmsState.timestamp && storedSmsState.timestamp >= oneDayAgo) {
          // Active SMS conversation exists - only show notification dot, don't shrink widget
          this.handleUnreadNotificationDot();
          return;
        }
      }
      const { unreadMessageCount } = this;
      if (!this.showUnreadMessagesDialog) {
        this.handleUnreadNotificationDot();
      } else if (
        this.isIFrame &&
        unreadMessageCount > 0 &&
        !this.isWidgetOpen
      ) {
        this.router.replace({ name: 'unread-messages' }).then(() => {
          this.setIframeHeight(true);
          IFrameHelper.sendMessage({ event: 'setUnreadMode' });
        });
        this.handleUnreadNotificationDot();
      }
    },
    unsetUnreadView() {
      if (this.isIFrame) {
        IFrameHelper.sendMessage({ event: 'resetUnreadMode' });
        this.setIframeHeight(false);
        this.handleUnreadNotificationDot();
      }
    },
    handleUnreadNotificationDot() {
      const { unreadMessageCount } = this;
      if (this.isIFrame) {
        IFrameHelper.sendMessage({
          event: 'handleNotificationDot',
          unreadMessageCount,
        });
      }
    },
    createWidgetEvents(message) {
      const { eventName } = message;
      const isWidgetTriggerEvent = eventName === 'webwidget.triggered';
      if (
        isWidgetTriggerEvent &&
        ['unread-messages', 'campaigns'].includes(this.$route.name)
      ) {
        return;
      }
      this.$store.dispatch('events/create', { name: eventName });
    },
    registerListeners() {
      const { websiteToken } = window.chatwootWebChannel;
      window.addEventListener('message', e => {
        if (!IFrameHelper.isAValidEvent(e)) {
          return;
        }
        const message = IFrameHelper.getMessage(e);
        if (message.event === 'config-set') {
          this.setLocale(message.locale);
          this.setBubbleLabel();
          this.fetchOldConversations().then(() => {
            this.setUnreadView();
            // Check SMS state after conversations are loaded
            this.checkSmsState();

            // Notify SDK about conversation state after conversations are loaded
            const conversationSize =
              this.$store.getters['conversation/getConversationSize'];
            IFrameHelper.sendMessage('has-conversations', {
              hasConversations: conversationSize > 0,
            });
          });
          this.fetchAvailableAgents(websiteToken);
          this.setAppConfig(message);
          this.$store.dispatch('contacts/get');
          this.setCampaignReadData(message.campaignsSnoozedTill);
        } else if (message.event === 'widget-visible') {
          // Check SMS state when widget becomes visible
          this.checkSmsState();
          this.scrollConversationToBottom();
        } else if (message.event === 'change-url') {
          const { referrerURL, referrerHost } = message;
          this.initCampaigns({
            currentURL: referrerURL,
            websiteToken,
            isInBusinessHours: this.isInWorkingHours,
          });
          window.referrerURL = referrerURL;
          this.setReferrerHost(referrerHost);
        } else if (message.event === 'toggle-close-button') {
          this.isMobile = message.isMobile;
        } else if (message.event === 'push-event') {
          this.createWidgetEvents(message);
        } else if (message.event === 'set-label') {
          this.$store.dispatch('conversationLabels/create', message.label);
        } else if (message.event === 'remove-label') {
          this.$store.dispatch('conversationLabels/destroy', message.label);
        } else if (message.event === 'set-user') {
          this.$store.dispatch('contacts/setUser', message);
        } else if (message.event === 'send-message') {
          // Handle message sent from greeting input box
          if (message.content) {
            const conversationSize =
              this.$store.getters['conversation/getConversationSize'];
            if (conversationSize === 0) {
              // No conversation exists, create one with the message
              this.$store.dispatch('conversation/createConversation', {
                message: message.content,
              });
            } else {
              // Conversation exists, just send the message
              this.$store.dispatch('conversation/sendMessage', {
                content: message.content,
              });
            }
          }
        } else if (message.event === 'show-sms-form') {
          // Handle showing SMS form when "Text Us" is clicked
          // Set flag to prevent default navigation
          if (window.$chatwoot) {
            window.$chatwoot.openingForSms = true;
          }
          // Navigate IMMEDIATELY before opening widget to prevent home page flash
          if (this.$route.name !== 'sms-form') {
            this.$router.replace({ name: 'sms-form' });
          }
          // Ensure widget is open
          if (!this.isWidgetOpen) {
            this.$store.dispatch('appConfig/toggleWidgetOpen', true);
          }
          // Clear flag after a brief delay to ensure navigation completes
          this.$nextTick(() => {
            if (window.$chatwoot) {
              window.$chatwoot.openingForSms = false;
            }
          });
        } else if (message.event === 'set-custom-attributes') {
          this.$store.dispatch(
            'contacts/setCustomAttributes',
            message.customAttributes
          );
        } else if (message.event === 'delete-custom-attribute') {
          this.$store.dispatch(
            'contacts/deleteCustomAttribute',
            message.customAttribute
          );
        } else if (message.event === 'set-conversation-custom-attributes') {
          this.$store.dispatch(
            'conversation/setCustomAttributes',
            message.customAttributes
          );
        } else if (message.event === 'delete-conversation-custom-attribute') {
          this.$store.dispatch(
            'conversation/deleteCustomAttribute',
            message.customAttribute
          );
        } else if (message.event === 'set-locale') {
          this.setLocale(message.locale);
          this.setBubbleLabel();
        } else if (message.event === 'set-color-scheme') {
          this.setColorScheme(message.darkMode);
        } else if (message.event === 'toggle-open') {
          // Check if opening for SMS BEFORE toggling widget state
          const isOpeningForSms = window.$chatwoot?.openingForSms;

          // If opening for SMS, navigate IMMEDIATELY before toggling widget state
          // This prevents any default routing from happening
          if (isOpeningForSms && message.isOpen) {
            // Navigate synchronously before widget state changes
            if (this.$route.name !== 'sms-form') {
              this.$router.replace({ name: 'sms-form' });
            }
          }

          if (message.isOpen) {
            trackEvent('widget_impression');
          }
          this.$store.dispatch('appConfig/toggleWidgetOpen', message.isOpen);

          // Clear flag after navigation (if it was set)
          if (isOpeningForSms && message.isOpen) {
            // Use nextTick to clear flag after navigation completes
            this.$nextTick(() => {
              if (window.$chatwoot) {
                window.$chatwoot.openingForSms = false;
              }
            });
          } else if (!isOpeningForSms) {
            const shouldShowMessageView =
              ['home'].includes(this.$route.name) &&
              message.isOpen &&
              this.messageCount;
            const shouldShowHomeView =
              !message.isOpen &&
              ['unread-messages', 'campaigns'].includes(this.$route.name);

            if (shouldShowMessageView) {
              this.replaceRoute('messages');
            }
            if (shouldShowHomeView) {
              this.$store.dispatch('conversation/setUserLastSeen');
              this.unsetUnreadView();
              this.replaceRoute('home');
            }
          }

          if (!message.isOpen) {
            this.resetCampaign();
          }
        } else if (message.event === SDK_SET_BUBBLE_VISIBILITY) {
          this.setBubbleVisibility(message.hideMessageBubble);
        }
      });
    },
    sendLoadedEvent() {
      IFrameHelper.sendMessage(loadedEventConfig());
    },
    sendRNWebViewLoadedEvent() {
      RNHelper.sendMessage(loadedEventConfig());
    },
    setCampaignReadData(snoozedTill) {
      if (snoozedTill) {
        this.campaignsSnoozedTill = Number(snoozedTill);
      }
    },
  },
};
</script>

<template>
  <div
    v-if="!conversationSize && isFetchingList"
    class="flex items-center justify-center flex-1 h-full bg-n-background"
    :class="{ dark: prefersDarkMode }"
  >
    <Spinner size="" />
  </div>
  <div
    v-else
    class="flex flex-col justify-end h-full"
    :class="{
      'is-mobile': isMobile,
      'is-widget-right': isRightAligned,
      'is-bubble-hidden': hideMessageBubble,
      'is-flat-design': isWidgetStyleFlat,
      dark: prefersDarkMode,
    }"
  >
    <router-view />
  </div>
</template>

<style lang="scss">
@import 'widget/assets/scss/woot.scss';
</style>
