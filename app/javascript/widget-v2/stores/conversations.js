import { defineStore } from 'pinia';
import { computed, reactive, ref } from 'vue';
import {
  fetchConversations,
  fetchConversation,
  createConversation,
  resolveConversation,
  updateLastSeen,
  toggleTyping,
} from 'widget-v2/api/conversations';

const emptySection = () => ({
  ids: [],
  page: 0,
  hasNextPage: true,
  loading: false,
});

export const useConversationsStore = defineStore('conversations', () => {
  const byId = ref({});
  const sections = reactive({ human: emptySection(), ai: emptySection() });
  const typingIn = ref({}); // display_id -> true

  const upsert = conversation => {
    const existing = byId.value[conversation.id] || {};
    byId.value = {
      ...byId.value,
      [conversation.id]: { ...existing, ...conversation },
    };
  };

  const trackInSection = conversation => {
    const section = conversation.widget_section === 'ai' ? 'ai' : 'human';
    if (!sections[section].ids.includes(conversation.id)) {
      sections[section].ids.unshift(conversation.id);
    }
  };

  // Cable payloads (Conversations::EventDataPresenter) use a different shape
  // than the REST API; normalize before storing.
  const upsertFromEvent = data => {
    const conversation = {
      id: data.id,
      status: data.status,
      widget_section: data.additional_attributes?.widget_section || 'human',
      assignee: data.meta?.assignee
        ? {
            name: data.meta.assignee.available_name || data.meta.assignee.name,
            avatar_url:
              data.meta.assignee.thumbnail || data.meta.assignee.avatar_url,
          }
        : null,
      last_activity_at: data.last_activity_at,
      contact_last_seen_at: data.contact_last_seen_at,
    };
    upsert(conversation);
    trackInSection(conversation);
  };

  const sectionConversations = section =>
    computed(() =>
      sections[section].ids
        .map(id => byId.value[id])
        .filter(Boolean)
        .sort((a, b) => (b.last_activity_at || 0) - (a.last_activity_at || 0))
    );

  const humanConversations = sectionConversations('human');
  const aiConversations = sectionConversations('ai');
  const totalUnread = computed(() =>
    Object.values(byId.value).reduce(
      (sum, conversation) => sum + (conversation.unread_count || 0),
      0
    )
  );

  const loadSection = async section => {
    const state = sections[section];
    if (state.loading || !state.hasNextPage) return;
    state.loading = true;
    try {
      const { payload, meta } = await fetchConversations({
        section,
        page: state.page + 1,
      });
      payload.forEach(conversation => {
        upsert(conversation);
        if (!state.ids.includes(conversation.id))
          state.ids.push(conversation.id);
      });
      state.page = meta.current_page;
      state.hasNextPage = meta.has_next_page;
    } finally {
      state.loading = false;
    }
  };

  const loadOne = async displayId => {
    const conversation = await fetchConversation(displayId);
    upsert(conversation);
    trackInSection(conversation);
    return conversation;
  };

  const create = async ({ section, content, contact }) => {
    const conversation = await createConversation({
      section,
      content,
      contact,
      referrerUrl: window.referrerURL || '',
    });
    upsert(conversation);
    trackInSection(conversation);
    return conversation;
  };

  const resolve = async displayId => {
    await resolveConversation(displayId);
    upsert({ id: displayId, status: 'resolved' });
  };

  const markSeen = async displayId => {
    const conversation = byId.value[displayId];
    if (conversation) upsert({ id: displayId, unread_count: 0 });
    await updateLastSeen(displayId);
  };

  const setTyping = (displayId, isTyping) => {
    typingIn.value = { ...typingIn.value, [displayId]: isTyping };
  };

  const notifyTyping = (displayId, status) => toggleTyping(displayId, status);

  const incrementUnread = displayId => {
    const conversation = byId.value[displayId];
    if (!conversation) return;
    upsert({
      id: displayId,
      unread_count: (conversation.unread_count || 0) + 1,
    });
  };

  return {
    byId,
    sections,
    typingIn,
    humanConversations,
    aiConversations,
    totalUnread,
    upsert,
    upsertFromEvent,
    loadSection,
    loadOne,
    create,
    resolve,
    markSeen,
    setTyping,
    notifyTyping,
    incrementUnread,
  };
});
