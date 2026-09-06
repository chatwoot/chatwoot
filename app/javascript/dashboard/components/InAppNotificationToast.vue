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
});

onUnmounted(() => {
  emitter.off(BUS_EVENTS.NEW_NOTIFICATION, handleNewNotification);
});
</script>

<template>
  <Teleport to="body">
    <TransitionGroup
      tag="div"
      class="fixed bottom-6 ltr:right-6 rtl:left-6 z-[9999] flex flex-col gap-2.5 pointer-events-none"
      enter-active-class="animate-toast-in"
      leave-active-class="animate-toast-out"
    >
      <NotificationCard
        v-for="notif in notifications"
        :key="notif.id"
        :notif="notif"
        :display-duration="displayDuration"
        @close="removeNotification"
        @open="openConversation"
      />
    </TransitionGroup>
  </Teleport>
</template>
