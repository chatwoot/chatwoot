<!-- eslint-disable vue/attribute-hyphenation -->
<template>
  <ninja-keys
    ref="ninjakeys"
    :no-auto-load-md-icons="true"
    hideBreadcrumbs
    :placeholder="placeholder"
    @selected="onSelected"
  />
</template>

<script>
import 'ninja-keys';
import conversationHotKeysMixin from './conversationHotKeys';
import inboxHotKeysMixin from './inboxHotKeys';
import goToCommandHotKeys from './goToCommandHotKeys';
import appearanceHotKeys from './appearanceHotKeys';
import agentMixin from 'dashboard/mixins/agentMixin';
import conversationLabelMixin from 'dashboard/mixins/conversation/labelMixin';
import conversationTeamMixin from 'dashboard/mixins/conversation/teamMixin';
import adminMixin from 'dashboard/mixins/isAdmin';
import { GENERAL_EVENTS } from '../../../helper/AnalyticsHelper/events';

export default {
  mixins: [
    adminMixin,
    agentMixin,
    conversationHotKeysMixin,
    inboxHotKeysMixin,
    conversationLabelMixin,
    conversationTeamMixin,
    appearanceHotKeys,
    goToCommandHotKeys,
  ],
  data() {
    return {
      modalObserver: null,
    };
  },
  computed: {
    placeholder() {
      return this.$t('COMMAND_BAR.SEARCH_PLACEHOLDER');
    },
    accountId() {
      return this.$store.getters.getCurrentAccountId;
    },
    routeName() {
      return this.$route.name;
    },
    hotKeys() {
      return [
        ...this.inboxHotKeys,
        ...this.conversationHotKeys,
        ...this.goToCommandHotKeys,
        ...this.goToAppearanceHotKeys,
      ];
    },
  },
  watch: {
    routeName() {
      this.setCommandbarData();
    },
    hotKeys() {
      // This is to update the command bar data when the hot keys are updated dynamically
      this.setCommandbarData();
    },
  },
  mounted() {
    this.setCommandbarData();
    if (this.$route.name === 'inbox_view') {
      this.$nextTick(() => {
        this.setModalObserver();
      });
    }
  },
  beforeDestroy() {
    this.disposeModalObserver();
  },
  methods: {
    setCommandbarData() {
      this.$refs.ninjakeys.data = this.hotKeys;
    },
    onSelected(item) {
      const { detail: { action: { title = null, section = null } = {} } = {} } =
        item;
      this.$track(GENERAL_EVENTS.COMMAND_BAR, {
        section,
        action: title,
      });
      this.setCommandbarData();
    },
    setModalObserver() {
      this.disposeModalObserver();

      const ninjaKeysElement = document.querySelector('ninja-keys');
      if (ninjaKeysElement && ninjaKeysElement.shadowRoot) {
        const modalElement =
          ninjaKeysElement.shadowRoot.querySelector('.modal');
        if (modalElement instanceof HTMLElement) {
          this.createModalObserver(modalElement);
        }
      }
    },
    createModalObserver(modalElement) {
      // Initialize an observer to detect when the command bar modal is closed and opened
      // The ninja-keys component does not emit a close event https://github.com/ssleptsov/ninja-keys?tab=readme-ov-file#events.
      // So by MutationObserver we can detect the modal visibility state by observing DOM changes.
      // By observing changes to the 'class' attribute of the modal element,
      // we can determine the modal's visibility state.

      this.modalObserver = new MutationObserver(mutations => {
        mutations.forEach(mutation => {
          if (mutation.attributeName === 'class') {
            const classList = mutation.target.classList;
            if (!classList.contains('visible')) {
              // Hide snooze notification items from cmd bar
              // The this.showSnoozeNotificationItems is from inboxHotKeysMixin
              this.showSnoozeNotificationItems = false;
            }
          }
        });
      });
      this.modalObserver.observe(modalElement, {
        attributes: true,
        attributeOldValue: true,
        attributeFilter: ['class'],
      });
    },
    disposeModalObserver() {
      if (this.modalObserver) {
        this.modalObserver.disconnect();
        this.modalObserver = null;
      }
    },
  },
};
</script>

<style lang="scss">
ninja-keys {
  --ninja-accent-color: var(--w-500);
  --ninja-font-family: 'PlusJakarta';
  z-index: 9999;
}

// Wrapped with body.dark to avoid overriding the default theme
// If OS is in dark theme and app is in light mode, It will prevent showing dark theme in command bar
body.dark {
  ninja-keys {
    --ninja-overflow-background: rgba(26, 29, 30, 0.5);
    --ninja-modal-background: #151718;
    --ninja-secondary-background-color: #26292b;
    --ninja-selected-background: #26292b;
    --ninja-footer-background: #2b2f31;
    --ninja-text-color: #f8faf9;
    --ninja-icon-color: #f8faf9;
    --ninja-secondary-text-color: #c2c9c6;
  }
}
</style>
