<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';
import { emitter } from 'shared/helpers/mitt';
import { useI18n } from 'dashboard/composables/useI18n';
import { useRoute } from 'dashboard/composables/route';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import {
  isAConversationRoute,
  isAInboxViewRoute,
  isNotificationRoute,
} from 'dashboard/helper/routeHelpers';

const { t } = useI18n();
const route = useRoute();

const RECONNECTED_BANNER_TIMEOUT = 2000;

const showNotification = ref(!navigator.onLine);
const isDisconnected = ref(false);
const isReconnecting = ref(false);
const isReconnected = ref(false);
let reconnectTimeout = null;

const bannerText = computed(() => {
  if (isReconnecting.value) return t('NETWORK.NOTIFICATION.RECONNECTING');
  if (isReconnected.value) return t('NETWORK.NOTIFICATION.RECONNECT_SUCCESS');
  return t('NETWORK.NOTIFICATION.OFFLINE');
});

const iconName = computed(() => (isReconnected.value ? 'wifi' : 'wifi-off'));
const canRefresh = computed(
  () => !isReconnecting.value && !isReconnected.value
);

const refreshPage = () => {
  window.location.reload();
};

const closeNotification = () => {
  showNotification.value = false;
  isReconnected.value = false;
  clearTimeout(reconnectTimeout);
};

const isInAnyOfTheRoutes = routeName => {
  return (
    isAConversationRoute(routeName, true) ||
    isAInboxViewRoute(routeName, true) ||
    isNotificationRoute(routeName, true)
  );
};

const updateWebsocketStatus = () => {
  isDisconnected.value = true;
  showNotification.value = true;
};

const handleReconnectionCompleted = () => {
  isDisconnected.value = false;
  isReconnecting.value = false;
  isReconnected.value = true;
  showNotification.value = true;
  reconnectTimeout = setTimeout(closeNotification, RECONNECTED_BANNER_TIMEOUT);
};

const handleReconnecting = () => {
  if (isInAnyOfTheRoutes(route.name)) {
    isReconnecting.value = true;
    isReconnected.value = false;
    showNotification.value = true;
  } else {
    handleReconnectionCompleted();
  }
};

const updateOnlineStatus = event => {
  // Case: Websocket is not disconnected
  // If the user goes offline, show the notification
  // If the user goes online, close the notification

  // Case: Websocket is disconnected
  // If the user goes offline, show the notification
  // If the user goes online but the websocket is disconnected, don't close the notification
  // If the user goes online and the websocket is not disconnected, close the notification

  if (event.type === 'offline') {
    showNotification.value = true;
  } else if (event.type === 'online' && !isDisconnected.value) {
    handleReconnectionCompleted();
  }
};

const addEventListeners = () => {
  window.addEventListener('offline', updateOnlineStatus);
  window.addEventListener('online', updateOnlineStatus);
  emitter.on(BUS_EVENTS.WEBSOCKET_DISCONNECT, updateWebsocketStatus);
  emitter.on(
    BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED,
    handleReconnectionCompleted
  );
  emitter.on(BUS_EVENTS.WEBSOCKET_RECONNECT, handleReconnecting);
};

const removeEventListeners = () => {
  window.removeEventListener('offline', updateOnlineStatus);
  window.removeEventListener('online', updateOnlineStatus);
  emitter.off(BUS_EVENTS.WEBSOCKET_DISCONNECT, updateWebsocketStatus);
  emitter.off(
    BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED,
    handleReconnectionCompleted
  );
  emitter.off(BUS_EVENTS.WEBSOCKET_RECONNECT, handleReconnecting);
  clearTimeout(reconnectTimeout);
};

onMounted(addEventListeners);

onBeforeUnmount(removeEventListeners);
</script>

<template>
  <transition name="network-notification-fade" tag="div">
    <div v-show="showNotification" class="fixed top-4 left-2 z-50 group">
      <div
        class="flex items-center justify-between py-1 px-2 w-full rounded-lg shadow-lg bg-yellow-200 dark:bg-yellow-700 relative"
      >
        <fluent-icon
          :icon="iconName"
          class="text-yellow-700/50 dark:text-yellow-50"
          size="18"
        />
        <span
          class="text-xs tracking-wide px-2 font-medium text-yellow-700/70 dark:text-yellow-50"
        >
          {{ bannerText }}
        </span>
        <woot-button
          v-if="canRefresh"
          :title="$t('NETWORK.BUTTON.REFRESH')"
          variant="clear"
          size="small"
          color-scheme="warning"
          icon="arrow-clockwise"
          @click="refreshPage"
        />
        <woot-button
          variant="clear"
          size="small"
          color-scheme="warning"
          icon="dismiss"
          @click="closeNotification"
        />
      </div>
    </div>
  </transition>
</template>
