import { flushPromises, mount } from '@vue/test-utils';
import { defineComponent, ref } from 'vue';
import ConversationList from '../ConversationList.vue';

// Remembers which conversation this instance was created for, like any
// per-row local state (hover, context menu, timers) in the real cards.
const ConversationItemStub = defineComponent({
  props: { source: { type: Object, required: true } },
  setup(props) {
    const createdFor = ref(props.source.id);
    return { createdFor };
  },
  template:
    '<div class="row" :data-id="source.id" :data-created-for="createdFor" />',
});

const conversations = ids => ids.map(id => ({ id }));

const mountList = conversationList =>
  mount(ConversationList, {
    props: { conversationList },
    global: {
      stubs: {
        ConversationItem: ConversationItemStub,
        IntersectionObserver: true,
      },
    },
  });

const renderedRows = wrapper =>
  wrapper.findAll('.row').map(row => ({
    id: row.attributes('data-id'),
    createdFor: row.attributes('data-created-for'),
  }));

const VIEWPORT_HEIGHT = 600;
const ROW_HEIGHT = 50;

// jsdom has no layout, so virtua never learns the viewport or row sizes and
// renders no rows. Report fixed sizes the way a browser ResizeObserver would.
class ResizeObserverStub {
  constructor(callback) {
    this.callback = callback;
  }

  observe(target) {
    const height = target.classList.contains('conversations-list')
      ? VIEWPORT_HEIGHT
      : ROW_HEIGHT;
    queueMicrotask(() =>
      this.callback([{ target, contentRect: { height, width: 300 } }])
    );
  }

  unobserve = vi.fn();

  disconnect = vi.fn();
}

// virtua ignores elements without an offsetParent, which jsdom always returns as null.
Object.defineProperty(HTMLElement.prototype, 'offsetParent', {
  get: () => document.body,
});
vi.stubGlobal('ResizeObserver', ResizeObserverStub);

// virtua attaches its scroll container in a requestAnimationFrame callback,
// then measures it through the ResizeObserver.
const waitForVirtualizer = async () => {
  await new Promise(resolve => {
    requestAnimationFrame(resolve);
  });
  await flushPromises();
};

describe('ConversationList', () => {
  it('renders a row for every conversation', async () => {
    const wrapper = mountList(conversations(['1', '2', '3']));
    await waitForVirtualizer();

    expect(renderedRows(wrapper).map(row => row.id)).toEqual(['1', '2', '3']);
  });

  it('keeps each row instance tied to its conversation when the list is reordered', async () => {
    const wrapper = mountList(conversations(['1', '2', '3']));
    await waitForVirtualizer();

    await wrapper.setProps({
      conversationList: conversations(['3', '1', '2']),
    });
    await waitForVirtualizer();

    expect(renderedRows(wrapper)).toEqual([
      { id: '3', createdFor: '3' },
      { id: '1', createdFor: '1' },
      { id: '2', createdFor: '2' },
    ]);
  });

  it('keeps each row instance tied to its conversation when one is removed', async () => {
    const wrapper = mountList(conversations(['1', '2', '3']));
    await waitForVirtualizer();

    await wrapper.setProps({ conversationList: conversations(['2', '3']) });
    await waitForVirtualizer();

    expect(renderedRows(wrapper)).toEqual([
      { id: '2', createdFor: '2' },
      { id: '3', createdFor: '3' },
    ]);
  });
});
