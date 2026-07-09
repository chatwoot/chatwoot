import { mount } from '@vue/test-utils';
import CrmKanbanCard from './CrmKanbanCard.vue';

// The card renders i18n keys + account labels from the store; stub both so we can
// mount in isolation and assert the click routing the "open conversation from the
// bubble" feature introduced (bubble -> openConversation, rest of card -> open).
vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, params) => (params ? `${key}:${JSON.stringify(params)}` : key),
  }),
}));
vi.mock('dashboard/composables/store', () => ({
  useMapGetter: () => ({ value: [] }),
}));

const CONVERSATION_CARD = {
  id: 5,
  title: 'Card A',
  last_message_at: 1700000000,
  conversation: { id: 99, display_id: 42 },
};

const NO_CONVERSATION_CARD = {
  id: 6,
  title: 'Card B',
  last_message_at: 1700000000,
};

const mountCard = (card = CONVERSATION_CARD, props = {}) =>
  mount(CrmKanbanCard, {
    props: { card, stageColor: '#2563eb', ...props },
    global: {
      stubs: {
        Avatar: true,
        ChannelIcon: true,
        CardPriorityIcon: true,
        CardLabels: true,
        SLACardLabel: true,
        CrmCardPill: true,
      },
    },
  });

describe('CrmKanbanCard bubble shortcut', () => {
  it('renders the last-message bubble as a conversation button when a linked conversation exists', () => {
    const wrapper = mountCard();

    expect(wrapper.find('button.crm-card-open-conversation').exists()).toBe(
      true
    );
  });

  it('emits openConversation (and NOT open) when the bubble is clicked', async () => {
    const wrapper = mountCard();

    await wrapper.find('button.crm-card-open-conversation').trigger('click');

    expect(wrapper.emitted('openConversation')).toHaveLength(1);
    expect(wrapper.emitted('openConversation')[0]).toEqual([CONVERSATION_CARD]);
    expect(wrapper.emitted('open')).toBeUndefined();
  });

  it('emits open when the card content is clicked', async () => {
    const wrapper = mountCard();

    // Content wrapper carries the drawer @click; clicking a content element
    // must bubble to it and open the drawer.
    await wrapper.find('div.relative.z-10').trigger('click');

    expect(wrapper.emitted('open')).toHaveLength(1);
    expect(wrapper.emitted('open')[0]).toEqual([CONVERSATION_CARD]);
    expect(wrapper.emitted('openConversation')).toBeUndefined();
  });

  it('emits open from the stretched primary button', async () => {
    const wrapper = mountCard();

    await wrapper
      .find('button[aria-label^="CRM_KANBAN.CARD.OPEN_DETAILS"]')
      .trigger('click');

    expect(wrapper.emitted('open')).toHaveLength(1);
    expect(wrapper.emitted('openConversation')).toBeUndefined();
  });

  it('keeps the bubble as a plain label (no shortcut) when the card has no conversation', async () => {
    const wrapper = mountCard(NO_CONVERSATION_CARD);

    expect(wrapper.find('button.crm-card-open-conversation').exists()).toBe(
      false
    );

    // The plain label click still bubbles up to the content wrapper -> open.
    await wrapper.find('div.relative.z-10').trigger('click');
    expect(wrapper.emitted('open')).toHaveLength(1);
    expect(wrapper.emitted('openConversation')).toBeUndefined();
  });
});
