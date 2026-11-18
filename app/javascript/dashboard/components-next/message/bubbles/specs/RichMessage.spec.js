import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import RichMessage from '../RichMessage.vue';
import BaseBubble from '../Base.vue';
import { provideMessageContext } from '../../provider.js';
import ptBR from 'dashboard/i18n/fazer-ai/locale/pt_BR/conversation.json';
import en from 'dashboard/i18n/fazer-ai/locale/en/conversation.json';

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: () => ref([]),
}));

// Cards as the connector and the Baileys parser store them in content_attributes.rich,
// deep-camelized by MessageList. Fictitious store data.
const LIST = {
  type: 'list',
  body: 'Escolha um horário para a visita',
  footer: 'Loja Exemplo',
  buttons: [
    { text: '09:00' },
    { text: '10:00' },
    { text: '11:00' },
    { text: '14:00' },
  ],
};
const BUTTONS = {
  type: 'buttons',
  body: 'Podemos confirmar a visita?',
  buttons: [{ text: 'Confirmar' }, { text: 'Reagendar' }],
};

const i18n = locale =>
  createI18n({ legacy: false, locale, messages: { pt_BR: ptBR, en } });

const directives = {
  dompurifyHtml: (el, binding) => {
    el.innerHTML = binding.value;
  },
};

const mountRich = (rich, { locale = 'pt_BR' } = {}) => {
  const Host = defineComponent({
    components: { RichMessage },
    setup() {
      provideMessageContext({
        id: ref(1),
        content: ref(''),
        attachments: ref([]),
        contentAttributes: ref({ rich }),
      });
    },
    template: '<RichMessage />',
  });
  return mount(Host, {
    global: {
      plugins: [i18n(locale)],
      directives,
      stubs: {
        BaseBubble: { template: '<div><slot /></div>' },
        Icon: { props: ['icon'], template: '<i :data-icon="icon" />' },
      },
    },
  });
};

const mountQuote = inReplyTo => {
  const Host = defineComponent({
    components: { BaseBubble },
    setup() {
      provideMessageContext({
        id: ref(2),
        variant: ref('user'),
        orientation: ref('left'),
        inReplyTo: ref(inReplyTo),
        shouldGroupWithNext: ref(false),
        additionalAttributes: ref({}),
        contentAttributes: ref({}),
        isCaptainMessage: ref(false),
        showingOriginal: ref(false),
      });
    },
    template: '<BaseBubble hide-meta>10:00</BaseBubble>',
  });
  return mount(Host, {
    global: {
      plugins: [i18n('pt_BR')],
      directives,
      stubs: { QuotedProduct: true, ReferralCard: true },
    },
  });
};

describe('list card', () => {
  it('shows the body, the footer and one menu button, not the options', () => {
    const wrapper = mountRich(LIST);

    expect(wrapper.text()).toContain('Escolha um horário para a visita');
    expect(wrapper.text()).toContain('Loja Exemplo');
    const menu = wrapper.find('[data-rich-list-toggle]');
    expect(menu.exists()).toBe(true);
    expect(menu.text()).toContain('Ver opções');
    expect(menu.attributes('aria-expanded')).toBe('false');
    expect(wrapper.text()).not.toContain('09:00');
    expect(wrapper.find('[data-rich-buttons]').exists()).toBe(false);
  });

  it('opens the options in order, as text nobody can click', async () => {
    const wrapper = mountRich(LIST);

    await wrapper.find('[data-rich-list-toggle]').trigger('click');

    const options = wrapper.findAll('[data-rich-list-option]');
    expect(options.map(option => option.text())).toEqual([
      '09:00',
      '10:00',
      '11:00',
      '14:00',
    ]);
    options.forEach(option => {
      expect(option.element.tagName).toBe('LI');
      expect(option.find('a, button').exists()).toBe(false);
    });
    expect(
      wrapper.find('[data-rich-list-toggle]').attributes('aria-expanded')
    ).toBe('true');
  });

  it('labels the menu in the agent language', () => {
    const wrapper = mountRich(LIST, { locale: 'en' });

    expect(wrapper.find('[data-rich-list-toggle]').text()).toContain(
      'View options'
    );
  });

  it('keeps the body of a list that came without options and shows no empty menu', () => {
    const wrapper = mountRich({ ...LIST, buttons: undefined });

    expect(wrapper.text()).toContain('Escolha um horário para a visita');
    expect(wrapper.find('[data-rich-list-toggle]').exists()).toBe(false);
  });
});

describe('buttons card', () => {
  it('lays the buttons side by side and has no list menu', () => {
    const wrapper = mountRich(BUTTONS);

    const row = wrapper.find('[data-rich-buttons]');
    expect(row.classes()).toContain('flex-row');
    expect(row.text()).toContain('Confirmar');
    expect(row.text()).toContain('Reagendar');
    expect(wrapper.find('[data-rich-list-toggle]').exists()).toBe(false);
  });

  it('keeps a template URL button as a safe external link and drops an unsafe one', () => {
    const wrapper = mountRich({
      type: 'template',
      title: 'Finalize seu cadastro',
      body: 'Sua conta foi criada.',
      buttons: [
        { text: 'Abrir', url: 'https://example.invalid/conta' },
        { text: 'Perigo', url: 'data:text/html,<b>x</b>' },
      ],
    });

    const links = wrapper.findAll('a');
    expect(links).toHaveLength(1);
    expect(links[0].attributes('href')).toBe('https://example.invalid/conta');
    expect(links[0].attributes('target')).toBe('_blank');
    expect(links[0].attributes('rel')).toBe('noopener noreferrer');
    expect(wrapper.text()).toContain('Perigo');
  });
});

describe('quote of a card', () => {
  const quoteText = wrapper =>
    wrapper.find('.line-clamp-2').text().replace(/\s+/g, ' ').trim();

  it('quotes the body of a list, not its flattened text', () => {
    const wrapper = mountQuote({
      id: 1,
      content: 'Escolha um horário para a visita\n\n▸ 09:00\n\n▸ 10:00',
      contentAttributes: { rich: LIST },
    });

    expect(quoteText(wrapper)).toBe('Escolha um horário para a visita');
  });

  it('quotes the body of a buttons card', () => {
    const wrapper = mountQuote({
      id: 1,
      content: 'Podemos confirmar a visita?\n\n▸ Confirmar\n\n▸ Reagendar',
      contentAttributes: { rich: BUTTONS },
    });

    expect(quoteText(wrapper)).toBe('Podemos confirmar a visita?');
  });

  it('quotes the title of a card that has no body', () => {
    const wrapper = mountQuote({
      id: 1,
      content: 'Horários de sábado\n\n▸ 09:00',
      contentAttributes: {
        rich: { type: 'list', title: 'Horários de sábado', buttons: [] },
      },
    });

    expect(quoteText(wrapper)).toBe('Horários de sábado');
  });

  it('quotes the body of a card that also has a title', () => {
    const wrapper = mountQuote({
      id: 1,
      content: 'Finalize seu cadastro\n\nSua conta foi criada.\n\n▸ Abrir',
      contentAttributes: {
        rich: {
          type: 'template',
          title: 'Finalize seu cadastro',
          body: 'Sua conta foi criada.',
          buttons: [{ text: 'Abrir', url: 'https://example.invalid/conta' }],
        },
      },
    });

    expect(quoteText(wrapper)).toBe('Sua conta foi criada.');
  });

  it('quotes a catalog order by the text written from its data', () => {
    const wrapper = mountQuote({
      id: 1,
      content: 'Pedido com 2 itens',
      contentAttributes: {
        rich: { type: 'order', title: 'Loja Exemplo', order: { itemCount: 2 } },
      },
    });

    expect(quoteText(wrapper)).toBe('Pedido com 2 itens');
  });

  it('quotes a plain text message as before', () => {
    const wrapper = mountQuote({ id: 1, content: 'Pode ser às 10?' });

    expect(quoteText(wrapper)).toBe('Pode ser às 10?');
  });
});
