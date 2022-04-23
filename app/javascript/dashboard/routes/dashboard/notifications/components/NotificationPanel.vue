<template>
  <div class="modal-mask">
    <div
      v-on-clickaway="closeNotificationPanel"
      class="notification-wrap flex-space-between"
    >
      <div class="header-wrap w-full flex-space-between">
        <div class="header-title--wrap flex-view">
          <span class="header-title">
            {{ $t('NOTIFICATIONS_PAGE.UNREAD_NOTIFICATION.TITLE') }}
          </span>
          <span v-if="totalUnreadNotifications" class="total-count block-title">
            {{ totalUnreadNotifications }}
          </span>
        </div>
        <div class="flex-view">
          <woot-button
            v-if="!noUnreadNotificationAvailable"
            color-scheme="primary"
            variant="smooth"
            size="tiny"
            class-names="action-button"
            :is-loading="uiFlags.isUpdating"
            @click="onMarkAllDoneClick"
          >
            {{ $t('NOTIFICATIONS_PAGE.MARK_ALL_DONE') }}
          </woot-button>
          <woot-button
            color-scheme="secondary"
            variant="link"
            size="tiny"
            icon="dismiss"
            @click="closeNotificationPanel"
          />
        </div>
      </div>
      <notification-panel-list
        :notifications="getUnreadNotifications"
        :is-loading="uiFlags.isFetching"
        :on-click-notification="openConversation"
        :in-last-page="inLastPage"
      />
      <div v-if="records.length !== 0" class="footer-wrap flex-space-between">
        <div class="flex-view">
          <woot-button
            size="medium"
            variant="clear"
            color-scheme="secondary"
            class-names="page-change--button"
            :is-disabled="inFirstPage"
            @click="onClickFirstPage"
          >
            <fluent-icon icon="chevron-left" size="16" />
            <fluent-icon
              icon="chevron-left"
              size="16"
              class="margin-left-minus-slab"
            />
          </woot-button>
          <woot-button
            color-scheme="secondary"
            variant="clear"
            size="medium"
            icon="chevron-left"
            :disabled="inFirstPage"
            @click="onClickPreviousPage"
          >
          </woot-button>
        </div>
        <span class="page-count"> {{ currentPage }} - {{ lastPage }} </span>
        <div class="flex-view">
          <woot-button
            color-scheme="secondary"
            variant="clear"
            size="medium"
            icon="chevron-right"
            :disabled="inLastPage"
            @click="onClickNextPage"
          >
          </woot-button>
          <woot-button
            size="medium"
            variant="clear"
            color-scheme="secondary"
            class-names="page-change--button"
            :disabled="inLastPage"
            @click="onClickLastPage"
          >
            <fluent-icon icon="chevron-right" size="16" />
            <fluent-icon
              icon="chevron-right"
              size="16"
              class="margin-left-minus-slab"
            />
          </woot-button>
        </div>
      </div>
      <div v-else></div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';

import NotificationPanelList from './NotificationPanelList';

export default {
  components: {
    NotificationPanelList,
  },
  mixins: [clickaway],
  data() {
    return {
      pageSize: 15,
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      meta: 'notifications/getMeta',
      records: 'notifications/getNotifications',
      uiFlags: 'notifications/getUIFlags',
    }),
    totalUnreadNotifications() {
      return this.meta.unreadCount;
    },
    noUnreadNotificationAvailable() {
      return this.meta.unreadCount === 0;
    },
    getUnreadNotifications() {
      return this.records.filter(notification => notification.read_at === null);
    },
    currentPage() {
      return Number(this.meta.currentPage);
    },
    lastPage() {
      if (this.totalUnreadNotifications > 15) {
        return Math.ceil(this.totalUnreadNotifications / this.pageSize);
      }
      return 1;
    },
    inFirstPage() {
      const page = Number(this.meta.currentPage);
      return page === 1;
    },
    inLastPage() {
      return this.currentPage === this.lastPage;
    },
  },
  mounted() {
    this.$store.dispatch('notifications/get', { page: 1 });
  },
  methods: {
    onPageChange(page) {
      this.$store.dispatch('notifications/get', { page });
    },
    openConversation(notification) {
      const {
        primary_actor_id: primaryActorId,
        primary_actor_type: primaryActorType,
        primary_actor: { id: conversationId },
      } = notification;

      this.$store.dispatch('notifications/read', {
        primaryActorId,
        primaryActorType,
        unreadCount: this.meta.unreadCount,
      });
      this.$router.push({
        name: 'inbox_conversation',
        params: { conversation_id: conversationId },
      });
      this.$emit('close');
    },
    onClickNextPage() {
      if (!this.inLastPage) {
        const page = this.currentPage + 1;
        this.onPageChange(page);
      }
    },
    onClickPreviousPage() {
      if (!this.inFirstPage) {
        const page = this.currentPage - 1;
        this.onPageChange(page);
      }
    },
    onClickFirstPage() {
      if (!this.inFirstPage) {
        const page = 1;
        this.onPageChange(page);
      }
    },
    onClickLastPage() {
      if (!this.inLastPage) {
        const page = this.lastPage;
        this.onPageChange(page);
      }
    },
    onMarkAllDoneClick() {
      this.$store.dispatch('notifications/readAll');
    },
    closeNotificationPanel() {
      this.$emit('close');
    },
  },
};
</script>
<style lang="scss" scoped>
.flex-view {
  display: flex;
}

.flex-space-between {
  display: flex;
  justify-content: space-between;
}

.notification-wrap {
  flex-direction: column;
  height: 90vh;
  width: 52rem;
  background-color: var(--white);
  border-radius: var(--border-radius-medium);
  position: absolute;
  left: var(--space-jumbo);
  margin: var(--space-small);
}
.header-wrap {
  flex-direction: row;
  align-items: center;
  border-bottom: 1px solid var(--s-50);
  padding: var(--space-two) var(--space-medium) var(--space-slab)
    var(--space-medium);

  .header-title--wrap {
    align-items: center;
  }

  .header-title {
    font-size: var(--font-size-two);
    font-weight: var(--font-weight-black);
  }

  .total-count {
    padding: var(--space-smaller) var(--space-small);
    background: var(--b-50);
    border-radius: var(--border-radius-rounded);
    font-size: var(--font-size-micro);
    font-weight: var(--font-weight-bold);
  }

  .action-button {
    padding: var(--space-micro) var(--space-small);
    margin-right: var(--space-small);
  }
}

.page-count {
  font-size: var(--font-size-micro);
  font-weight: var(--font-weight-bold);
  color: var(--s-500);
}

.footer-wrap {
  align-items: center;
  padding: var(--space-smaller) var(--space-two);
}

.page-change--button:hover {
  background: var(--s-50);
}
</style>
