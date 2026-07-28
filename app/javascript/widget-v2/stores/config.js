import { defineStore } from 'pinia';
import { computed, ref } from 'vue';
import { fetchWidgetConfig } from 'widget-v2/api/config';
import { applyTheme, applyDarkMode } from 'widget-v2/helpers/theme';

export const useConfigStore = defineStore('config', () => {
  const config = ref(null);
  const status = ref('idle'); // idle | loading | ready | error
  const hostTheme = ref(null);
  const hostBrand = ref(null);
  const hostNotice = ref(null);
  const hostPosts = ref(null);
  const darkMode = ref('light'); // light | dark | auto
  const locale = ref(window.chatwootWebChannel?.locale || 'en');

  const channel = computed(() => config.value?.channel_config || {});
  const aiAgent = computed(() => config.value?.ai_agent || null);
  const portal = computed(() => config.value?.portal || null);
  const contact = computed(() => config.value?.contact || {});
  const globalConfig = computed(() => config.value?.global_config || {});
  const hasAiAgent = computed(() => Boolean(aiAgent.value));
  const announcements = computed(() => config.value?.announcements || []);

  const applyCurrentTheme = () => {
    // The host may pass a bare theme name or an object of overrides.
    const host =
      typeof hostTheme.value === 'string'
        ? { name: hostTheme.value }
        : hostTheme.value || {};
    applyTheme(host, {
      defaultPrimary:
        channel.value.widget_color || window.chatwootWebChannel?.widgetColor,
    });
    applyDarkMode(host.darkMode || darkMode.value);
  };

  const load = async () => {
    status.value = 'loading';
    try {
      config.value = await fetchWidgetConfig();
      status.value = 'ready';
      applyCurrentTheme();
    } catch {
      status.value = 'error';
    }
  };

  const setHostTheme = theme => {
    hostTheme.value = theme;
    applyCurrentTheme();
  };

  const setDarkMode = mode => {
    darkMode.value = mode;
    applyCurrentTheme();
  };

  const setHostBrand = brand => {
    hostBrand.value = brand;
  };

  const setHostNotice = notice => {
    hostNotice.value = notice;
  };

  const setHostPosts = posts => {
    hostPosts.value = Array.isArray(posts) ? posts : null;
  };

  return {
    config,
    status,
    locale,
    darkMode,
    channel,
    aiAgent,
    hasAiAgent,
    announcements,
    portal,
    contact,
    globalConfig,
    hostBrand,
    hostNotice,
    hostPosts,
    load,
    setHostTheme,
    setHostBrand,
    setHostNotice,
    setHostPosts,
    setDarkMode,
    applyCurrentTheme,
  };
});
