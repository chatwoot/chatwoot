<script>
import '@chatwoot/ninja-keys';
import wootConstants from 'dashboard/constants/globals';
import conversationHotKeysMixin from './conversationHotKeys';
import bulkActionsHotKeysMixin from './bulkActionsHotKeys';
import inboxHotKeysMixin from './inboxHotKeys';
import goToCommandHotKeys from './goToCommandHotKeys';
import appearanceHotKeys from './appearanceHotKeys';
import agentMixin from 'dashboard/mixins/agentMixin';
import conversationLabelMixin from 'dashboard/mixins/conversation/labelMixin';
import conversationTeamMixin from 'dashboard/mixins/conversation/teamMixin';
import { GENERAL_EVENTS } from '../../../helper/AnalyticsHelper/events';

export default {
  mixins: [
    agentMixin,
    conversationHotKeysMixin,
    bulkActionsHotKeysMixin,
    inboxHotKeysMixin,
    conversationLabelMixin,
    conversationTeamMixin,
    appearanceHotKeys,
    goToCommandHotKeys,
  ],
  data() {
    return {
      // Added selectedSnoozeType to track the selected snooze type
      // So if the selected snooze type is "custom snooze" then we set selectedSnoozeType with the CMD action id
      // So that we can track the selected snooze type and when we close the command bar
      selectedSnoozeType: null,
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
        ...this.bulkActionsHotKeys,
        ...this.goToCommandHotKeys,
        ...this.goToAppearanceHotKeys,
      ];
    },
  },
  watch: {
    routeName() {
      this.setCommandbarData();
    },
  },
  mounted() {
    this.setCommandbarData();
  },
  methods: {
    setCommandbarData() {
      this.$refs.ninjakeys.data = this.hotKeys;
    },
    onSelected(item) {
      const {
        detail: {
          action: { title = null, section = null, id = null } = {},
        } = {},
      } = item;
      // Added this condition to prevent setting the selectedSnoozeType to null
      // When we select the "custom snooze" (CMD bar will close and the custom snooze modal will open)
      if (id === wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME) {
        this.selectedSnoozeType =
          wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME;
      } else {
        this.selectedSnoozeType = null;
      }
      this.$track(GENERAL_EVENTS.COMMAND_BAR, {
        section,
        action: title,
      });
      this.setCommandbarData();
    },
    onClosed() {
      // If the selectedSnoozeType is not "SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME (custom snooze)" then we set the context menu chat id to null
      // Else we do nothing and its handled in the ChatList.vue hideCustomSnoozeModal() method
      if (
        this.selectedSnoozeType !==
        wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME
      ) {
        this.$store.dispatch('setContextMenuChatId', null);
      }
    },
  },
};
</script>

<!-- eslint-disable vue/attribute-hyphenation -->
<template>
  <ninja-keys
    ref="ninjakeys"
    noAutoLoadMdIcons
    hideBreadcrumbs
    :placeholder="placeholder"
    @selected="onSelected"
    @closed="onClosed"
  />
</template>

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
