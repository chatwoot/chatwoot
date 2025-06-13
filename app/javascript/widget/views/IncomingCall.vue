<script>
import { mapGetters } from 'vuex';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import { acceptCall, rejectCall } from '../helpers/callHelper';

export default {
  name: 'IncomingCall',
  components: {
    Thumbnail,
  },
  computed: {
    ...mapGetters({
      activeCall: 'calls/getActiveCall',
    }),
    caller() {
      return (
        this.activeCall?.caller || {
          name: 'Unknown Caller',
          avatar_url: null,
        }
      );
    },
  },
  methods: {
    async handleAcceptCall() {
      if (!this.activeCall) return;
      acceptCall(this.activeCall.call_data);
      window.open(
        `https://${this.activeCall.call_data.domain}/${this.activeCall.call_data.room_id}?jwt=${this.activeCall.call_data.jwt}#config.prejoinConfig.enabled=false`,
        '_blank'
      );
    },
    async handleRejectCall() {
      if (!this.activeCall) return;
      rejectCall(this.activeCall.call_data);
    },
  },
};
</script>

<template>
  <div class="dialog-overlay" @click.self="handleRejectCall">
    <div class="dialog-content">
      <div class="call-dialog">
        <div class="call-header">
          <div class="px-2">
            <Thumbnail
              :src="caller.avatar_url"
              size="40px"
              :username="caller.name"
              :status="availabilityStatus"
            />
          </div>

          <div class="caller-info">
            <div class="caller-name">{{ caller.name || 'Unknown Caller' }}</div>
            <div class="call-status">{{ $t('INCOMING_CALL') }}</div>
          </div>
        </div>
        <div class="call-actions">
          <button class="reject-button" @click="handleRejectCall">
            {{ $t('DECLINE_BUTTON') }}
          </button>
          <button class="accept-button" @click="handleAcceptCall">
            {{ $t('ACCEPT_BUTTON') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10000;
}

.dialog-content {
  width: 100%;
  max-width: 320px;
  margin: 0 16px;
  animation: slideIn 0.2s ease-out;
}

.call-dialog {
  background: white;
  border-radius: 8px;
  padding: 16px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.call-header {
  display: flex;
  align-items: center;
  margin-bottom: 16px;
}

.caller-avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  margin-right: 12px;
  object-fit: cover;
}

.caller-info {
  flex: 1;
}

.caller-name {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 4px;
}

.call-status {
  font-size: 14px;
  color: #666;
}

.call-actions {
  display: flex;
  gap: 8px;

  button {
    flex: 1;
    padding: 8px 16px;
    border-radius: 4px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
    border: none;

    &.accept-button {
      background: #10b981;
      color: white;

      &:hover {
        background: #059669;
      }
    }

    &.reject-button {
      background: #ef4444;
      color: white;

      &:hover {
        background: #dc2626;
      }
    }
  }
}

@keyframes slideIn {
  from {
    transform: translateY(-20px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

@media (prefers-color-scheme: dark) {
  .call-dialog {
    background: #1f2937;
    color: white;
  }

  .call-status {
    color: #9ca3af;
  }
}
</style>
