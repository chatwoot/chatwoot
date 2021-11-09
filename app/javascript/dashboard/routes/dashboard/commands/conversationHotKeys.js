import { mapGetters } from 'vuex';
import wootConstants from '../../../constants';
import agentMixin from 'dashboard/mixins/agentMixin';
import {
  CMD_MUTE_CONVERSATION,
  CMD_REOPEN_CONVERSATION,
  CMD_RESOLVE_CONVERSATION,
  CMD_SNOOZE_CONVERSATION,
} from './commandBarBusEvents';
import {
  ICON_MUTE_CONVERSATION,
  ICON_RESOLVE_CONVERSATION,
  ICON_SNOOZE_CONVERSATION,
  ICON_SNOOZE_UNTIL_NEXT_REPLY,
  ICON_SNOOZE_UNTIL_NEXT_WEEK,
  ICON_SNOOZE_UNTIL_TOMORRROW,
} from './CommandBarIcons';

export default {
  mixins: [agentMixin],
  watch: {
    assignableAgents() {
      this.setCommandbarData();
    },
    currentChat() {
      this.setCommandbarData();
    },
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),
    inboxId() {
      return this.currentChat.inbox_id;
    },
    statusActions() {
      const isOpen = this.currentChat.status === wootConstants.STATUS_TYPE.OPEN;
      const isResolved =
        this.currentChat.status === wootConstants.STATUS_TYPE.RESOLVED;

      let actions = [];

      if (isOpen) {
        actions = [
          {
            id: 'resolve_conversation',
            title: 'Resolve conversation',
            hotkey: 'cmd+e',
            section: 'Conversation',
            icon: ICON_RESOLVE_CONVERSATION,
            handler: () => bus.$emit(CMD_RESOLVE_CONVERSATION),
          },
          {
            id: 'Snooze Conversation',
            title: 'Snooze conversation',
            icon: ICON_SNOOZE_CONVERSATION,
            children: ['until_next_reply', 'until_tomorrow', 'until_next_week'],
          },
          {
            id: 'until_next_reply',
            title: 'Until next reply',
            parent: 'Snooze Conversation',
            icon: ICON_SNOOZE_UNTIL_NEXT_REPLY,
            handler: () => bus.$emit(CMD_SNOOZE_CONVERSATION, 'nextReply'),
          },
          {
            id: 'until_tomorrow',
            title: 'Until tomorrow',
            parent: 'Snooze Conversation',
            icon: ICON_SNOOZE_UNTIL_TOMORRROW,
            handler: () => bus.$emit(CMD_SNOOZE_CONVERSATION, 'tomorrow'),
          },
          {
            id: 'until_next_week',
            title: 'Until next week',
            parent: 'Snooze Conversation',
            icon: ICON_SNOOZE_UNTIL_NEXT_WEEK,
            handler: () => bus.$emit(CMD_SNOOZE_CONVERSATION, 'nextWeek'),
          },
        ];
      } else if (isResolved) {
        actions = [
          {
            id: 'reopen_conversation',
            title: 'Reopen conversation',
            hotkey: 'cmd+c',
            section: 'Conversation',
            icon: `<svg role="img" class="ninja-icon ninja-icon--fluent" width="18" height="18" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M19.25 2a.75.75 0 0 0-.743.648l-.007.102v5.69l-4.574-4.56a6.41 6.41 0 0 0-8.878-.179l-.186.18a6.41 6.41 0 0 0 0 9.063l8.845 8.84a.75.75 0 0 0 1.06-1.062l-8.845-8.838a4.91 4.91 0 0 1 6.766-7.112l.178.17L17.438 9.5H11.75a.75.75 0 0 0-.743.648L11 10.25c0 .38.282.694.648.743l.102.007h7.5a.75.75 0 0 0 .743-.648L20 10.25v-7.5a.75.75 0 0 0-.75-.75Z" fill="currentColor"/></svg>`,
            handler: () => bus.$emit(CMD_REOPEN_CONVERSATION),
          },
        ];
      }
      return actions;
    },
    assignActions() {
      const agentOptions = this.agentsList.map(agent => ({
        id: `agent-${agent.id}`,
        title: agent.name,
        parent: 'assign_an_agent',
        section: 'Change Assignee',
        uniqueIdentifier: agent.id,
        icon: `<svg role="img" class="ninja-icon ninja-icon--fluent" width="18" height="18" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M17.5 12a5.5 5.5 0 1 1 0 11 5.5 5.5 0 0 1 0-11Zm-5.478 2a6.474 6.474 0 0 0-.708 1.5h-7.06a.75.75 0 0 0-.75.75v.907c0 .656.286 1.279.783 1.706C5.545 19.945 7.44 20.501 10 20.501c.599 0 1.162-.03 1.688-.091.25.5.563.964.93 1.38-.803.141-1.676.21-2.618.21-2.89 0-5.128-.656-6.691-2a3.75 3.75 0 0 1-1.305-2.843v-.907A2.25 2.25 0 0 1 4.254 14h7.768Zm4.697.588-.069.058-2.515 2.517-.041.05-.035.058-.032.078-.012.043-.01.086.003.088.019.085.032.078.025.042.05.066 2.516 2.516a.5.5 0 0 0 .765-.638l-.058-.069L15.711 18h4.79a.5.5 0 0 0 .491-.41L21 17.5a.5.5 0 0 0-.41-.492L20.5 17h-4.789l1.646-1.647a.5.5 0 0 0 .058-.637l-.058-.07a.5.5 0 0 0-.638-.058ZM10 2.004a5 5 0 1 1 0 10 5 5 0 0 1 0-10Zm0 1.5a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7Z" fill="currentColor"/></svg>`,
        handler: () => this.openRoute(`accounts/${this.accountId}/dashboard`),
      }));
      return [
        {
          id: 'assign_an_agent',
          title: 'Assign an agent',
          section: 'Conversation',
          icon: `<svg role="img" class="ninja-icon ninja-icon--fluent" width="18" height="18" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M17.5 12a5.5 5.5 0 1 1 0 11 5.5 5.5 0 0 1 0-11Zm-5.478 2a6.474 6.474 0 0 0-.708 1.5h-7.06a.75.75 0 0 0-.75.75v.907c0 .656.286 1.279.783 1.706C5.545 19.945 7.44 20.501 10 20.501c.599 0 1.162-.03 1.688-.091.25.5.563.964.93 1.38-.803.141-1.676.21-2.618.21-2.89 0-5.128-.656-6.691-2a3.75 3.75 0 0 1-1.305-2.843v-.907A2.25 2.25 0 0 1 4.254 14h7.768Zm4.697.588-.069.058-2.515 2.517-.041.05-.035.058-.032.078-.012.043-.01.086.003.088.019.085.032.078.025.042.05.066 2.516 2.516a.5.5 0 0 0 .765-.638l-.058-.069L15.711 18h4.79a.5.5 0 0 0 .491-.41L21 17.5a.5.5 0 0 0-.41-.492L20.5 17h-4.789l1.646-1.647a.5.5 0 0 0 .058-.637l-.058-.07a.5.5 0 0 0-.638-.058ZM10 2.004a5 5 0 1 1 0 10 5 5 0 0 1 0-10Zm0 1.5a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7Z" fill="currentColor"/></svg>`,
          children: agentOptions.map(option => option.id),
        },
        ...agentOptions,
      ];
    },
    conversationHotKeys() {
      if (
        [
          'inbox_conversation',
          'conversation_through_inbox',
          'conversations_through_label',
          'conversations_through_team',
        ].includes(this.$route.name)
      ) {
        return [
          ...this.statusActions,
          {
            id: 'mute_conversation',
            title: 'Mute conversation',
            hotkey: 'cmd+m',
            section: 'Conversation',
            icon: ICON_MUTE_CONVERSATION,
            handler: () => bus.$emit(CMD_MUTE_CONVERSATION),
          },
          {
            id: 'send_a_transcript',
            title: 'Send an email transcript',
            section: 'Conversation',
            icon: `<svg role="img" class="ninja-icon ninja-icon--fluent" width="18" height="18" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M19.75 11.5a.75.75 0 0 1 .743.648l.007.102v5a4.75 4.75 0 0 1-4.533 4.745L15.75 22h-7.5c-.98 0-1.813-.626-2.122-1.5h9.622l.184-.005a3.25 3.25 0 0 0 3.06-3.06L19 17.25v-5a.75.75 0 0 1 .75-.75Zm-2.5-2a.75.75 0 0 1 .743.648l.007.102v7a2.25 2.25 0 0 1-2.096 2.245l-.154.005h-10a2.25 2.25 0 0 1-2.245-2.096L3.5 17.25v-7a.75.75 0 0 1 1.493-.102L5 10.25v7c0 .38.282.694.648.743L5.75 18h10a.75.75 0 0 0 .743-.648l.007-.102v-7a.75.75 0 0 1 .75-.75ZM6.218 6.216l3.998-3.996a.75.75 0 0 1 .976-.073l.084.072 4.004 3.997a.75.75 0 0 1-.976 1.134l-.084-.073-2.72-2.714v9.692a.75.75 0 0 1-.648.743l-.102.007a.75.75 0 0 1-.743-.648L10 14.255V4.556L7.279 7.277a.75.75 0 0 1-.977.072l-.084-.072a.75.75 0 0 1-.072-.977l.072-.084 3.998-3.996-3.998 3.996Z" fill="currentColor"/></svg>`,
            handler: () =>
              this.openRoute(`accounts/${this.accountId}/dashboard`),
          },
          ...this.assignActions,
          {
            id: 'add_a_label_to_the_conversation',
            title: 'Add label to the conversation',
            section: 'Conversation',
            icon: `<svg role="img" class="ninja-icon ninja-icon--fluent" width="18" height="18" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M19.75 2A2.25 2.25 0 0 1 22 4.25v5.462a3.25 3.25 0 0 1-.952 2.298l-8.5 8.503a3.255 3.255 0 0 1-4.597.001L3.489 16.06a3.25 3.25 0 0 1-.003-4.596l8.5-8.51A3.25 3.25 0 0 1 14.284 2h5.465Zm0 1.5h-5.465c-.465 0-.91.185-1.239.513l-8.512 8.523a1.75 1.75 0 0 0 .015 2.462l4.461 4.454a1.755 1.755 0 0 0 2.477 0l8.5-8.503a1.75 1.75 0 0 0 .513-1.237V4.25a.75.75 0 0 0-.75-.75ZM17 5.502a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3Z" fill="currentColor"/></svg>`,
            handler: () =>
              this.openRoute(`accounts/${this.accountId}/dashboard`),
          },
          {
            id: 'remove_a_label_to_the_conversation',
            title: 'Remove label from the conversation',
            section: 'Conversation',
            icon: `<svg role="img" class="ninja-icon ninja-icon--fluent" width="18" height="18" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M19.75 2A2.25 2.25 0 0 1 22 4.25v5.462a3.25 3.25 0 0 1-.952 2.298l-.026.026a6.473 6.473 0 0 0-1.43-.692l.395-.395a1.75 1.75 0 0 0 .513-1.237V4.25a.75.75 0 0 0-.75-.75h-5.466c-.464 0-.91.185-1.238.513l-8.512 8.523a1.75 1.75 0 0 0 .015 2.462l4.461 4.454a1.755 1.755 0 0 0 2.33.13c.165.487.386.947.654 1.374a3.256 3.256 0 0 1-4.043-.442L3.489 16.06a3.25 3.25 0 0 1-.004-4.596l8.5-8.51a3.25 3.25 0 0 1 2.3-.953h5.465ZM17 5.502a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3ZM17.5 23a5.5 5.5 0 1 0 0-11 5.5 5.5 0 0 0 0 11Zm-2.354-7.854a.5.5 0 0 1 .708 0l1.646 1.647 1.646-1.647a.5.5 0 0 1 .708.708L18.207 17.5l1.647 1.646a.5.5 0 0 1-.708.708L17.5 18.207l-1.646 1.647a.5.5 0 0 1-.708-.708l1.647-1.646-1.647-1.646a.5.5 0 0 1 0-.708Z" fill="currentColor"/></svg>`,
            handler: () =>
              this.openRoute(`accounts/${this.accountId}/dashboard`),
          },
        ];
      }

      return [];
    },
  },
};
