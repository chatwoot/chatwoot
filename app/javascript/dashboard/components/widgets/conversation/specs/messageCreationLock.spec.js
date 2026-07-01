import { shallowMount } from '@vue/test-utils';

import CopilotEditorSection from '../CopilotEditorSection.vue';
import MessagesView from '../MessagesView.vue';
import ReplyBox from '../ReplyBox.vue';
import ReplyBottomPanel from '../../WootWriter/ReplyBottomPanel.vue';

const mountCopilotEditorSection = props =>
  shallowMount(CopilotEditorSection, {
    props: {
      showCopilotEditor: true,
      isGeneratingContent: false,
      generatedContent: 'Suggested reply',
      ...props,
    },
    global: {
      stubs: {
        Transition: false,
        CopilotEditor: {
          template:
            '<button data-testid="copilot-editor" @click="$emit(\'send\')" />',
        },
        CaptainLoader: true,
      },
    },
  });

describe('conversation message creation lock UI', () => {
  describe('MessagesView', () => {
    it('returns the message-limit banner copy with the configured limit', () => {
      const $t = vi.fn((key, params) => `${key}:${params.limit}`);
      const message =
        MessagesView.computed.messageCreationLockBannerMessage.call({
          currentChat: {
            message_creation_locked: true,
            message_creation_lock_reason: 'message_limit',
            message_limit: 10000,
          },
          $t,
        });

      expect(message).toBe(
        'CONVERSATION.MESSAGE_CREATION_LOCK.MESSAGE_LIMIT:10000'
      );
      expect($t).toHaveBeenCalledWith(
        'CONVERSATION.MESSAGE_CREATION_LOCK.MESSAGE_LIMIT',
        { limit: 10000 }
      );
    });

    it('returns the manual lock banner copy', () => {
      const $t = vi.fn(key => key);
      const message =
        MessagesView.computed.messageCreationLockBannerMessage.call({
          currentChat: {
            message_creation_locked: true,
            message_creation_lock_reason: 'manual',
          },
          $t,
        });

      expect(message).toBe('CONVERSATION.MESSAGE_CREATION_LOCK.MANUAL');
    });
  });

  describe('ReplyBox', () => {
    it('disables the editor when message creation is locked', () => {
      const isDisabled = ReplyBox.computed.isEditorDisabled.call({
        isMessageCreationLocked: true,
        isAWhatsAppChannel: false,
        isAPIInbox: false,
        isOnPrivateNote: false,
        currentChat: { can_reply: true },
      });

      expect(isDisabled).toBe(true);
    });

    it('uses the locked placeholder when message creation is locked', () => {
      const placeholder = ReplyBox.computed.messagePlaceHolder.call({
        isEditorDisabled: true,
        isMessageCreationLocked: true,
        $t: key => key,
      });

      expect(placeholder).toBe('CONVERSATION.FOOTER.MESSAGE_CREATION_LOCKED');
    });
  });

  describe('ReplyBottomPanel', () => {
    it('keeps template actions available when only the editor is disabled', () => {
      const showWhatsAppTemplateButton =
        ReplyBottomPanel.computed.showWhatsAppTemplateButton.call({
          enableWhatsAppTemplates: true,
          isMessageCreationLocked: false,
        });
      const showContentTemplateButton =
        ReplyBottomPanel.computed.showContentTemplateButton.call({
          enableContentTemplates: true,
          isMessageCreationLocked: false,
        });

      expect(showWhatsAppTemplateButton).toBe(true);
      expect(showContentTemplateButton).toBe(true);
    });

    it('hides template actions when message creation is locked', () => {
      const showWhatsAppTemplateButton =
        ReplyBottomPanel.computed.showWhatsAppTemplateButton.call({
          enableWhatsAppTemplates: true,
          isMessageCreationLocked: true,
        });
      const showContentTemplateButton =
        ReplyBottomPanel.computed.showContentTemplateButton.call({
          enableContentTemplates: true,
          isMessageCreationLocked: true,
        });

      expect(showWhatsAppTemplateButton).toBe(false);
      expect(showContentTemplateButton).toBe(false);
    });
  });

  describe('CopilotEditorSection', () => {
    it('keeps the follow-up editor available when message creation is unlocked', async () => {
      const wrapper = mountCopilotEditorSection({
        isMessageCreationLocked: false,
      });

      await wrapper.vm.$nextTick();

      expect(wrapper.find('[data-testid="copilot-editor"]').exists()).toBe(
        true
      );
    });

    it('hides the follow-up editor when message creation is locked', async () => {
      const wrapper = mountCopilotEditorSection({
        isMessageCreationLocked: true,
      });

      await wrapper.vm.$nextTick();

      expect(wrapper.find('[data-testid="copilot-editor"]').exists()).toBe(
        false
      );
    });
  });
});
