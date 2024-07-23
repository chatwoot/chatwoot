<template>
  <div
    class="flex items-center justify-between w-full py-2 border-b ltr:pl-4 rtl:pl-2 rtl:pr-4 ltr:pr-2 h-14 border-slate-50 dark:border-slate-800/50"
  >
    <div class="flex items-center gap-1.5">
      <h1 class="text-xl font-medium text-slate-900 dark:text-slate-25">
        {{ $t('INBOX.LIST.TITLE') }}
      </h1>
      <div class="relative">
        <div
          role="button"
          class="flex items-center gap-1 px-2 py-1 border rounded-md border-slate-100 dark:border-slate-700/50"
          @click="openInboxDisplayMenu"
        >
          <span
            class="text-xs font-medium text-center text-slate-600 dark:text-slate-200"
          >
            {{ $t('INBOX.LIST.DISPLAY_DROPDOWN') }}
          </span>
          <fluent-icon
            icon="chevron-down"
            size="12"
            class="text-slate-600 dark:text-slate-200"
          />
        </div>
        <inbox-display-menu
          v-if="showInboxDisplayMenu"
          v-on-clickaway="openInboxDisplayMenu"
          class="absolute top-9 ltr:left-0 rtl:right-0"
          @filter="onFilterChange"
        />
      </div>
    </div>
    <div class="relative flex items-center gap-1">
      <!-- <woot-button
        variant="clear"
        size="small"
        color-scheme="secondary"
        icon="filter"
        @click="openInboxFilter"
      /> -->
      <woot-button
        variant="clear"
        size="small"
        color-scheme="secondary"
        icon="mail-inbox"
        @click="openInboxOptionsMenu"
      />
      <inbox-option-menu
        v-if="showInboxOptionMenu"
        v-on-clickaway="openInboxOptionsMenu"
        class="absolute top-9 ltr:right-0 ltr:md:right-[unset] rtl:left-0 rtl:md:left-[unset]"
        @option-click="onInboxOptionMenuClick"
      />
    </div>
  </div>
</template>

<script>
import { useAlert } from 'dashboard/composables';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import InboxOptionMenu from './InboxOptionMenu.vue';
import InboxDisplayMenu from './InboxDisplayMenu.vue';

export default {
  components: {
    InboxOptionMenu,
    InboxDisplayMenu,
  },
  props: {
    isContextMenuOpen: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      showInboxDisplayMenu: false,
      showInboxOptionMenu: false,
    };
  },
  watch: {
    isContextMenuOpen: {
      handler(val) {
        if (val) {
          this.showInboxDisplayMenu = false;
          this.showInboxOptionMenu = false;
        }
      },
      immediate: true,
    },
  },
  methods: {
    markAllRead() {
      this.$track(INBOX_EVENTS.MARK_ALL_NOTIFICATIONS_AS_READ);
      this.$store.dispatch('notifications/readAll').then(() => {
        useAlert(this.$t('INBOX.ALERTS.MARK_ALL_READ'));
      });
    },
    deleteAll() {
      this.$store.dispatch('notifications/deleteAll').then(() => {
        useAlert(this.$t('INBOX.ALERTS.DELETE_ALL'));
      });
    },
    deleteAllRead() {
      this.$store.dispatch('notifications/deleteAllRead').then(() => {
        useAlert(this.$t('INBOX.ALERTS.DELETE_ALL_READ'));
      });
    },
    openInboxDisplayMenu() {
      this.showInboxDisplayMenu = !this.showInboxDisplayMenu;
    },
    openInboxOptionsMenu() {
      this.showInboxOptionMenu = !this.showInboxOptionMenu;
    },
    onInboxOptionMenuClick(key) {
      const actions = {
        mark_all_read: () => this.markAllRead(),
        delete_all: () => this.deleteAll(),
        delete_all_read: () => this.deleteAllRead(),
      };
      const action = actions[key];
      if (action) action();
      this.$emit('redirect');
    },
    onFilterChange(option) {
      this.$emit('filter', option);
      this.showInboxDisplayMenu = false;
      this.$emit('redirect');
    },
  },
};
</script>

<style></style>
