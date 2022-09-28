<template>
  <div class="footer-wrap">
    <custom-button
      v-if="config.isDefaultScreen"
      class="start-conversation"
      :style="{ background: config.color }"
    >
      {{
        $t('INBOX_MGMT.WIDGET_BUILDER.FOOTER.START_CONVERSATION_BUTTON_TEXT')
      }}
    </custom-button>
    <div v-else class="chat-message-input is-focused">
      <resizable-text-area
        id="chat-input"
        :placeholder="
          $t('INBOX_MGMT.WIDGET_BUILDER.FOOTER.CHAT_INPUT_PLACEHOLDER')
        "
        class="user-message-input is-focused"
      />
      <div class="button-wrap">
        <fluent-icon icon="emoji" />
        <fluent-icon class="icon-send" icon="send" />
      </div>
    </div>
  </div>
</template>

<script>
import CustomButton from 'dashboard/components/buttons/Button';
import ResizableTextArea from 'shared/components/ResizableTextArea';
export default {
  name: 'WidgetFooter',
  components: {
    CustomButton,
    ResizableTextArea,
  },
  props: {
    config: {
      type: Object,
      default: () => {},
    },
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/variables.scss';
.footer-wrap {
  width: 100%;
  display: flex;
  flex-direction: column;
  position: relative;
  padding-left: var(--space-two);
  padding-right: var(--space-two);

  .start-conversation {
    justify-content: center;
    font-size: var(--font-size-small);
    border-radius: var(--border-radius-normal);
    padding-left: var(--space-two);
    padding-right: var(--space-two);
  }

  .chat-message-input {
    align-items: center;
    display: flex;
    padding: var(--space-zero) var(--space-small) var(--space-zero)
      var(--space-slab);
    border-radius: var(--border-radius-normal);
    background: white;

    &.is-focused {
      box-shadow: 0 0 0 0.1rem var(--color-woot), 0 0 0.2rem 0.2rem var(--w-100);
    }
  }

  .button-wrap {
    display: flex;
    align-items: center;
    padding-left: var(--space-small);
  }

  .user-message-input {
    border: 0;
    height: var(--space-medium);
    min-height: var(--space-medium);
    max-height: var(--space-giga);
    line-height: 1;
    font-size: var(--font-size-small);
    resize: none;
    padding: var(--space-zero);
    padding-top: var(--space-smaller);
    padding-bottom: var(--space-smaller);
    margin-top: var(--space-small);
    margin-bottom: var(--space-small);
  }

  .icon-send {
    margin-left: var(--space-one);
  }
}
</style>
