import { mount } from '@vue/test-utils';

import TemplatesPicker from '../TemplatesPicker.vue';

const { dispatch, inbox, templates } = vi.hoisted(() => ({
  dispatch: vi.fn(),
  inbox: { value: {} },
  templates: { value: [] },
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('dashboard/composables/store', () => ({
  useFunctionGetter: key =>
    key === 'inboxes/getVisibleWhatsAppTemplates' ? templates : inbox,
  useStore: () => ({ dispatch }),
}));

const baseTemplate = {
  status: 'APPROVED',
  language: 'en_US',
  category: 'UTILITY',
  components: [{ type: 'BODY', text: 'Hello' }],
};

const createWrapper = () =>
  mount(TemplatesPicker, {
    props: { inboxId: 1 },
    global: {
      stubs: {
        Icon: true,
        'fluent-icon': true,
      },
    },
  });

describe('TemplatesPicker', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    inbox.value = { id: 1, provider: 'whatsapp_cloud' };
    templates.value = [];
  });

  it('shows every Cloud classification and explains unavailable templates', () => {
    templates.value = [
      { ...baseTemplate, id: 1, name: 'sendable', classification: 'sendable' },
      {
        ...baseTemplate,
        id: 2,
        name: 'preview',
        classification: 'preview_only',
        classification_reason: 'parameter_adapter_unavailable',
      },
      {
        ...baseTemplate,
        id: 3,
        name: 'product',
        classification: 'unsupported',
        classification_reason: 'unsupported_by_linoo_version',
      },
    ];

    const wrapper = createWrapper();

    expect(wrapper.findAll('[data-testid="template-row"]')).toHaveLength(3);
    expect(
      wrapper
        .findAll('[data-testid="template-classification"]')
        .map(node => node.text())
    ).toEqual([
      'WHATSAPP_TEMPLATES.PICKER.CLASSIFICATIONS.SENDABLE',
      'WHATSAPP_TEMPLATES.PICKER.CLASSIFICATIONS.PREVIEW_ONLY',
      'WHATSAPP_TEMPLATES.PICKER.CLASSIFICATIONS.UNSUPPORTED',
    ]);
    expect(
      wrapper.findAll('[data-testid="template-classification-reason"]')
    ).toHaveLength(2);
  });

  it('selects only sendable Cloud templates and fails malformed classifications closed', async () => {
    templates.value = [
      { ...baseTemplate, id: 1, name: 'sendable', classification: 'sendable' },
      {
        ...baseTemplate,
        id: 2,
        name: 'preview',
        classification: 'preview_only',
        classification_reason: 'parameter_adapter_unavailable',
      },
      { ...baseTemplate, id: 3, name: 'malformed' },
    ];
    const wrapper = createWrapper();
    const rows = wrapper.findAll('[data-testid="template-row"]');

    expect(rows.map(row => row.attributes('disabled'))).toEqual([
      undefined,
      '',
      '',
    ]);
    await rows[0].trigger('click');
    await rows[1].trigger('click');
    await rows[2].trigger('click');

    expect(wrapper.emitted('onSelect')).toEqual([[templates.value[0]]]);
    expect(
      wrapper
        .findAll('[data-testid="template-classification-reason"]')[1]
        .text()
    ).toBe('WHATSAPP_TEMPLATES.PICKER.REASONS.CLASSIFICATION_UNAVAILABLE');
  });

  it('preserves selection for a sendable unclassified legacy template', async () => {
    inbox.value = { id: 1, provider: 'default' };
    templates.value = [{ ...baseTemplate, id: 1, name: 'legacy_template' }];
    const wrapper = createWrapper();
    const row = wrapper.get('[data-testid="template-row"]');

    expect(row.attributes('disabled')).toBeUndefined();
    expect(
      wrapper.find('[data-testid="template-classification"]').exists()
    ).toBe(false);
    await row.trigger('click');
    expect(wrapper.emitted('onSelect')).toEqual([[templates.value[0]]]);
  });
});
