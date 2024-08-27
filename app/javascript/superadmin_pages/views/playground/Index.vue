<script>
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import PlaygroundHeader from '../../components/playground/Header.vue';
import UserMessage from '../../components/playground/UserMessage.vue';
import BotMessage from '../../components/playground/BotMessage.vue';
import TypingIndicator from '../../components/playground/TypingIndicator.vue';

export default {
  components: {
    PlaygroundHeader,
    UserMessage,
    BotMessage,
    TypingIndicator,
  },
  props: {
    componentData: {
      type: Object,
      default: () => ({}),
    },
  },
  setup() {
    const { formatMessage } = useMessageFormatter();
    return {
      formatMessage,
    };
  },
  data() {
    return { messages: [], messageContent: '', isWaiting: false };
  },
  computed: {
    previousMessages() {
      return this.messages.map(message => ({
        type: message.type,
        message: message.content,
      }));
    },
  },
  mounted() {
    this.focusInput();
  },
  methods: {
    focusInput() {
      this.$refs.messageInput.focus();
    },
    onMessageSend() {
      this.addMessageToData('User', this.messageContent);
      this.sendMessageToServer(this.messageContent);
    },
    scrollToLastMessage() {
      this.$nextTick(() => {
        const messageId = this.messages[this.messages.length - 1].id;
        const messageElement = document.getElementById(`message-${messageId}`);
        messageElement.scrollIntoView({ behavior: 'smooth' });
      });
    },
    addMessageToData(type, content) {
      this.messages.push({ id: this.messages.length, type, content });
      this.scrollToLastMessage();
    },
    async sendMessageToServer(messageContent) {
      this.messageContent = '';
      this.isWaiting = true;
      const csrfToken = document
        .querySelector('meta[name="csrf-token"]')
        .getAttribute('content');

      try {
        const response = await fetch(window.location.href, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken,
          },
          body: JSON.stringify({
            message: messageContent,
            previous_messages: this.previousMessages,
          }),
          credentials: 'include',
        });

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const { message } = await response.json();
        this.addMessageToData('Bot', message);
      } catch (error) {
        this.addMessageToData(
          'bot',
          'Error: Could not retrieve response. Please check the console for more details.'
        );
      } finally {
        this.isWaiting = false;
        this.focusInput();
      }
    },
  },
};
</script>

<template>
  <section class="flex flex-col w-full h-full bg-slate-25">
    <PlaygroundHeader
      :response-source-name="componentData.responseSourceName"
      :response-source-path="componentData.responseSourcePath"
    />
    <div class="flex-1 px-8 py-4 overflow-auto">
      <div
        v-for="message in messages"
        :id="`message-${message.id}`"
        :key="message.id"
      >
        <UserMessage
          v-if="message.type === 'User'"
          :message="formatMessage(message.content)"
        />
        <BotMessage v-else :message="formatMessage(message.content)" />
      </div>
      <TypingIndicator v-if="isWaiting" />
    </div>
    <div class="w-full px-8 py-6">
      <textarea
        ref="messageInput"
        v-model="messageContent"
        :rows="4"
        class="resize-none block p-2.5 w-full text-sm text-gray-900 bg-gray-50 rounded-lg border !outline-2 border-slate-100 focus:ring-woot-500 focus:border-woot-500 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-woot-500 dark:focus:border-woot-500"
        placeholder="Type a message... [CMD/CTRL + Enter to send]"
        autofocus
        autocomplete="off"
        @keydown.meta.enter="onMessageSend"
        @keydown.ctrl.enter="onMessageSend"
      />
    </div>
  </section>
</template>
