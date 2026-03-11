<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import NotificationCard from './NotificationCard.vue';

const { t } = useI18n();
const router = useRouter();
const store = useStore();

const notifications = ref([]);
const isDark = ref(document.documentElement.classList.contains('dark'));
let themeObserver = null;

const displayDuration = computed(
  () =>
    (store.getters['userNotificationSettings/getNotificationDisplayDuration'] ??
      6) * 1000
);

const NOTIFICATION_REASONS = computed(() => ({
  conversation_creation: t(
    'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_CREATED'
  ),
  conversation_assignment: t(
    'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_ASSIGNED'
  ),
  conversation_mention: t(
    'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.CONVERSATION_MENTION'
  ),
  assigned_conversation_new_message: t(
    'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.ASSIGNED_CONVERSATION_NEW_MESSAGE'
  ),
  conversation_participating: t(
    'PROFILE_SETTINGS.FORM.NOTIFICATIONS.TYPES.PARTICIPATING_CONVERSATION_NEW_MESSAGE'
  ),
}));

const removeNotification = id => {
  notifications.value = notifications.value.filter(n => n.id !== id);
};

const handleNewNotification = data => {
  const notification = data.notification || data;
  const {
    notification_type: notificationType,
    primary_actor,
    secondary_actor,
  } = notification;

  const pushFlags =
    store.getters['userNotificationSettings/getSelectedPushFlags'] ?? [];
  if (!pushFlags.includes(`push_${notificationType}`)) return;

  const sender = primary_actor?.meta?.sender;
  const inbox = primary_actor?.inbox_id
    ? store.getters['inboxes/getInbox'](primary_actor.inbox_id)
    : null;
  const title =
    notification.push_message_title ||
    t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.DEFAULT_TITLE');
  const id = Date.now();

  notifications.value.push({
    id,
    title,
    reason: NOTIFICATION_REASONS.value[notificationType] || null,
    senderName:
      sender?.name ||
      title.split(':')[0] ||
      t('PROFILE_SETTINGS.FORM.NOTIFICATIONS.DEFAULT_SENDER'),
    senderAvatar: sender?.thumbnail || '',
    messageContent: secondary_actor?.content || '',
    conversationId: primary_actor?.id,
    displayId: primary_actor?.id,
    accountId: store.getters.getCurrentAccountId,
    inboxName: inbox?.name || null,
  });

  setTimeout(() => removeNotification(id), displayDuration.value);
};

const openConversation = notif => {
  removeNotification(notif.id);
  if (notif.conversationId && notif.accountId) {
    router.push(
      `/app/accounts/${notif.accountId}/conversations/${notif.conversationId}`
    );
  }
};

onMounted(() => {
  emitter.on(BUS_EVENTS.NEW_NOTIFICATION, handleNewNotification);
  themeObserver = new MutationObserver(() => {
    isDark.value = document.documentElement.classList.contains('dark');
  });
  themeObserver.observe(document.documentElement, {
    attributes: true,
    attributeFilter: ['class'],
  });
});

onUnmounted(() => {
  emitter.off(BUS_EVENTS.NEW_NOTIFICATION, handleNewNotification);
  themeObserver?.disconnect();
});
</script>

<template>
  <teleport to="body">
    <div class="cw-notification-stack" :class="{ dark: isDark }">
      <transition-group name="cw-notif" tag="div">
        <NotificationCard
          v-for="notif in notifications"
          :key="notif.id"
          :notif="notif"
          :display-duration="displayDuration"
          @close="removeNotification"
          @open="openConversation"
        />
      </transition-group>
    </div>
  </teleport>
</template>

<style scoped>
.cw-notification-stack {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 99999;
  display: flex;
  flex-direction: column;
  gap: 10px;
  pointer-events: none;
}
.cw-notif-enter-active {
  animation: cw-slide-in 0.35s cubic-bezier(0.34, 1.56, 0.64, 1);
}
.cw-notif-leave-active {
  animation: cw-slide-out 0.25s ease-in forwards;
}
@keyframes cw-slide-in {
  from {
    opacity: 0;
    transform: translateX(110%) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateX(0) scale(1);
  }
}
@keyframes cw-slide-out {
  from {
    opacity: 1;
    transform: translateX(0) scale(1);
  }
  to {
    opacity: 0;
    transform: translateX(110%) scale(0.95);
  }
}
</style>
