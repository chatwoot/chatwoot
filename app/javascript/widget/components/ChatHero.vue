<template>
  <elevated-sheet is-collapsed>
    <div class="flex flex-col relative pb-4 ">
      <div
        class="flex flex-col mt-6 opacity-100 group-[.is-collapsed]:opacity-0"
      >
        <h2 class="text-base font-bold leading-6 text-slate-900 mb-1 ">
          {{ $t('CHAT_SECTION.TITLE') }}
        </h2>
        <p class="text-sm leading-6 text-slate-700 my-2">
          <slot />
        </p>
      </div>
      <div
        v-if="hasConversation"
        class="my-2"
        :class="{
          'sticky bottom-2': hasConversation,
        }"
      >
        <continue-chat-button
          :title="$t('CHAT_SECTION.CONTINUE_CHAT_TITLE')"
          :content="$t('CHAT_SECTION.CONTINUE_CHAT_BODY')"
          @continue="startConversation"
        />
      </div>
      <div
        :class="{
          'sticky bottom-3': !hasConversation,
        }"
        class="rounded-lg bg-white"
      >
        <start-chat-button
          :text="$t('CHAT_SECTION.START_CONVERSATION')"
          @start="startConversation"
        />
      </div>
      <arrow-button
        v-if="hasConversation"
        :text="$t('CHAT_SECTION.SEE_ALL_CHATS')"
        @click="showAllChats"
      />
    </div>
  </elevated-sheet>
</template>

<script>
import ArrowButton from './ArrowButton.vue';
import ContinueChatButton from './ContinueChatButton.vue';
import ElevatedSheet from './ElevatedSheet.vue';
import StartChatButton from './StartChatButton.vue';

export default {
  components: {
    ArrowButton,
    ContinueChatButton,
    ElevatedSheet,
    StartChatButton,
  },
  props: {
    hasConversation: {
      type: Boolean,
      default: false,
    },
  },
  methods: {
    startConversation() {
      this.$emit('start');
    },
    showAllChats() {
      this.$emit('all-chats');
    },
  },
};
</script>
