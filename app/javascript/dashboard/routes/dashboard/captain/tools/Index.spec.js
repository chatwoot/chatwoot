import { flushPromises, shallowMount } from '@vue/test-utils';
import Index from './Index.vue';

const mocks = vi.hoisted(() => ({
  alerts: vi.fn(),
  dialogClose: vi.fn(),
  dialogOpen: vi.fn(),
  dispatch: vi.fn(),
  getterValues: null,
}));

const translate = (key, params = {}) => {
  if (key === 'CAPTAIN.CUSTOM_TOOLS.DISABLE_CONFIRMATION.DESCRIPTION_OTHER') {
    return `This tool is used by ${params.count} enabled scenarios.`;
  }
  if (key === 'CAPTAIN.CUSTOM_TOOLS.DISABLE_CONFIRMATION.TITLE') {
    return `Disable ${params.title}?`;
  }
  return key;
};

vi.mock('dashboard/composables/store', async () => {
  const { ref } = await import('vue');
  mocks.getterValues = {
    'captainCustomTools/getRecords': ref([
      {
        id: 7,
        title: 'Order lookup',
        description: 'Looks up an order',
        enabled: true,
        created_at: 1_700_000_000,
        updated_at: 1_700_000_000,
      },
    ]),
    'captainCustomTools/getMeta': ref({ totalCount: 1, page: 1 }),
    'captainCustomTools/getUIFlags': ref({ fetchingList: false }),
  };

  return {
    useStore: () => ({ dispatch: mocks.dispatch }),
    useMapGetter: key => mocks.getterValues[key],
  };
});

vi.mock('dashboard/composables', () => ({ useAlert: mocks.alerts }));

vi.mock('dashboard/composables/usePolicy', () => ({
  usePolicy: () => ({
    isFeatureFlagEnabled: () => true,
    shouldShowPaywall: () => false,
  }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: translate }),
}));

const PageLayoutStub = {
  inheritAttrs: false,
  emits: ['click'],
  template: '<div><slot name="body" /></div>',
};

const CustomToolCardStub = {
  props: ['id', 'enabled', 'isUpdating'],
  emits: ['toggle'],
  template: `
    <button
      data-test="toggle"
      :disabled="isUpdating"
      @click="$emit('toggle', { id, enabled: !enabled })"
    />
  `,
};

const DialogStub = {
  props: ['title', 'description', 'confirmButtonLabel', 'isLoading'],
  emits: ['confirm', 'close'],
  methods: {
    open() {
      mocks.dialogOpen();
    },
    close() {
      mocks.dialogClose();
      this.$emit('close');
    },
  },
  template: `
    <div data-test="disable-dialog">
      <button data-test="confirm" @click="$emit('confirm')" />
    </div>
  `,
};

const mountIndex = () =>
  shallowMount(Index, {
    global: {
      mocks: { $t: translate },
      stubs: {
        PageLayout: PageLayoutStub,
        CaptainPaywall: true,
        CustomToolsPageEmptyState: true,
        CreateCustomToolDialog: true,
        CustomToolCard: CustomToolCardStub,
        DeleteDialog: true,
        Dialog: DialogStub,
      },
    },
  });

describe('Captain custom tools', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.dispatch.mockResolvedValue(undefined);
  });

  it('confirms before disabling a tool used by enabled scenarios', async () => {
    mocks.dispatch.mockImplementation(action => {
      if (action === 'captainCustomTools/show') {
        return Promise.resolve({
          id: 7,
          title: 'Order lookup',
          enabled_scenarios_count: 2,
        });
      }
      return Promise.resolve();
    });
    const wrapper = mountIndex();

    await flushPromises();
    await wrapper.get('[data-test="toggle"]').trigger('click');
    await flushPromises();

    expect(mocks.dispatch).toHaveBeenCalledWith('captainCustomTools/show', 7);
    expect(mocks.dispatch).not.toHaveBeenCalledWith(
      'captainCustomTools/update',
      expect.anything()
    );
    expect(mocks.dialogOpen).toHaveBeenCalledOnce();
    expect(wrapper.findComponent(DialogStub).props('description')).toBe(
      'This tool is used by 2 enabled scenarios.'
    );

    await wrapper.get('[data-test="confirm"]').trigger('click');
    await flushPromises();

    expect(mocks.dispatch).toHaveBeenCalledWith('captainCustomTools/update', {
      id: 7,
      enabled: false,
    });
    expect(mocks.dialogClose).toHaveBeenCalledOnce();
  });

  it('disables immediately when no enabled scenarios use the tool', async () => {
    mocks.dispatch.mockImplementation(action => {
      if (action === 'captainCustomTools/show') {
        return Promise.resolve({
          id: 7,
          title: 'Order lookup',
          enabled_scenarios_count: 0,
        });
      }
      return Promise.resolve();
    });
    const wrapper = mountIndex();

    await flushPromises();
    await wrapper.get('[data-test="toggle"]').trigger('click');
    await flushPromises();

    expect(mocks.dispatch).toHaveBeenCalledWith('captainCustomTools/update', {
      id: 7,
      enabled: false,
    });
    expect(mocks.dialogOpen).not.toHaveBeenCalled();
  });
});
