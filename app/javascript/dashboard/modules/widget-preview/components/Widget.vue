<script>
import WidgetHead from './WidgetHead.vue';
import WidgetBody from './WidgetBody.vue';
import WidgetFooter from './WidgetFooter.vue';
import InputRadioGroup from 'dashboard/routes/dashboard/settings/inbox/components/InputRadioGroup.vue';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import { mapGetters } from 'vuex';

export default {
  name: 'Widget',
  components: {
    WidgetHead,
    WidgetBody,
    WidgetFooter,
    InputRadioGroup,
  },
  mixins: [globalConfigMixin],
  props: {
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
    color: { type: String, default: '' },
    dot1: { type: String, default: '' },
    dot2: { type: String, default: '' },
    dot3: { type: String, default: '' },
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
  },
  data() {
    return {
      widgetScreens: [
        {
          id: 'default',
          title: this.$t('INBOX_MGMT.WIDGET_BUILDER.WIDGET_SCREEN.DEFAULT'),
          checked: true,
        },
        {
          id: 'chat',
          title: this.$t('INBOX_MGMT.WIDGET_BUILDER.WIDGET_SCREEN.CHAT'),
          checked: false,
        },
      ],
      isDefaultScreen: true,
      isWidgetVisible: true,
    };
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
    getWidgetConfig() {
      return {
        welcomeHeading: this.welcomeHeading,
        welcomeTagline: this.welcomeTagline,
        websiteName: this.websiteName,
        logo: this.logo,
        isDefaultScreen: this.isDefaultScreen,
        isOnline: this.isOnline,
        replyTime: this.replyTimeText,
        color: this.color,
      };
    },
    replyTimeText() {
      switch (this.replyTime) {
        case 'in_a_few_minutes':
          return this.$t(
            'INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_FEW_MINUTES'
          );
        case 'in_a_day':
          return this.$t('INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_DAY');
        default:
          return this.$t('INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_FEW_HOURS');
      }
    },
    getBubblePositionStyle() {
      return {
        justifyContent: this.widgetBubblePosition === 'left' ? 'start' : 'end',
      };
    },
    isBubbleExpanded() {
      return (
        !this.isWidgetVisible && this.widgetBubbleType === 'expanded_bubble'
      );
    },
    getWidgetBubbleLauncherTitle() {
      return this.isWidgetVisible || this.widgetBubbleType === 'standard'
        ? ' '
        : this.widgetBubbleLauncherTitle;
    },
  },
  methods: {
    addLogo() {
      const svgns = 'http://www.w3.org/2000/svg';

      // Create SVG
      const svg = document.createElementNS(svgns, 'svg');
      svg.setAttribute('viewBox', '0 0 208.85 217.51');

      const size = this.isBubbleExpanded ? 42 : 64;
      svg.setAttribute('width', size);
      svg.setAttribute('height', size);
      svg.setAttribute('preserveAspectRatio', "xMidYMid meet");

      svg.setAttribute('id', 'dynamic-svg');

      const circle = document.createElementNS(svgns, 'circle');
      circle.setAttribute('cx', '103.95');
      circle.setAttribute('cy', '105.93');
      circle.setAttribute('r', '76.66');
      circle.setAttribute('fill', '#ffffff');
      svg.appendChild(circle);

      // Dots
      const dots = [
        { cx: '70.18', cy: '105.93', color: this.dot1 }, // Green
        { cx: '103.95', cy: '105.93', color: this.dot2 }, // Yellow
        { cx: '137.68', cy: '105.93', color: this.dot3 }, // Red
      ];

      dots.forEach(dot => {
        const dotEl = document.createElementNS(svgns, 'circle');
        dotEl.setAttribute('cx', dot.cx);
        dotEl.setAttribute('cy', dot.cy);
        dotEl.setAttribute('r', '11.97');
        dotEl.setAttribute('fill', dot.color);
        svg.appendChild(dotEl);
      });

      this.$refs.svgButton.insertBefore(svg, this.$refs.svgButton.firstChild);
    },
    removeLogo() {
      const svg = this.$refs.svgButton.querySelector('#dynamic-svg');
      if (svg) {
        this.$refs.svgButton.removeChild(svg);
      }
    },
    handleScreenChange(item) {
      this.isDefaultScreen = item.id === 'default';
    },
    toggleWidget() {
      this.isWidgetVisible = !this.isWidgetVisible;
      this.isDefaultScreen = true;
    },
  },
  watch: {
    isWidgetVisible(newVal) {
      if (newVal) {
        this.removeLogo();
      } else {
        this.addLogo();
      }
    },
    widgetBubbleType(newVal) {
      if (this.isWidgetVisible) return;
      this.removeLogo();
      this.addLogo();
    },
    dot1(newVal) {
      if (this.isWidgetVisible) return;
      this.removeLogo();
      this.addLogo();
    },
    dot2(newVal) {
      if (this.isWidgetVisible) return;
      this.removeLogo();
      this.addLogo();
    },
    dot3(newVal) {
      if (this.isWidgetVisible) return;
      this.removeLogo();
      this.addLogo();
    },
  },
};
</script>

<template>
  <div>
    <div v-if="isWidgetVisible" class="flex flex-col items-center">
      <InputRadioGroup
        name="widget-screen"
        :items="widgetScreens"
        :action="handleScreenChange"
      />
    </div>
    <div
      v-if="isWidgetVisible"
      class="widget-wrapper flex flex-col justify-between rounded-lg shadow-md bg-slate-25 dark:bg-slate-800 h-[31.25rem] w-80"
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
            class="items-center gap-0.5 text-slate-500 dark:text-slate-400 cursor-pointer flex filter grayscale opacity-90 hover:grayscale-0 hover:opacity-100 text-xxs"
          >
            <img
              class="max-w-2.5 max-h-2.5"
              :src="globalConfig.logoThumbnail"
            />
            <span>
              {{
                useInstallationName(
                  $t('INBOX_MGMT.WIDGET_BUILDER.BRANDING_TEXT'),
                  globalConfig.installationName
                )
              }}
            </span>
          </a>
        </div>
      </div>
    </div>
    <div class="flex mt-4 w-[320px]" :style="getBubblePositionStyle">
      <button
        ref="svgButton"
        class="relative flex items-center justify-center rounded-full cursor-pointer p-0"
        :style="{
          background: color,
          ...(isBubbleExpanded
            ? {}: {
                'border-radius': '100% 100% 100% 100% / 100% 100% 0% 100%',
                'box-shadow': '0 8px 24px rgba(0, 0, 0, .16)',
              }),
        }"
        :class="
          isBubbleExpanded
            ? 'w-auto font-medium text-base text-white dark:text-white h-12 pl-1 pr-4 m-0'
            : 'w-16 h-16 bg-[#1f93ff] cursor-pointer select-none overflow-hidden z-[2147483000] rounded-full'
        "
        @click="toggleWidget"
      >
        <!-- <img
          v-if="!isWidgetVisible"
          src="~dashboard/assets/images/bubble-logo.svg"
          alt=""
          draggable="false"
          class="w-6 h-6 mx-auto"
        /> -->
        <div v-if="isBubbleExpanded">
          {{ getWidgetBubbleLauncherTitle }}
        </div>
        <div v-if="isWidgetVisible" class="relative">
          <div class="absolute w-0.5 h-8 rotate-45 -translate-y-1/2 bg-white" />
          <div
            class="absolute w-0.5 h-8 -rotate-45 -translate-y-1/2 bg-white"
          />
        </div>
      </button>
    </div>
  </div>
</template>
