<template>
  <div class="widget-preview-container min-w-[352px] min-h-[775px]">
    <div v-if="isWidgetVisible" class="screen-selector">
      <input-radio-group
        name="widget-screen"
        :items="widgetScreens"
        :action="handleScreenChange"
      />
    </div>
    <div
      v-if="isWidgetVisible"
      :style="
        getWidgetBodyConfig.isDefaultScreen
          ? {}
          : { justifyContent: 'space-between' }
      "
      class="widget-wrapper"
    >
      <WidgetHead :config="getWidgetHeadConfig" />
      <div style="height: 100%">
        <WidgetBody :config="getWidgetBodyConfig" />
        <WidgetFooter :config="getWidgetFooterConfig" />
        <div class="branding">
          <a class="branding-link">
            <img class="branding-image" :src="globalConfig.logoThumbnail" />
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
    <div class="widget-bubble" :style="getBubblePositionStyle">
      <button
        class="bubble"
        :class="getBubbleTypeClass"
        :style="
          !channelAvatarUrl
            ? { background: color }
            : isWidgetVisible
            ? { background: color }
            : {}
        "
        @click="toggleWidget"
      >
        <img
          v-if="!isWidgetVisible"
          :src="
            channelAvatarUrl ||
            require('../../../assets/images/bubble-logo.svg')
          "
          :class="{
            '!w-full !h-full': channelAvatarUrl,
          }"
          alt=""
        />
      </button>
    </div>
  </div>
</template>

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
    faqs: {
      type: Array,
      default: () => [],
    },
    welcomeTagline: {
      type: String,
      default: '',
    },
    websiteName: {
      type: String,
      default: '',
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
    channelAvatarUrl: {
      type: String,
      default: null,
    },
    chatOnWhatsappSettings: {
      type: Object,
      default: () => {},
    },
    askQuestionText: {
      type: String,
      default: 'Ask a question',
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
    getWidgetHeadConfig() {
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
    getWidgetBodyConfig() {
      return {
        welcomeHeading: this.welcomeHeading,
        welcomeTagline: this.welcomeTagline,
        isDefaultScreen: this.isDefaultScreen,
        isOnline: this.isOnline,
        replyTime: this.replyTimeText,
        color: this.color,
        logo: this.logo,
        faqs: this.faqs,
        chatOnWhatsappSettings: this.chatOnWhatsappSettings,
        askQuestionText: this.askQuestionText,
      };
    },
    avatarSrc() {
      return (
        this.channelAvatarUrl || '~dashboard/assets/images/bubble-logo.svg'
      );
    },
    getWidgetFooterConfig() {
      return {
        isDefaultScreen: this.isDefaultScreen,
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
        width: '100%',
      };
    },
    getBubbleTypeClass() {
      return {
        'bubble-close': this.isWidgetVisible,
        'bubble-expanded':
          !this.isWidgetVisible && this.widgetBubbleType === 'expanded_bubble',
        'mt-[700px] !p-0': !this.isWidgetVisible,
      };
    },
    getWidgetBubbleLauncherTitle() {
      return this.isWidgetVisible || this.widgetBubbleType === 'standard'
        ? ' '
        : this.widgetBubbleLauncherTitle;
    },
  },
  methods: {
    handleScreenChange(item) {
      this.isDefaultScreen = item.id === 'default';
    },
    toggleWidget() {
      this.isWidgetVisible = !this.isWidgetVisible;
      this.isDefaultScreen = true;
    },
  },
};
</script>

<style lang="scss" scoped>
.screen-selector {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.widget-wrapper {
  display: flex;
  flex-direction: column;
  box-shadow: var(--shadow-widget-builder);
  border-radius: var(--border-radius-large);
  background-color: #f4f6fb;
  width: calc(var(--space-large) * 11);
  height: calc(var(--space-mega) * 6.5);

  .branding {
    padding-top: var(--space-one);
    padding-bottom: var(--space-one);
    display: flex;
    justify-content: center;

    .branding-link {
      align-items: center;
      color: var(--b-500);
      cursor: pointer;
      display: flex;
      filter: grayscale(1);
      flex-direction: row;
      font-size: var(--font-size-micro);
      line-height: 1.5;
      opacity: 0.9;
      text-decoration: none;

      &:hover {
        filter: grayscale(0);
        opacity: 1;
        color: var(--b-600);
      }

      .branding-image {
        max-width: var(--space-one);
        max-height: var(--space-one);
        margin-right: var(--space-micro);
      }
    }
  }
}
.widget-bubble {
  display: flex;
  flex-direction: row;
  margin-top: var(--space-normal);
  width: calc(var(--space-large) * 10);

  .bubble {
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: calc(var(--border-radius-large) * 10);
    height: calc(var(--space-large) * 2);
    width: calc(var(--space-large) * 2);
    position: relative;
    overflow-wrap: anywhere;
    cursor: pointer;

    img {
      height: var(--space-medium);
      width: var(--space-medium);
    }

    div {
      padding-right: var(--space-two);
    }

    .bubble-expanded {
      img {
        height: var(--space-large);
        width: var(--space-large);
      }
    }
  }

  .bubble-close::before,
  .bubble-close::after {
    background-color: var(--white);
    content: ' ';
    display: inline;
    height: var(--space-medium);
    width: var(--space-micro);
    left: var(--space-large);
    position: absolute;
  }

  .bubble-close::before {
    transform: rotate(45deg);
  }

  .bubble-close::after {
    transform: rotate(-45deg);
  }

  .bubble-expanded {
    font-size: var(--font-size-default);
    font-weight: var(--font-weight-medium);
    color: var(--white);
    width: auto !important;
    height: var(--space-larger) !important;
  }
}
</style>
