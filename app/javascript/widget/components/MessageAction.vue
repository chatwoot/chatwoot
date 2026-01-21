<template>
  <div class="tags-container mt-2">
    <button
      v-if="!shouldHideThatHelpedButton"
      class="tag-button bg-[#FAFAFA] hover:bg-[#F2F2F2]"
      :disabled="isUpdating"
      @click="handleTagClick('that_helped')"
    >
      That Helped
    </button>
    <button
      class="tag-button bg-[#FAFAFA] hover:bg-[#F2F2F2]"
      :disabled="isUpdating"
      @click="handleTagClick('need_more_help')"
    >
      Need More Help
    </button>
    <button
      v-if="shouldHideThatHelpedButton"
      class="tag-button bg-[#FAFAFA] hover:bg-[#F2F2F2]"
      :disabled="isUpdating"
      @click="handleTagClick('main_menu')"
    >
      Main Menu
    </button>
  </div>
</template>

<script>
import { mapActions } from 'vuex';
import configMixin from '../mixins/configMixin';
import ContactsAPI from '../api/contacts';

export default {
  name: 'MessageAction',
  mixins: [configMixin],
  data() {
    return {
      isUpdating: false,
    };
  },
  computed: {
    filteredTags() {
      return this.tags.filter(tag => tag.text != null && tag.text !== '');
    },
    shouldHideThatHelpedButton() {
      return (
        this.channelConfig.messageActionSettings?.hide_that_helped_button ===
        true
      );
    },
  },
  methods: {
    ...mapActions('conversation', ['sendMessage']),
    async handleTagClick(tag) {
      this.isUpdating = true;
      try {
        if (tag === 'that_helped') {
          await this.sendMessage({
            content: 'That Helped',
            selectedReply: tag.id,
            conversationResolved: true,
          });
        } else if (tag === 'main_menu') {
          await this.sendMessage({
            content: 'Main Menu',
            selectedReply: tag.id,
          });
          await ContactsAPI.sendMainMenuMessage();
        } else if (this.channelConfig.needMoreHelpType === 'assign_to_agent') {
          await this.sendMessage({
            content: 'Need More Help',
            selectedReply: tag.id,
            assignToAgent: true,
          });
        } else if (
          this.channelConfig.needMoreHelpType === 'redirect_to_whatsapp'
        ) {
          await this.sendMessage({
            content: 'Need More Help',
            selectedReply: tag.id,
          });
          const data = await ContactsAPI.getWhatsappRedirectURL();
          if (data.data?.whatsappUrl) {
            window.open(data.data?.whatsappUrl, '_blank');
          }
        } else if (
          this.channelConfig.needMoreHelpType === 'send_custom_message'
        ) {
          await this.sendMessage({
            content: 'Need More Help',
            selectedReply: tag.id,
          });
          await ContactsAPI.sendCustomNeedHelpMessage();
        }
      } catch (error) {
        // Ignore error
      } finally {
        this.isUpdating = false;
      }
    },
  },
};
</script>

<style scoped>
.tags-container {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tag-button {
  border: 1px solid #d9d9d9;
  border-radius: 8px;
  padding: 6px 12px;
  font-size: 14px;
  cursor: pointer;
  outline: none;
  color: #262626;
  font-weight: 500;
}

.selected-tag {
  opacity: 0.5;
}
</style>
