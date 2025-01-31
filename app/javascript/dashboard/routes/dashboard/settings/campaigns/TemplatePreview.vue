<script>
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

const {
  LOGO_THUMBNAIL: logoThumbnail,
  BRAND_NAME: brandName,
  WIDGET_BRAND_URL: widgetBrandURL,
} = window.globalConfig || {};

export default {
  mixins: [globalConfigMixin],
  name: 'TemplatePreview',
  props: {
    selectedTemplate: {
      type: Object,
      default: null,
    },
    previewPosition: {
      type: Object,
      default: () => ({
        right: 90,
        top: 130,
      }),
    },
  },
  data() {
    return {
      globalConfig: {
        brandName,
        logoThumbnail,
        widgetBrandURL,
      },
    };
  },
  computed: {
    hasMultipleCurlyBraces() {
      if (!this.selectedTemplate?.components) return false;

      // Find the index of BODY component
      const bodyIndex = this.selectedTemplate.components.findIndex(
        component => component.type === 'BODY'
      );

      if (
        bodyIndex === -1 ||
        !this.selectedTemplate.components[bodyIndex].text
      ) {
        return false;
      }

      const text = this.selectedTemplate.components[bodyIndex].text;
      const curlyBraceMatches = text.match(/{{.*?}}/g) || [];

      if (
        this.selectedTemplate?.parameter_format !== 'NAMED' &&
        curlyBraceMatches.length > 0
      ) {
        return true;
      }

      return curlyBraceMatches.length > 1;
    },
  },
  watch: {
    hasMultipleCurlyBraces: {
      immediate: true,
      handler(newValue) {
        this.$emit('template-validation', !newValue);
      },
    },
  },
};
</script>

<template>
  <div
    class="template-preview-wrapper"
    :style="{
      right: `${previewPosition.right}px`,
      top: `${previewPosition.top}px`,
    }"
  >
    <!-- Fixed Header Section -->
    <div class="status-bar">
      <span class="time">
        {{
          $t('CAMPAIGN.ADD.PREVIEW.TIME', {
            default: '12:00',
          })
        }}
      </span>
      <div class="status-icons">
        <woot-button
          icon="speaker-mute"
          size="medium"
          color-scheme="clear secondary-icon"
          class-names="button--only-icon speaker"
        ></woot-button>
        <!-- <woot-button
          icon="mail-unread"
          size="medium"
          color-scheme="clear secondary-icon"
          class-names="button--only-icon mail"
        ></woot-button> -->
        <woot-button
          icon="wifi"
          size="medium"
          color-scheme="clear secondary-icon"
          class-names="button--only-icon wifi"
        ></woot-button>
      </div>
    </div>

    <div class="chat-header">
      <div class="header-content">
        <woot-button
          icon="chevron-left"
          size="small"
          color-scheme="clear secondary-icon"
          class-names="button--only-icon back "
        ></woot-button>
        <div class="business-profile">
          <img
            class="profile-img"
            :alt="globalConfig.brandName"
            :src="globalConfig.logoThumbnail"
          />
          <div class="business-info">
            <div class="name-container">
              <span class="business-name">
                {{
                  $t('CAMPAIGN.ADD.PREVIEW.BUSINESS', {
                    default: 'OneHash',
                  })
                }}
              </span>
              <woot-button
                icon="checkmark-circle"
                size="small"
                color-scheme="clear success"
                class-names="button--only-icon"
              ></woot-button>
            </div>
          </div>
        </div>
        <div class="header-actions">
          <woot-button
            icon="call"
            size="small"
            color-scheme="clear secondary-icon"
            class-names="button--only-icon call"
          ></woot-button>
          <span class="more-icon">⋮</span>
        </div>
      </div>
    </div>

    <!-- Scrollable Content Area -->
    <div class="scrollable-content">
      <div class="chat-area">
        <!-- Meta Banner -->
        <div class="meta-banner">
          <woot-button
            icon="information"
            size="small"
            color-scheme="clear"
            class-names="button--only-icon mt-0"
          ></woot-button>
          {{
            $t('CAMPAIGN.ADD.PREVIEW.META_INFO', {
              default:
                'This business uses a secure service from Meta to manage this chat. Tap to learn more',
            })
          }}
        </div>

        <!-- Template Message -->
        <div v-if="selectedTemplate" class="message-container">
          <div class="template-content">
            <!-- Header section with conditional rendering -->
            <div v-if="selectedTemplate.components[0]" class="header-section">
              <img
                v-if="selectedTemplate.components[0].format === 'IMAGE'"
                :src="selectedTemplate.components[0].example.header_handle[0]"
                :alt="selectedTemplate.components[0].format"
                class="template-image"
              />
              <div v-else class="header-text">
                {{ selectedTemplate.components[0].text }}
              </div>
            </div>
            <div v-if="selectedTemplate.components[1]" class="body-text">
              {{ selectedTemplate.components[1].text }}
            </div>
            <div v-if="selectedTemplate.components[2]" class="footer-text">
              {{ selectedTemplate.components[2].text }}
            </div>
            <div v-if="hasMultipleCurlyBraces" class="error-message">
              Only 'NAMED' templates with up to 1 parameter are allowed.
              (parameter_name: 'name') <br />
              <span class="example-text" v-pre>
                Example: Hi {{ name }} Thanks for reaching *OneHash* Support! We
                are looking into your queries.
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Fixed Footer Section -->
    <div class="message-input-area">
      <div class="input-actions">
        <span class="plus-icon">+</span>
        <div class="input-box"></div>
        <div class="action-buttons">
          <woot-button
            icon="attach"
            size="medium"
            color-scheme="clear primary"
            class-names="button--only-icon action-button"
          ></woot-button>
          <woot-button
            icon="emoji"
            size="medium"
            color-scheme="clear primary"
            class-names="button--only-icon action-button"
          ></woot-button>
          <woot-button
            icon="microphone"
            size="medium"
            color-scheme="clear primary"
            class-names="button--only-icon action-button"
          ></woot-button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.template-preview-wrapper {
  position: fixed;
  width: 300px;
  height: 550px;
  background: #ede4db;
  border-radius: 20px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.example-text {
  display: block; /* Ensures it takes a full line */
  margin-top: 8px; /* Adds space between the text and the span */
  color: #111b21;
}

.status-bar {
  background: #075e56;
  padding: 4px 12px;
  color: white;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 14px;
  height: 24px;
  flex-shrink: 0;
}

.chat-header {
  background: #075e54;
  padding: 8px 16px;
  color: white;
  flex-shrink: 0;
}

.template-image {
  width: 100%;
  max-height: 200px;
  object-fit: cover;
  border-radius: 4px;
  margin-bottom: 8px;
}

.header-section {
  margin-bottom: 8px;
}

/* Scrollable content styles */
.scrollable-content {
  flex-grow: 1;
  overflow-y: auto;
  scrollbar-width: thin;
  scrollbar-color: rgba(0, 0, 0, 0.2) transparent;
}

/* Webkit scrollbar styles */
.scrollable-content::-webkit-scrollbar {
  width: 6px;
}

.scrollable-content::-webkit-scrollbar-track {
  background: transparent;
}

.scrollable-content::-webkit-scrollbar-thumb {
  background-color: rgba(0, 0, 0, 0.2);
  border-radius: 3px;
}

.chat-area {
  padding: 16px;
  background: #efeae2;
  min-height: 100%;
}

.status-icons {
  display: flex;
  gap: 0px;
  align-items: center;
}

.back {
  position: relative;
  left: -6px;
}
.speaker {
  position: relative;
  right: -19px;
}
.call {
  position: relative;
  top: -2px;
}
.wifi {
  position: relative;
  right: -6px;
}

.header-content {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 3px;
}

.business-profile {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  flex-grow: 1;
  position: relative;
  left: -15px;
}

.profile-img {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  object-fit: cover;
  position: relative;
  top: -3px; /* Moves the image 2px up */
  right: -2px; /* Moves the image 1px to the left */
}

.name-container {
  display: flex;
  align-items: flex-start;
  gap: 2px;
}

.business-name {
  font-size: 18px;
  font-weight: 500;
}

.header-actions {
  display: flex;
  gap: 6px;
  font-size: 16px;
}

.meta-banner {
  background: #dbf2f1;
  padding: 3px 6px;
  border-radius: 8px;
  font-size: 11px;
  color: #667781;
  margin-bottom: 16px;
  display: flex;
  gap: 8px;
}

.message-container {
  background: white;
  border-radius: 8px;
  padding: 0;
  max-width: 85%;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
}

.template-content {
  padding: 16px;
}

.header-text {
  font-size: 14px;
  color: #111b21;
  margin-bottom: 8px;
}

.body-text {
  font-size: 14px;
  color: #111b21;
  line-height: 1.5;
  margin-bottom: 8px;
}

.footer-text {
  font-size: 13px;
  color: #667781;
  padding-top: 8px;
  border-top: 1px solid #e9edef;
}

.error-message {
  margin-top: 8px;
  padding: 8px;
  background-color: #fef2f2;
  color: #dc2626;
  border-radius: 4px;
  font-size: 13px;
  border: 1px solid #fee2e2;
}

.message-input-area {
  padding: 8px 16px;
  background: #f0f0f0;
  flex-shrink: 0;
}

.input-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.input-box {
  flex-grow: 1;
  height: 40px;
  background: white;
  border-radius: 20px;
}

.action-buttons {
  display: flex;
  align-items: center;
  margin-left: -8px;
}

.action-button {
  margin: 0 !important;
  padding: 0 !important;
}

.plus-icon,
.attach-icon,
.camera-icon,
.mic-icon {
  font-size: 20px;
  color: #54656f;
  cursor: pointer;
}
</style>
