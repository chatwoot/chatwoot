<template>
  <div>
    <div v-if="isWidgetVisible" class="screen-selector">
      <input-radio-group
        name="widget-screen"
        :items="widgetScreens"
        :action="handleScreenChange"
      />
    </div>
    <div v-if="isWidgetVisible" class="widget-wrapper">
      <WidgetHead :config="getWidgetHeadConfig" />
      <WidgetBody :config="getWidgetBodyConfig" />
      <WidgetFooter :config="getWidgetFooterConfig" />
      <div class="branding">
        {{ $t('INBOX_MGMT.WIDGET_BUILDER.BRANDING_TEXT') }}
      </div>
    </div>
    <div
      class="widget-bubble"
      :style="{
        justifyContent: widgetBubblePosition === 'left' ? 'start' : 'end',
      }"
    >
      <button
        class="bubble"
        :class="{
          'bubble-close': isWidgetVisible,
          'bubble-expanded':
            !isWidgetVisible && widgetBubbleType === 'expanded_bubble',
        }"
        :style="{ background: color }"
        @click="toggleWidget"
      >
        <img
          v-if="!isWidgetVisible"
          src="~dashboard/assets/images/bubble-logo.svg"
          alt=""
        />
        <div>
          {{
            isWidgetVisible || widgetBubbleType === 'standard'
              ? ' '
              : widgetBubbleLauncherTitle
          }}
        </div>
      </button>
    </div>
  </div>
</template>

<script>
import WidgetHead from './WidgetHead';
import WidgetBody from './WidgetBody';
import WidgetFooter from './WidgetFooter';
import InputRadioGroup from '../../../routes/dashboard/settings/inbox/components/InputRadioGroup.vue';

export default {
  name: 'Widget',
  components: {
    WidgetHead,
    WidgetBody,
    WidgetFooter,
    InputRadioGroup,
  },
  props: {
    welcomeHeading: {
      type: String,
      default: 'Hi There!',
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
      default: 'in_a_few_minutes',
    },
    color: {
      type: String,
      default: '#1f93ff',
    },
    widgetBubblePosition: {
      type: String,
      default: 'left',
    },
    widgetBubbleLauncherTitle: {
      type: String,
      default: 'Chat with us',
    },
    widgetBubbleType: {
      type: String,
      default: 'standard',
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
        isDefaultScreen: this.isDefaultScreen,
        isOnline: this.isOnline,
        replyTime: this.replyTimeText,
        color: this.color,
      };
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
        case 'in_a_few_hours':
          return this.$t('INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_FEW_HOURS');
        case 'in_a_day':
          return this.$t('INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_DAY');
        default:
          return this.$t('INBOX_MGMT.WIDGET_BUILDER.REPLY_TIME.IN_A_FEW_HOURS');
      }
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
  justify-content: space-between;
  box-shadow: 0 0px 20px 5px rgb(0 0 0 / 10%);
  border-radius: var(--border-radius-large);
  background-color: #f4f6fb;
  min-width: 32rem;
  max-width: 32rem;

  .branding {
    padding-top: var(--space-one);
    padding-bottom: var(--space-one);
    text-align: center;
  }
}
.widget-bubble {
  display: flex;
  flex-direction: row;
  margin-top: var(--space-normal);
  min-width: 32rem;
  max-width: 32rem;

  .bubble {
    display: flex;
    align-items: center;
    border-radius: 3rem;
    height: 6rem;
    width: 6rem;
    position: relative;
    overflow-wrap: anywhere;
    cursor: pointer;

    img {
      height: var(--space-medium);
      width: var(--space-medium);
      margin: 1rem 1rem 0.6rem 1.7rem;
    }

    div {
      padding-right: var(--space-normal);
    }
  }

  .bubble-close::before,
  .bubble-close::after {
    background-color: var(--white);
    content: ' ';
    display: inline;
    height: var(--space-medium);
    width: var(--space-micro);
    left: var(--space-three);
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
