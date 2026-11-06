import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import Email from '../Email/Index.vue';
import { provideMessageContext } from '../../provider.js';
import { MESSAGE_TYPES } from '../../constants.js';

vi.mock('dashboard/composables/useTranslations', () => ({
  useTranslations: () => ({
    hasTranslations: ref(false),
    translationContent: ref(null),
  }),
}));

const html = `
  <div>New message</div>
  <div class="gmail_quote">
    <font color="black">Quoted black text</font>
    <span style="color: rgb(0, 0, 0)">Quoted inline color</span>
    <span style="color: #a25618">Colored emphasis</span>
  </div>`;

const mountEmail = messageType => {
  const Host = defineComponent({
    components: { Email },
    setup() {
      provideMessageContext({
        content: ref('New message'),
        contentAttributes: ref({ email: { htmlContent: { full: html } } }),
        attachments: ref([]),
        messageType: ref(messageType),
      });
    },
    template: '<Email />',
  });

  return mount(Host, {
    global: {
      mocks: { $t: key => key },
      stubs: {
        BaseBubble: { template: '<div><slot /></div>' },
        EmailMeta: true,
        Icon: true,
        AttachmentChips: true,
      },
    },
  });
};

describe('Email bubble colors', () => {
  it.each([MESSAGE_TYPES.INCOMING, MESSAGE_TYPES.OUTGOING])(
    'keeps both visible and quoted HTML on the light email canvas for type %s',
    async messageType => {
      const wrapper = mountEmail(messageType);
      const letter = () => wrapper.find('.letter-render');
      expect(letter().classes()).toContain('email-light-canvas');
      expect(letter().text()).toContain('New message');
      expect(letter().text()).not.toContain('Quoted black text');

      await wrapper.find('button').trigger('click');
      expect(letter().classes()).toContain('email-light-canvas');
      expect(letter().find('font').attributes('color')).toBe('black');
      expect(letter().find('span').attributes('style')).toContain(
        'color: rgb(0, 0, 0)'
      );
      expect(letter().findAll('span')[1].attributes('style')).toContain(
        '#a25618'
      );
    }
  );
});
