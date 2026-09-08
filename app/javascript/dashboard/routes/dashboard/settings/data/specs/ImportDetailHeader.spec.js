import { mount } from '@vue/test-utils';
import ImportDetailHeader from '../components/ImportDetailHeader.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

const ButtonStub = {
  name: 'Button',
  props: {
    label: { type: String, default: '' },
    icon: { type: String, default: '' },
    isLoading: { type: Boolean, default: false },
  },
  emits: ['click'],
  template: `
    <button
      :data-label="label"
      :data-icon="icon"
      :data-loading="isLoading"
      @click="$emit('click')"
    >
      {{ label }}
    </button>
  `,
};

const BaseSettingsHeaderStub = {
  template: `
    <section>
      <slot name="title" />
      <slot name="description" />
    </section>
  `,
};

const mountHeader = props =>
  mount(ImportDetailHeader, {
    props,
    global: {
      stubs: {
        Button: ButtonStub,
        BaseSettingsHeader: BaseSettingsHeaderStub,
      },
      mocks: {
        $t: key => key,
      },
    },
  });

describe('ImportDetailHeader', () => {
  const activeImport = {
    id: 1,
    name: 'Intercom import',
    data_type: 'intercom',
    source_provider: 'intercom',
    status: 'processing',
    stalled: true,
  };

  it('shows Retry between Refresh and Abandon for stalled imports', async () => {
    const wrapper = mountHeader({ dataImport: activeImport });
    const buttons = wrapper.findAll('button');

    expect(buttons.map(button => button.attributes('data-label'))).toEqual([
      '',
      'DATA_IMPORTS.TABLE.RETRY',
      'DATA_IMPORTS.TABLE.ABANDON',
    ]);

    await buttons[1].trigger('click');

    expect(wrapper.emitted('retry')).toHaveLength(1);
  });

  it('hides Retry when the server does not report the import as stalled', () => {
    const wrapper = mountHeader({
      dataImport: { ...activeImport, stalled: false },
    });

    expect(
      wrapper.find('[data-label="DATA_IMPORTS.TABLE.RETRY"]').exists()
    ).toBe(false);
  });
});
