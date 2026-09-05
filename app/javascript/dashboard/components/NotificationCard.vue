<script setup>
import { computed } from 'vue';

const props = defineProps({
  notif: { type: Object, required: true },
  displayDuration: { type: Number, required: true },
});

const emit = defineEmits(['close', 'open']);

const avatarLetter = computed(() =>
  props.notif.senderName.charAt(0).toUpperCase()
);
</script>

<template>
  <div class="cw-notification-card" @click="emit('open', notif)">
    <div class="cw-notif-top">
      <span v-if="notif.reason" class="cw-notif-reason">
        <svg width="9" height="9" viewBox="0 0 24 24" fill="currentColor">
          <path
            d="M12 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6-6V11c0-3.07-1.64-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.63 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2z"
          />
        </svg>
        {{ notif.reason }}
      </span>
      <button class="cw-notif-close" @click.stop="emit('close', notif.id)">
        <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor">
          <path
            d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"
          />
        </svg>
      </button>
    </div>

    <div class="cw-notif-body">
      <div class="cw-notif-avatar">
        <img
          v-if="notif.senderAvatar"
          :src="notif.senderAvatar"
          :alt="notif.senderName"
          class="cw-notif-avatar-img"
        />
        <div v-else class="cw-notif-avatar-fallback">{{ avatarLetter }}</div>
        <span class="cw-notif-badge" />
      </div>

      <div class="cw-notif-content">
        <div class="cw-notif-header">
          <span class="cw-notif-name">{{ notif.senderName }}</span>
          <span class="cw-notif-conversation">{{ `#${notif.displayId}` }}</span>
          <span v-if="notif.inboxName" class="cw-notif-inbox">{{
            notif.inboxName
          }}</span>
        </div>
        <p class="cw-notif-message">{{ notif.messageContent }}</p>
      </div>
    </div>

    <div
      class="cw-notif-progress"
      :style="`--duration: ${displayDuration / 1000}s`"
    />
  </div>
</template>

<style scoped>
.cw-notification-card {
  pointer-events: all;
  display: flex;
  flex-direction: column;
  gap: 8px;
  width: 300px;
  padding: 10px 12px 12px;
  background: #ffffff;
  border-radius: 14px;
  box-shadow:
    0 4px 6px -1px rgba(0, 0, 0, 0.07),
    0 10px 30px -5px rgba(0, 0, 0, 0.12),
    0 0 0 1px rgba(0, 0, 0, 0.05);
  cursor: pointer;
  position: relative;
  overflow: hidden;
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease;
}
.cw-notification-card:hover {
  transform: translateY(-2px) scale(1.01);
  box-shadow:
    0 8px 12px -2px rgba(0, 0, 0, 0.1),
    0 16px 40px -6px rgba(0, 0, 0, 0.15),
    0 0 0 1px rgba(0, 0, 0, 0.06);
}
.dark .cw-notification-card {
  background: #1e2530;
  box-shadow:
    0 4px 6px -1px rgba(0, 0, 0, 0.3),
    0 10px 30px -5px rgba(0, 0, 0, 0.4),
    0 0 0 1px rgba(255, 255, 255, 0.06);
}
.cw-notif-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}
.cw-notif-reason {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.6px;
  color: #6366f1;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.dark .cw-notif-reason {
  color: #818cf8;
}
.cw-notif-close {
  flex-shrink: 0;
  width: 18px;
  height: 18px;
  border: none;
  background: none;
  color: #9ca3af;
  cursor: pointer;
  padding: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  transition:
    color 0.15s,
    background 0.15s;
  margin-left: auto;
}
.cw-notif-close:hover {
  color: #374151;
  background: #f3f4f6;
}
.dark .cw-notif-close:hover {
  color: #e2e8f0;
  background: rgba(255, 255, 255, 0.08);
}
.cw-notif-body {
  display: flex;
  align-items: center;
  gap: 10px;
}
.cw-notif-avatar {
  position: relative;
  flex-shrink: 0;
}
.cw-notif-avatar-img {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  object-fit: cover;
}
.cw-notif-avatar-fallback {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: 600;
}
.cw-notif-badge {
  position: absolute;
  bottom: 0;
  right: 0;
  width: 9px;
  height: 9px;
  background: #22c55e;
  border-radius: 50%;
  border: 2px solid #fff;
}
.dark .cw-notif-badge {
  border-color: #1e2530;
}
.cw-notif-content {
  flex: 1;
  min-width: 0;
}
.cw-notif-header {
  display: flex;
  align-items: center;
  gap: 5px;
  margin-bottom: 2px;
}
.cw-notif-name {
  font-size: 13px;
  font-weight: 600;
  color: #111827;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 120px;
}
.dark .cw-notif-name {
  color: #f1f5f9;
}
.cw-notif-conversation {
  font-size: 11px;
  font-weight: 500;
  color: #6366f1;
  background: #eef2ff;
  padding: 1px 5px;
  border-radius: 20px;
  white-space: nowrap;
  flex-shrink: 0;
}
.dark .cw-notif-conversation {
  color: #a5b4fc;
  background: rgba(99, 102, 241, 0.15);
}
.cw-notif-inbox {
  font-size: 11px;
  color: #9ca3af;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  flex-shrink: 1;
  min-width: 0;
}
.cw-notif-inbox::before {
  content: '·';
  margin-right: 3px;
}
.dark .cw-notif-inbox {
  color: #64748b;
}
.cw-notif-message {
  font-size: 12px;
  color: #6b7280;
  margin: 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  line-height: 1.4;
}
.dark .cw-notif-message {
  color: #94a3b8;
}
.cw-notif-progress {
  position: absolute;
  bottom: 0;
  left: 0;
  height: 3px;
  width: 100%;
  background: linear-gradient(90deg, #6366f1, #8b5cf6);
  border-radius: 0 0 14px 14px;
  transform-origin: left;
  animation: cw-progress var(--duration, 6s) linear forwards;
}
@keyframes cw-progress {
  from {
    transform: scaleX(1);
  }
  to {
    transform: scaleX(0);
  }
}
</style>
