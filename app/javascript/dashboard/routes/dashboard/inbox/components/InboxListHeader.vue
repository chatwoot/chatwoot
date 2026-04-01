<script>
import { useAlert, useTrack } from 'dashboard/composables';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import NextButton from 'dashboard/components-next/button/Button.vue';
import InboxOptionMenu from './InboxOptionMenu.vue';
import InboxDisplayMenu from './InboxDisplayMenu.vue';

export default {
  components: {
    NextButton,
    InboxOptionMenu,
    InboxDisplayMenu,
  },
  props: {
    isContextMenuOpen: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['redirect', 'filter'],
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
      useTrack(INBOX_EVENTS.MARK_ALL_NOTIFICATIONS_AS_READ);
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

<template>
  <div
    class="flex w-full flex-col gap-3 border-b border-outline-variant/10 px-3 pb-3 pt-4"
  >
    <div class="min-w-0 space-y-1">
      <span
        class="block text-[11px] font-semibold uppercase tracking-widest text-secondary"
      >
        {{ $t('INBOX.LIST.SECTION_EYEBROW') }}
      </span>
      <p class="mb-0 text-xs leading-snug text-on-primary-container">
        {{ $t('INBOX.LIST.NOTE') }}
      </p>
    </div>
    <div class="flex h-10 items-center justify-between gap-1">
      <div class="flex min-w-0 flex-1 items-center gap-2">
        <h1
          class="min-w-0 truncate text-lg font-bold tracking-tight text-on-surface"
        >
          {{ $t('INBOX.LIST.TITLE') }}
        </h1>
        <div class="relative shrink-0">
          <NextButton
            :label="$t('INBOX.LIST.DISPLAY_DROPDOWN')"
            icon="i-lucide-chevron-down"
            trailing-icon
            slate
            xs
            faded
            @click="openInboxDisplayMenu"
          />
          <InboxDisplayMenu
            v-if="showInboxDisplayMenu"
            v-on-clickaway="openInboxDisplayMenu"
            class="absolute top-full mt-1 ltr:left-0 rtl:right-0"
            @filter="onFilterChange"
          />
        </div>
      </div>
      <div class="relative flex shrink-0 items-center gap-1">
        <NextButton
          icon="i-lucide-sliders-vertical"
          slate
          xs
          faded
          @click="openInboxOptionsMenu"
        />
        <InboxOptionMenu
          v-if="showInboxOptionMenu"
          v-on-clickaway="openInboxOptionsMenu"
          class="absolute top-full mt-1 ltr:right-0 ltr:lg:right-[unset] rtl:left-0 rtl:lg:left-[unset]"
          @option-click="onInboxOptionMenuClick"
        />
      </div>
    </div>
  </div>
</template>
