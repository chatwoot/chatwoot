<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import WidgetHead from './WidgetHead.vue';
import WidgetBody from './WidgetBody.vue';
import WidgetFooter from './WidgetFooter.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import Code from 'dashboard/components/Code.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import { useBranding } from 'shared/composables/useBranding';
import { useMapGetter } from 'dashboard/composables/store';

const props = defineProps({
  welcomeHeading: {
    type: String,
    default: '',
  },
  welcomeTagline: {
    type: String,
    default: '',
  },
  websiteName: {
    type: String,
    required: true,
  },
  logo: {
    type: String,
    default: '',
  },
  isOnline: {
    type: Boolean,
    default: true,
  },
  replyTime: {
    type: String,
    default: '',
  },
  color: {
    type: String,
    default: '',
  },
  widgetBubblePosition: {
    type: String,
    default: '',
  },
  widgetBubbleLauncherTitle: {
    type: String,
    default: '',
  },
  widgetBubbleType: {
    type: String,
    default: '',
  },
  webWidgetScript: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();
const { replaceInstallationName } = useBranding();
const globalConfig = useMapGetter('globalConfig/get');

const isChatMode = ref(false);
const [isWidgetVisible, toggleWidget] = useToggle(true);

const activeTabIndex = ref(0);

const tabs = computed(() => [
  {
    label: t(
      'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_VIEW_OPTION.PREVIEW'
    ),
  },
  {
    label: t(
      'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_VIEW_OPTION.SCRIPT'
    ),
  },
]);

const isPreviewTab = computed(() => activeTabIndex.value === 0);

const widgetScript = computed(() => {
  if (!props.webWidgetScript) return '';

  const options = {
    position: props.widgetBubblePosition,
    type: props.widgetBubbleType,
    launcherTitle: props.widgetBubbleLauncherTitle,
  };

  const script = props.webWidgetScript;
  return (
    script.substring(0, 13) +
    t('INBOX_MGMT.WIDGET_BUILDER.SCRIPT_SETTINGS', {
      options: JSON.stringify(options),
    }) +
    script.substring(13)
  );
});

const replyTimeText = computed(() => {
  switch (props.replyTime) {
    case 'in_a_few_minutes':
      return t('INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_FEW_MINUTES');
    case 'in_a_day':
      return t('INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_DAY');
    default:
      return t('INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_FEW_HOURS');
  }
});

const getWidgetConfig = computed(() => ({
  welcomeHeading: props.welcomeHeading,
  welcomeTagline: props.welcomeTagline,
  websiteName: props.websiteName,
  logo: props.logo,
  isDefaultScreen: !isChatMode.value,
  isOnline: props.isOnline,
  replyTime: replyTimeText.value,
  color: props.color,
}));

const getBubblePositionStyle = computed(() => ({
  justifyContent: props.widgetBubblePosition === 'left' ? 'start' : 'end',
}));

const isBubbleExpanded = computed(
  () => !isWidgetVisible.value && props.widgetBubbleType === 'expanded_bubble'
);

const getWidgetBubbleLauncherTitle = computed(() =>
  isWidgetVisible.value || props.widgetBubbleType === 'standard'
    ? ' '
    : props.widgetBubbleLauncherTitle
);

const handleTabChange = tab => {
  activeTabIndex.value = tabs.value.findIndex(item => item.label === tab.label);
};

const handleToggleWidget = () => {
  toggleWidget();
  if (isWidgetVisible.value) {
    isChatMode.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col h-full min-h-0 flex-1">
    <div class="flex items-center justify-between mb-6 flex-shrink-0">
      <TabBar
        :tabs="tabs"
        :initial-active-tab="activeTabIndex"
        @tab-changed="handleTabChange"
      />

      <div v-if="isPreviewTab" class="flex items-center gap-2">
        <span class="text-heading-3 text-n-slate-11">
          {{ $t('INBOX_MGMT.WIDGET_BUILDER.WIDGET_SCREEN.CHAT') }}
        </span>
        <Switch v-model="isChatMode" />
      </div>
    </div>

    <div class="flex-1 min-h-0 flex flex-col">
      <div
        v-if="isPreviewTab"
        class="flex-1 flex flex-col items-center justify-end pb-4"
      >
        <div
          v-if="isWidgetVisible"
          class="widget-wrapper flex flex-1 flex-shrink-0 flex-col justify-between rounded-lg shadow-md bg-n-slate-2 dark:bg-n-solid-1 h-[31.25rem] w-80 mb-4"
        >
          <WidgetHead :config="getWidgetConfig" />
          <div>
            <WidgetBody
              v-if="!getWidgetConfig.isDefaultScreen"
              :config="getWidgetConfig"
            />
            <WidgetFooter :config="getWidgetConfig" />
            <div class="py-2.5 flex justify-center">
              <a
                class="items-center gap-0.5 text-n-slate-11 cursor-pointer flex filter grayscale opacity-90 hover:grayscale-0 hover:opacity-100 text-xxs"
              >
                <img
                  class="max-w-2.5 max-h-2.5"
                  :src="globalConfig.logoThumbnail"
                />
                <span>
                  {{
                    replaceInstallationName(
                      $t('INBOX_MGMT.WIDGET_BUILDER.BRANDING_TEXT')
                    )
                  }}
                </span>
              </a>
            </div>
          </div>
        </div>

        <div class="flex w-[320px]" :style="getBubblePositionStyle">
          <button
            class="relative flex items-center justify-center rounded-full cursor-pointer"
            :style="{ background: props.color }"
            :class="
              isBubbleExpanded
                ? 'w-auto font-medium text-base text-white dark:text-white h-12 px-4'
                : 'w-16 h-16'
            "
            @click="handleToggleWidget"
          >
            <img
              v-if="!isWidgetVisible"
              src="~dashboard/assets/images/bubble-logo.svg"
              alt=""
              draggable="false"
              class="w-6 h-6 mx-auto"
            />
            <div v-if="isBubbleExpanded" class="ltr:pl-2.5 rtl:pr-2.5">
              {{ getWidgetBubbleLauncherTitle }}
            </div>
            <div v-if="isWidgetVisible" class="relative">
              <div
                class="absolute w-0.5 h-8 rotate-45 -translate-y-1/2 bg-white"
              />
              <div
                class="absolute w-0.5 h-8 -rotate-45 -translate-y-1/2 bg-white"
              />
            </div>
          </button>
        </div>
      </div>

      <div
        v-else
        class="flex-1 p-3 rounded-lg [&_code]:!bg-n-slate-2 bg-n-slate-2 min-w-0 overflow-auto [&_pre]:whitespace-pre-wrap [&_pre]:break-words [&_code]:whitespace-pre-wrap"
      >
        <Code
          :script="widgetScript"
          lang="html"
          class="!text-start"
          :codepen-title="`${websiteName} - Chatwoot Widget Test`"
          enable-code-pen
        />
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
// Widget-specific color variables to match actual widget appearance
.widget-wrapper {
  // Light mode - widget colors
  --slate-1: 252 252 253;
  --slate-2: 249 249 251;
  --slate-3: 240 240 243;
  --slate-4: 232 232 236;
  --slate-5: 224 225 230;
  --slate-6: 217 217 224;
  --slate-7: 205 206 214;
  --slate-8: 185 187 198;
  --slate-9: 139 141 152;
  --slate-10: 128 131 141;
  --slate-11: 96 100 108;
  --slate-12: 28 32 36;

  --background-color: 253 253 253;
  --text-blue: 8 109 224;
  --border-container: 236 236 236;
  --border-strong: 235 235 235;
  --border-weak: 234 234 234;
  --solid-1: 255 255 255;
  --solid-2: 255 255 255;
  --solid-3: 255 255 255;
  --solid-active: 255 255 255;
  --solid-amber: 252 232 193;
  --solid-blue: 218 236 255;
  --solid-iris: 230 231 255;

  --alpha-1: 67, 67, 67, 0.06;
  --alpha-2: 201, 202, 207, 0.15;
  --alpha-3: 255, 255, 255, 0.96;
  --black-alpha-1: 0, 0, 0, 0.12;
  --black-alpha-2: 0, 0, 0, 0.04;
  --border-blue: 39, 129, 246, 0.5;
  --white-alpha: 255, 255, 255, 0.8;
}

// Dark mode - widget colors
.dark .widget-wrapper {
  --slate-1: 17 17 19;
  --slate-2: 24 25 27;
  --slate-3: 33 34 37;
  --slate-4: 39 42 45;
  --slate-5: 46 49 53;
  --slate-6: 54 58 63;
  --slate-7: 67 72 78;
  --slate-8: 90 97 105;
  --slate-9: 105 110 119;
  --slate-10: 119 123 132;
  --slate-11: 176 180 186;
  --slate-12: 237 238 240;

  --background-color: 18 18 19;
  --border-strong: 52 52 52;
  --border-weak: 38 38 42;
  --solid-1: 23 23 26;
  --solid-2: 29 30 36;
  --solid-3: 44 45 54;
  --solid-active: 53 57 66;
  --solid-amber: 42 37 30;
  --solid-blue: 16 49 91;
  --solid-iris: 38 42 101;
  --text-blue: 126 182 255;

  --alpha-1: 36, 36, 36, 0.8;
  --alpha-2: 139, 147, 182, 0.15;
  --alpha-3: 36, 38, 45, 0.9;
  --black-alpha-1: 0, 0, 0, 0.3;
  --black-alpha-2: 0, 0, 0, 0.2;
  --border-blue: 39, 129, 246, 0.5;
  --border-container: 236, 236, 236, 0;
  --white-alpha: 255, 255, 255, 0.1;
}
</style>
