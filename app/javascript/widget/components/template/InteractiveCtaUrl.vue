<script>
import CardButton from 'shared/components/CardButton.vue';

export default {
  components: {
    CardButton,
  },
  props: {
    message: {
      type: String,
      default: '',
    },
    messageContentAttributes: {
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    bodyText() {
      return this.messageContentAttributes.body_text || this.message;
    },
    footerText() {
      return this.messageContentAttributes.footer_text || '';
    },
    headerMediaUrl() {
      return this.messageContentAttributes.header?.media_url || '';
    },
    action() {
      const action = this.messageContentAttributes.action || {};
      return {
        type: 'url',
        text: action.text,
        uri: action.uri,
      };
    },
  },
};
</script>

<template>
  <div
    class="chat-bubble agent bg-n-background dark:bg-n-solid-3 text-n-slate-12 max-w-80 rounded-lg overflow-hidden"
  >
    <img
      v-if="headerMediaUrl"
      :src="headerMediaUrl"
      :alt="bodyText"
      class="w-full h-40 object-cover"
    />

    <div class="px-4 pt-4 pb-3">
      <p class="text-base font-medium text-n-slate-12">
        {{ bodyText }}
      </p>
      <p v-if="footerText" class="mt-2 text-sm text-n-slate-11">
        {{ footerText }}
      </p>
    </div>

    <div class="px-3 py-3 border-t border-n-strong">
      <CardButton :action="action" />
    </div>
  </div>
</template>
