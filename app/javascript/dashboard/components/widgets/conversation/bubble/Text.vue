<template>
  <div
    class="message-text__wrap"
    :class="{
      'show--quoted': showQuotedContent,
      'hide--quoted': !showQuotedContent,
    }"
  >
    <div class="text-content" v-html="message"></div>
    <button
      v-if="displayQuotedButton"
      class="quoted-text--button"
      @click="toggleQuotedContent"
    >
      <span v-if="showQuotedContent">
        <i class="ion-chevron-up" />
        {{ $t('CHAT_LIST.HIDE_QUOTED_TEXT') }}
      </span>
      <span v-else>
        <i class="ion-chevron-down" />
        {{ $t('CHAT_LIST.SHOW_QUOTED_TEXT') }}
      </span>
    </button>
  </div>
</template>

<script>
export default {
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
  },
  data() {
    return {
      showQuotedContent: false,
    };
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
    all: revert;

    td {
      all: revert;
    }

    tr {
      all: revert;
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
}
</style>
