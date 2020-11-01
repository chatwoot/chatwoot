import { BUS_EVENTS } from 'shared/constants/busEvents';

export default {
  events: {
    'config-set': this.onConfigSet,
    'widget-visible': this.onWidgetVisible,
    'set-current-url': this.onSetCurrentUrl,
    'toggle-close-button': this.onToggleCloseButton,
    'push-event': this.onPushEvent,
    'set-user': this.onSetUser,
    'set-custom-attributes': this.onSetCustomAttributes,
    'delete-custom-attribute': this.onDeleteCustomAttributes,
    'set-locale': this.onSetLocale,
    'set-unread-view': this.onSetUnreadView,
    'unset-unread-view': this.onUnsetUnreadView,
  },
  methods: {
    executeEvent(message) {
      const { event } = message;
      if (this[event] && typeof this[event] === 'function') {
        this[event](message);
      }
    },
    onConfigSet(message) {
      this.setLocale(message.locale);
      this.setBubbleLabel();
      this.setPosition(message.position);
      this.fetchOldConversations().then(() => this.setUnreadView());
      this.setPopoutDisplay(message.showPopoutButton);
      this.setHideMessageBubble(message.hideMessageBubble);
    },
    onWidgetVisible() {
      this.scrollConversationToBottom();
    },
    onSetCurrentUrl(message) {
      window.referrerURL = message.referrerURL;
      bus.$emit(BUS_EVENTS.SET_REFERRER_HOST, message.referrerHost);
    },
    onToggleCloseButton(message) {
      this.isMobile = message.showClose;
    },
    onPushEvent(message) {
      this.createWidgetEvents(message);
    },
    onSetUser(message) {
      this.$store.dispatch('contacts/update', message);
    },
    onSetCustomAttributes(message) {
      this.$store.dispatch(
        'contacts/setCustomAttributes',
        message.customAttributes
      );
    },
    onDeleteCustomAttributes(message) {
      this.$store.dispatch('contacts/setCustomAttributes', {
        [message.customAttribute]: null,
      });
    },
    onSetLocale(message) {
      this.setLocale(message.locale);
      this.setBubbleLabel();
    },
    onSetUnreadView() {
      this.showUnreadView = true;
    },
    onUnsetUnreadView() {
      this.showUnreadView = false;
    },
  },
};
