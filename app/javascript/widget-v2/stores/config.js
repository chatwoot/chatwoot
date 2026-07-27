import { defineStore } from 'pinia';
import { computed, ref } from 'vue';
import { fetchWidgetConfig } from 'widget-v2/api/config';
import { applyTheme, applyDarkMode } from 'widget-v2/helpers/theme';

export const useConfigStore = defineStore('config', () => {
  const config = ref(null);
  const status = ref('idle'); // idle | loading | ready | error
  const hostTheme = ref(null);
  const darkMode = ref('light'); // light | dark | auto
  const locale = ref(window.chatwootWebChannel?.locale || 'en');

  const channel = computed(() => config.value?.channel_config || {});
  const aiAgent = computed(() => config.value?.ai_agent || null);
  const portal = computed(() => config.value?.portal || null);
  const contact = computed(() => config.value?.contact || {});
  const globalConfig = computed(() => config.value?.global_config || {});
  const hasAiAgent = computed(() => Boolean(aiAgent.value));

  const applyCurrentTheme = () => {
    applyTheme({
      primary:
        channel.value.widget_color || window.chatwootWebChannel?.widgetColor,
      ...(hostTheme.value || {}),
    });
    applyDarkMode(hostTheme.value?.darkMode || darkMode.value);
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

  return {
    config,
    status,
    locale,
    darkMode,
    channel,
    aiAgent,
    hasAiAgent,
    portal,
    contact,
    globalConfig,
    load,
    setHostTheme,
    setDarkMode,
    applyCurrentTheme,
  };
});
