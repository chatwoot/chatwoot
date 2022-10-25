<template>
  <div
    class="message-text__wrap"
    :class="{
      'show--quoted': showQuotedContent,
      'hide--quoted': !showQuotedContent,
    }"
  >
    <a
      v-if="messageData.content_type === 'location'"
      :href="'https://maps.google.com/?q=' + latitude + ',' + longitude"
      target="_blank"
      class="text-content c-white"
      rel="noopener noreferrer nofollow"
    >
      <img src="~dashboard/assets/images/map_image.jpg" alt="Location" />
    </a>

    <div v-if="!isEmail" v-dompurify-html="message" class="text-content" />
    <letter v-else class="text-content" :html="message" />
    <button
      v-if="displayQuotedButton"
      class="quoted-text--button"
      @click="toggleQuotedContent"
    >
      <span v-if="showQuotedContent">
        <fluent-icon icon="chevron-up" class="fluent-icon" size="16" />
        {{ $t('CHAT_LIST.HIDE_QUOTED_TEXT') }}
      </span>
      <span v-else>
        <fluent-icon icon="chevron-down" class="fluent-icon" size="16" />
        {{ $t('CHAT_LIST.SHOW_QUOTED_TEXT') }}
      </span>
    </button>
  </div>
</template>

<script>
import Letter from 'vue-letter';

export default {
  components: { Letter },
  props: {
    message: {
      type: String,
      default: '',
    },
    readableTime: {
      type: String,
      default: '',
    },
    isEmail: {
      type: Boolean,
      default: true,
    },
    displayQuotedButton: {
      type: Boolean,
      default: false,
    },
    messageData: {
      type: Object,
      default: null,
    },
  },
  data() {
    return {
      showQuotedContent: false,
    };
  },
  computed: {
    longitude() {
      return this.messageData.additional_attributes?.longitude;
    },
    latitude() {
      return this.messageData.additional_attributes?.latitude;
    },
  },
  methods: {
    toggleQuotedContent() {
      this.showQuotedContent = !this.showQuotedContent;
    },
  },
};
</script>
<style lang="scss">
.text-content {
  overflow: auto;

  ul,
  ol {
    padding-left: var(--space-two);
  }
  table {
    margin: 0;
    border: 0;

    td {
      margin: 0;
      border: 0;
    }

    tr {
      border-bottom: 0 !important;
    }
  }

  h1,
  h2,
  h3,
  h4,
  h5,
  h6 {
    font-size: var(--font-size-normal);
  }
}

.show--quoted {
  blockquote {
    display: block;
  }
}

.hide--quoted {
  blockquote {
    display: none;
  }
}

.quoted-text--button {
  color: var(--s-400);
  cursor: pointer;
  font-size: var(--font-size-mini);
  padding-bottom: var(--space-small);
  padding-top: var(--space-small);

  .fluent-icon {
    margin-bottom: var(--space-minus-smaller);
  }
}
</style>
