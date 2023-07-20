<template>
  <elevated-sheet is-collapsed>
    <div class="flex flex-col relative pb-4 ">
      <div
        class="flex flex-col mt-6 opacity-100 group-[.is-collapsed]:opacity-0"
      >
        <h2 class="text-base font-bold leading-6 text-slate-900 mb-1 ">
          Chat with us
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
        <continue-chat-button @continue="startConversation" />
      </div>
      <div
        :class="{
          'sticky bottom-2': !hasConversation,
        }"
        class="rounded-lg bg-white"
      >
        <start-chat-button @start="startConversation" />
      </div>
      <router-link v-slot="{ href }" custom :to="categoryPath">
        <a
          :href="href"
          class="flex w-full text-sm font-medium rounded-md mt-2 px-2 leading-6 text-slate-800 justify-center items-center hover:bg-slate-75 h-8 all-chat-button"
        >
          See all chats
          <span class="px-1 text-slate-700 all-chat-button">
            <fluent-icon icon="arrow-right" size="14" />
          </span>
        </a>
      </router-link>
    </div>
  </elevated-sheet>
</template>

<script>
import StartChatButton from './StartChatButton.vue';
import ElevatedSheet from './ElevatedSheet.vue';
import ContinueChatButton from './ContinueChatButton.vue';

export default {
  components: { ElevatedSheet, StartChatButton, ContinueChatButton },
  props: {
    articles: {
      type: Array,
      default: () => [],
    },
    categoryPath: {
      type: String,
      default: '',
    },
    isCollapsed: {
      type: Boolean,
      default: true,
    },
    hasConversation: {
      type: Boolean,
      default: false,
    },
  },
  methods: {
    startConversation() {
      this.$emit('start');
    },
  },
};
</script>

<style scoped>
.all-chat-button {
  color: var(--brand-textButtonClear);
}
.has-bg {
  background: var(--brand-bgLight);
}
</style>
