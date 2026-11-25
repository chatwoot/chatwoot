vi.mock('dashboard/components-next/dialog/Dialog.vue', () => ({
  default: { template: '<div />' },
}));
vi.mock(
  'dashboard/components-next/Campaigns/WhatsAppCampaign/AudienceFields.vue',
  () => ({ default: { template: '<div />' } })
);
vi.mock(
  'dashboard/components-next/Campaigns/WhatsAppCampaign/TemplateFields.vue',
  () => ({ default: { template: '<div />' } })
);
vi.mock(
  'dashboard/components-next/Campaigns/WhatsAppCampaign/SchedulePopover.vue',
  () => ({ default: { template: '<div />' } })
);
import { flushPromises, shallowMount } from '@vue/test-utils';
import { nextTick, reactive, ref } from 'vue';
import WhatsAppCampaignFormPage from './WhatsAppCampaignFormPage.vue';

const mocks = vi.hoisted(() => ({
  dispatch: vi.fn(),
  health: vi.fn(),
  replace: vi.fn(),
  route: { params: {} },
  getters: {},
}));
vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: mocks.dispatch }),
  useMapGetter: key => mocks.getters[key],
}));
vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
  useTrack: vi.fn(),
}));
vi.mock('dashboard/api/inboxHealth', () => ({
  default: { getHealthStatus: mocks.health },
}));
vi.mock('vue-router', () => ({
  useRoute: () => mocks.route,
  useRouter: () => ({ push: vi.fn(), replace: mocks.replace }),
}));
vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key, te: () => false, locale: ref('en') }),
}));

const template = {
  name: 'greeting',
  language: 'en',
  category: 'UTILITY',
  components: [{ type: 'BODY', text: 'Hello {{1}}' }],
};

describe('WhatsAppCampaignFormPage', () => {
  beforeEach(() => {
    mocks.route = reactive({
      name: 'campaigns_whatsapp_edit',
      params: { campaignId: 1 },
    });
    mocks.getters = {
      'campaigns/getWhatsAppCampaigns': ref([
        {
          id: 1,
          title: 'Original',
          inbox: { id: 1 },
          campaign_status: 'active',
          scheduled_at: 2000000000,
          audience: [{ type: 'Label', id: 2 }],
          template_params: {
            name: 'greeting',
            language: 'en',
            processed_params: { body: { 1: 'Jamie' } },
          },
        },
      ]),
      'labels/getLabels': ref([]),
      'inboxes/getWhatsAppInboxes': ref([{ id: 1 }]),
      'inboxes/getFilteredWhatsAppTemplates': ref(() => [template]),
      'campaigns/getUIFlags': ref({}),
    };
    mocks.health.mockResolvedValue({ data: {} });
  });

  it('hydrates and selects templates without provider IDs', () => {
    const wrapper = shallowMount(WhatsAppCampaignFormPage);
    expect(wrapper.vm.selectedTemplate).toEqual(template);
    expect(wrapper.vm.isTemplateComplete).toBe(true);
    wrapper.unmount();
  });

  it('keeps edits made during a save dirty and discards to the submitted values', async () => {
    let finish;
    mocks.dispatch.mockReturnValue(
      new Promise(resolve => {
        finish = resolve;
      })
    );
    const wrapper = shallowMount(WhatsAppCampaignFormPage);
    wrapper.vm.state.title = 'Submitted';
    const saving = wrapper.vm.handleSectionSave('basic');
    wrapper.vm.state.title = 'Edited while saving';
    finish();
    await saving;
    expect(wrapper.vm.isSectionDirty('basic')).toBe(true);
    wrapper.vm.handleDiscard('basic');
    expect(wrapper.vm.state.title).toBe('Submitted');
    wrapper.unmount();
  });

  it('does not mark a newer schedule as saved', async () => {
    let finish;
    mocks.dispatch.mockReturnValue(
      new Promise(resolve => {
        finish = resolve;
      })
    );
    const wrapper = shallowMount(WhatsAppCampaignFormPage);
    wrapper.vm.state.scheduledAt = '2035-01-01T12:00';
    const saving = wrapper.vm.handleReschedule();
    wrapper.vm.state.scheduledAt = '2035-01-02T12:00';
    finish();
    await saving;
    expect(wrapper.vm.isScheduleDirty).toBe(true);
    wrapper.vm.handleCancelReschedule();
    expect(wrapper.vm.state.scheduledAt).toBe('2035-01-01T12:00');
    wrapper.unmount();
  });

  it('ignores an earlier inbox health response after changing inbox', async () => {
    let finishFirst;
    mocks.health.mockImplementationOnce(
      () =>
        new Promise(resolve => {
          finishFirst = resolve;
        })
    );
    mocks.health.mockResolvedValueOnce({ data: { quality_rating: 'GREEN' } });
    const wrapper = shallowMount(WhatsAppCampaignFormPage);
    wrapper.vm.state.inboxId = 2;
    await nextTick();
    await flushPromises();
    finishFirst({ data: { quality_rating: 'RED' } });
    await flushPromises();
    expect(wrapper.vm.healthData).toEqual({ quality_rating: 'GREEN' });
    expect(mocks.health.mock.calls[0][1].signal.aborted).toBe(true);
    wrapper.unmount();
  });

  it.each(['processing', 'completed'])(
    'redirects direct edits of %s campaigns',
    status => {
      mocks.getters['campaigns/getWhatsAppCampaigns'].value[0].campaign_status =
        status;
      const wrapper = shallowMount(WhatsAppCampaignFormPage);
      expect(mocks.replace).toHaveBeenCalledWith({
        name: 'campaigns_whatsapp_index',
      });
      wrapper.unmount();
    }
  );

  it('disables saving a malformed or non-HTTP media URL', () => {
    const wrapper = shallowMount(WhatsAppCampaignFormPage);
    wrapper.vm.state.processedParams.header = { media_url: 'not a url' };
    expect(wrapper.vm.isTemplateComplete).toBe(false);
    wrapper.vm.state.processedParams.header.media_url =
      'ftp://example.com/image.jpg';
    expect(wrapper.vm.isTemplateComplete).toBe(false);
    wrapper.vm.state.processedParams.header.media_url =
      'https://example.com/image.jpg';
    expect(wrapper.vm.isTemplateComplete).toBe(true);
    wrapper.unmount();
  });
  it('clears template values when selecting a different inbox for a new campaign', async () => {
    mocks.route.params = {};
    const wrapper = shallowMount(WhatsAppCampaignFormPage);
    wrapper.vm.state.inboxId = 1;
    await nextTick();
    wrapper.vm.state.templateId = 'greeting:en';
    wrapper.vm.state.processedParams = { body: { 1: 'Old value' } };
    wrapper.vm.state.inboxId = 2;
    await nextTick();
    expect(wrapper.vm.state.templateId).toBeNull();
    expect(wrapper.vm.state.processedParams).toEqual({});
    wrapper.unmount();
  });
  it.each([{ 1: 'Jamie' }, ['Jamie']])(
    'hydrates legacy body parameters %j',
    params => {
      mocks.getters[
        'campaigns/getWhatsAppCampaigns'
      ].value[0].template_params.processed_params = params;
      const wrapper = shallowMount(WhatsAppCampaignFormPage);
      expect(wrapper.vm.state.processedParams).toEqual({
        body: { 1: 'Jamie' },
      });
      expect(wrapper.vm.templatePayload.message).toBe('Hello Jamie');
      expect(wrapper.vm.isSectionDirty('template')).toBe(false);
      wrapper.unmount();
    }
  );

  it('shows missing body inputs instead of treating them as complete', () => {
    mocks.getters[
      'campaigns/getWhatsAppCampaigns'
    ].value[0].template_params.processed_params = {};
    const wrapper = shallowMount(WhatsAppCampaignFormPage);
    expect(wrapper.vm.state.processedParams).toEqual({ body: { 1: '' } });
    expect(wrapper.vm.isTemplateComplete).toBe(false);
    wrapper.unmount();
  });
  it('waits for campaign loading before redirecting an unavailable edit URL', async () => {
    mocks.getters['campaigns/getWhatsAppCampaigns'].value = [];
    mocks.getters['campaigns/getUIFlags'].value = {
      isFetching: true,
      hasFetched: false,
    };
    const wrapper = shallowMount(WhatsAppCampaignFormPage);
    expect(mocks.replace).not.toHaveBeenCalled();
    mocks.getters['campaigns/getUIFlags'].value = {
      isFetching: false,
      hasFetched: true,
    };
    await nextTick();
    expect(mocks.replace).toHaveBeenCalledWith({
      name: 'campaigns_whatsapp_index',
    });
    wrapper.unmount();
  });
  it('requires dynamic button values even when the body has no variables', () => {
    mocks.getters['inboxes/getFilteredWhatsAppTemplates'].value = () => [
      {
        ...template,
        components: [
          { type: 'BODY', text: 'Your offer' },
          {
            type: 'BUTTONS',
            buttons: [
              { type: 'QUICK_REPLY', text: 'Thanks' },
              { type: 'COPY_CODE' },
            ],
          },
        ],
      },
    ];
    mocks.getters[
      'campaigns/getWhatsAppCampaigns'
    ].value[0].template_params.processed_params = {
      buttons: [null, { type: 'copy_code', parameter: '' }],
    };
    const wrapper = shallowMount(WhatsAppCampaignFormPage);
    expect(wrapper.vm.isTemplateComplete).toBe(false);
    wrapper.vm.state.processedParams.buttons[1].parameter = 'WELCOME';
    expect(wrapper.vm.isTemplateComplete).toBe(true);
    wrapper.unmount();
  });
  it.each(['body', 'header', 'buttons'])(
    'hydrates a legacy variable named %s',
    name => {
      mocks.getters['inboxes/getFilteredWhatsAppTemplates'].value = () => [
        {
          ...template,
          components: [{ type: 'BODY', text: `Hello {{${name}}}` }],
        },
      ];
      mocks.getters[
        'campaigns/getWhatsAppCampaigns'
      ].value[0].template_params.processed_params = { [name]: 'Jamie' };
      const wrapper = shallowMount(WhatsAppCampaignFormPage);
      expect(wrapper.vm.state.processedParams.body[name]).toBe('Jamie');
      expect(wrapper.vm.templatePayload.message).toBe('Hello Jamie');
      wrapper.unmount();
    }
  );

  it('does not redirect from a cached edit page after navigating to analytics', async () => {
    const wrapper = shallowMount(WhatsAppCampaignFormPage);
    mocks.route.name = 'campaigns_whatsapp_analytics';
    mocks.getters['campaigns/getWhatsAppCampaigns'].value[0].campaign_status =
      'processing';
    await nextTick();
    expect(mocks.replace).not.toHaveBeenCalled();
    mocks.route.name = 'campaigns_whatsapp_edit';
    await nextTick();
    expect(mocks.replace).toHaveBeenCalledWith({
      name: 'campaigns_whatsapp_index',
    });
    wrapper.unmount();
  });
});
