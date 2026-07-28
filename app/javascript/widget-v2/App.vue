<script setup>
import { computed, onMounted, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useConfigStore } from 'widget-v2/stores/config';
import { useConversationsStore } from 'widget-v2/stores/conversations';
import { useAgentsStore } from 'widget-v2/stores/agents';
import { useUiStore } from 'widget-v2/stores/ui';
import { onHostMessage, sendToHost } from 'widget-v2/helpers/bridge';
import { watchSystemDarkMode } from 'widget-v2/helpers/theme';
import { setUser } from 'widget-v2/api/contacts';
import { setAuthToken } from 'widget-v2/api/client';
import { loadLocale } from 'widget-v2/i18n';
import TabBar from 'widget-v2/components/TabBar.vue';
import EmptyState from 'widget-v2/components/EmptyState.vue';

const route = useRoute();
const i18n = useI18n();
const configStore = useConfigStore();
const conversationsStore = useConversationsStore();
const uiStore = useUiStore();

const showTabBar = computed(() => route.meta.tabBar);

// Reading-heavy screens (the help center) ask the host to widen the panel.
watch(
  () => Boolean(route.meta.expanded),
  expanded => sendToHost('setExpandedLayout', { expanded }),
  { immediate: true }
);

const setLocale = async locale => {
  if (!locale) return;
  const normalized = locale.replace('-', '_');
  await loadLocale(i18n, normalized);
  if (i18n.availableLocales.includes(normalized)) {
    i18n.locale.value = normalized;
  }
};

const identifyUser = async ({ identifier, user }) => {
  try {
    const response = await setUser(identifier, user);
    if (response.widget_auth_token) {
      setAuthToken(response.widget_auth_token);
      sendToHost('setAuthCookie', {
        data: { widgetAuthToken: response.widget_auth_token },
      });
    }
    configStore.load();
  } catch (error) {
    sendToHost('error', {
      errorType: 'SET_USER_ERROR',
      data: error?.response?.data,
    });
  }
};

const hostEvents = {
  'config-set': message => {
    if (message.locale) setLocale(message.locale);
    if (message.darkMode) configStore.setDarkMode(message.darkMode);
    if (message.theme) configStore.setHostTheme(message.theme);
    if (message.brand) configStore.setHostBrand(message.brand);
    if (message.notice) configStore.setHostNotice(message.notice);
    if (message.posts) configStore.setHostPosts(message.posts);
  },
  'toggle-open': ({ isOpen }) => uiStore.setOpen(isOpen),
  'widget-visible': () => uiStore.setOpen(true),
  'set-user': identifyUser,
  'set-locale': ({ locale }) => setLocale(locale),
  'set-color-scheme': ({ darkMode }) => configStore.setDarkMode(darkMode),
};

onMounted(async () => {
  onHostMessage(message => {
    const handler = hostEvents[message.event];
    if (handler) handler(message);
  });

  sendToHost('loaded', {
    config: {
      authToken: window.authToken,
      channelConfig: window.chatwootWebChannel,
    },
  });

  watchSystemDarkMode(() => configStore.darkMode);
  setLocale(window.chatwootWebChannel?.locale);
  await configStore.load();
  useAgentsStore()
    .load()
    .catch(() => {});
});

watch(
  () => conversationsStore.totalUnread,
  unreadCount =>
    sendToHost('handleNotificationDot', { unreadMessageCount: unreadCount })
);
</script>

<template>
  <div
    class="relative flex flex-col h-full bg-cw-solid text-cw-text antialiased"
  >
    <EmptyState
      v-if="configStore.status === 'error'"
      class="my-auto"
      icon="i-ph-plugs"
      :title="$t('COMMON.ERROR_TITLE')"
      :description="$t('COMMON.ERROR_DESCRIPTION')"
    />

    <template v-else>
      <router-view v-slot="{ Component }">
        <component :is="Component" class="flex-1 min-h-0" />
      </router-view>
      <TabBar v-if="showTabBar" />
    </template>
  </div>
</template>
