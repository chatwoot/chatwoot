<template>
  <div
    class="flex w-full ltr:pl-4 rtl:pl-2 rtl:pr-4 ltr:pr-2 py-2 h-14 justify-between items-center border-b border-slate-50 dark:border-slate-800/50"
  >
    <div class="flex items-center gap-1.5">
      <h1 class="font-medium text-slate-900 dark:text-slate-25 text-xl">
        {{ $t('INBOX.LIST.TITLE') }}
      </h1>
      <div class="relative">
        <div
          role="button"
          class="flex gap-1 items-center py-1 px-2 border border-slate-100 dark:border-slate-700/50 rounded-md"
          @click="openInboxDisplayMenu"
        >
          <span
            class="text-slate-600 dark:text-slate-200 text-xs text-center font-medium"
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
    <div class="flex relative gap-1 items-center">
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
import { mixin as clickaway } from 'vue-clickaway';
import InboxOptionMenu from './InboxOptionMenu.vue';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import InboxDisplayMenu from './InboxDisplayMenu.vue';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    InboxOptionMenu,
    InboxDisplayMenu,
  },
  mixins: [clickaway, alertMixin],
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
        this.showAlert(this.$t('INBOX.ALERTS.MARK_ALL_READ'));
      });
    },
    deleteAll() {
      this.$store.dispatch('notifications/deleteAll').then(() => {
        this.showAlert(this.$t('INBOX.ALERTS.DELETE_ALL'));
      });
    },
    deleteAllRead() {
      this.$store.dispatch('notifications/deleteAllRead').then(() => {
        this.showAlert(this.$t('INBOX.ALERTS.DELETE_ALL_READ'));
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
