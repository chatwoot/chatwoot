<template>
  <div class="modal-mask">
    <div v-on-clickaway="closeNotificationCentre" class="notification-wrap">
      <div class="header-wrap">
        <div class="header-title--wrap">
          <span class="header-title">Notifications</span>
          <span v-if="totalNotifications" class="total-count">
            {{ totalNotifications }}
          </span>
        </div>
        <div class="header-action--button">
          <woot-button
            color-scheme="primary"
            variant="smooth"
            size="tiny"
            class-names="action-button"
            :is-loading="uiFlags.isUpdating"
            @click="onMarkAllDoneClick"
          >
            Mark All Done
          </woot-button>
          <woot-button
            color-scheme="secondary"
            variant="link"
            size="tiny"
            icon="dismiss"
            @click="closeNotificationCentre"
          />
        </div>
      </div>
      <notification-centre-list-items
        :notifications="records"
        :is-loading="uiFlags.isFetching"
        :on-click-notification="openConversation"
      />
      <div v-if="records.length !== 0" class="footer-wrap">
        <div class="page-button--wrap">
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
        <span class="page-count">
          {{ currentPage }}
        </span>
        <div class="page-button--wrap">
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

import NotificationCentreListItems from './NotificationCentreListItems';

export default {
  components: {
    NotificationCentreListItems,
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
    totalNotifications() {
      return this.meta.count;
    },
    currentPage() {
      return Number(this.meta.currentPage);
    },
    inFirstPage() {
      const page = Number(this.meta.currentPage);
      return page === 1;
    },
    inLastPage() {
      return (
        this.currentPage === Math.ceil(this.totalNotifications / this.pageSize)
      );
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
      if (Number(this.$route.params.conversation_id) === conversationId) {
        this.$emit('close');
        return;
      }
      this.$router.push({
        name: 'inbox_conversation',
        params: { conversation_id: conversationId },
      });
      if (
        this.$route.name === 'home' ||
        this.$route.name === 'inbox_conversation'
      ) {
        this.$router.go();
      } else {
        return;
      }

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
        const page = Math.ceil(this.totalNotifications / this.pageSize);
        this.onPageChange(page);
      }
    },
    onMarkAllDoneClick() {
      this.$store.dispatch('notifications/readAll');
    },
    closeNotificationCentre() {
      this.$emit('close');
    },
  },
};
</script>
<style lang="scss" scoped>
.notification-wrap {
  display: flex;
  justify-content: space-between;
  flex-direction: column;
  height: 90vh;
  width: 52rem;
  background-color: var(--white);
  border-radius: var(--border-radius-medium);
  position: absolute;
  left: var(--space-jumbo);
  top: 4%;
  margin: var(--space-small);
}
.header-wrap {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  border-bottom: 1px solid var(--s-50);
  padding: var(--space-two) var(--space-medium) var(--space-slab)
    var(--space-medium);

  .header-title--wrap {
    display: flex;
    align-items: center;
  }

  .header-title {
    font-size: var(--font-size-two);
    font-weight: var(--font-weight-black);
  }

  .header-action--button {
    display: flex;
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
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--space-smaller) var(--space-two);
}

.page-button--wrap {
  display: flex;
  align-items: baseline;

  .page-change--button:hover {
    background: var(--s-50);
  }
}
</style>
