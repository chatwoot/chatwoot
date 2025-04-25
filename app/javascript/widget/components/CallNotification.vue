<script>
import { mapGetters } from 'vuex';
import configMixin from '../mixins/configMixin';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import { isWidgetColorLighter } from 'shared/helpers/colorHelper';

export default {
  name: 'CallNotification',
  components: {
    Thumbnail,
  },
  mixins: [configMixin],
  props: {
    caller: {
      type: Object,
      required: true,
    },
    roomId: {
      type: [String, Number],
      required: true,
    },
  },
  emits: ['accept', 'reject'],
  computed: {
    callerName() {
      return this.caller.name || this.$t('CALL_VIEW.UNKNOWN_CALLER');
    },
    callerAvatar() {
      return this.caller.avatar_url || '/assets/images/chatwoot_bot.png';
    },
    availabilityStatus() {
      return this.caller.availability_status || 'online';
    },
  },
};
</script>

<template>
  <div class="call-notification">
    <div class="call-header">
      <Thumbnail
        :src="callerAvatar"
        size="40px"
        :username="callerName"
        :status="availabilityStatus"
      />
      <div class="caller-info">
        <div class="caller-name" v-dompurify-html="callerName" />
        <div class="call-status">{{ $t('CALL_VIEW.INCOMING_CALL') }}</div>
      </div>
    </div>
    <div class="call-actions">
      <button class="reject" @click="$emit('reject', roomId)">
        {{ $t('CALL_VIEW.DECLINE') }}
      </button>
      <button class="accept" @click="$emit('accept', roomId)">
        {{ $t('CALL_VIEW.ACCEPT') }}
      </button>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.call-notification {
  background: var(--white);
  border-radius: var(--border-radius-medium);
  padding: var(--space-normal);
  width: 100%;

  .call-header {
    display: flex;
    align-items: center;
    margin-bottom: var(--space-small);

    .caller-info {
      flex-grow: 1;
      margin-left: var(--space-small);

      .caller-name {
        font-weight: var(--font-weight-medium);
        margin-bottom: var(--space-micro);
        color: var(--color-heading);
      }

      .call-status {
        color: var(--color-body);
        font-size: var(--font-size-small);
      }
    }
  }

  .call-actions {
    display: flex;
    gap: var(--space-small);
    margin-top: var(--space-normal);

    button {
      flex: 1;
      padding: var(--space-small) var(--space-normal);
      border-radius: var(--border-radius-normal);
      font-weight: var(--font-weight-medium);
      transition: all 0.2s ease;
      border: 1px solid transparent;

      &.accept {
        background: var(--g-400);
        color: var(--white);
        border-color: var(--g-500);

        &:hover {
          background: var(--g-500);
        }
      }

      &.reject {
        background: var(--r-50);
        color: var(--r-400);
        border-color: var(--r-100);

        &:hover {
          background: var(--r-100);
          color: var(--r-500);
        }
      }
    }
  }
}

@media (prefers-color-scheme: dark) {
  .call-notification {
    background: var(--color-background-dark);

    .caller-info {
      .caller-name {
        color: var(--color-heading-dark);
      }

      .call-status {
        color: var(--color-body-dark);
      }
    }
  }
}
</style> 