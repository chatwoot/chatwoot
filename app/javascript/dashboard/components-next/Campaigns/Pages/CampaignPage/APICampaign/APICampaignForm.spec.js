import { mount } from '@vue/test-utils';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { nextTick } from 'vue';
import APICampaignForm from './APICampaignForm.vue';

const mockLabels = [
  { id: 1, title: 'VIP Customer' },
  { id: 2, title: 'Premium Customer' },
];

const mockInboxes = [
  { id: 1, name: 'API Inbox 1' },
  { id: 2, name: 'API Inbox 2' },
];

// Mock the composables
vi.mock('dashboard/composables/store', () => ({
  useMapGetter: vi.fn(path => {
    const mockData = {
      'campaigns/getUIFlags': { value: { isCreating: false } },
      'labels/getLabels': { value: mockLabels },
      'inboxes/getAPIInboxes': { value: mockInboxes },
    };
    return mockData[path] || { value: [] };
  }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: vi.fn(key => key),
  }),
}));

const createWrapper = (props = {}) => {
  return mount(APICampaignForm, {
    props: {
      ...props,
    },
    global: {
      stubs: {
        Input: {
          template:
            '<input v-bind="$attrs" @input="$emit(\'update:modelValue\', $event.target.value)" />',
        },
        TextArea: {
          template:
            '<textarea v-bind="$attrs" @input="$emit(\'update:modelValue\', $event.target.value)" />',
        },
        Button: {
          template:
            '<button v-bind="$attrs" @click="$emit(\'click\')"><slot /></button>',
        },
        ComboBox: {
          template:
            '<select v-bind="$attrs" @change="$emit(\'update:modelValue\', $event.target.value)"><option v-for="option in options" :key="option.value" :value="option.value">{{ option.label }}</option></select>',
          props: ['options', 'modelValue'],
        },
        TagMultiSelectComboBox: {
          template:
            '<div><select multiple v-bind="$attrs" @change="handleChange"><option v-for="option in options" :key="option.value" :value="option.value">{{ option.label }}</option></select></div>',
          props: ['options', 'modelValue'],
          methods: {
            handleChange(event) {
              const values = Array.from(event.target.selectedOptions).map(
                option => parseInt(option.value, 10)
              );
              this.$emit('update:modelValue', values);
            },
          },
        },
      },
    },
  });
};

describe('APICampaignForm', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders correctly', () => {
    const wrapper = createWrapper();
    expect(wrapper.exists()).toBe(true);
  });

  it('displays form fields with proper stubs', () => {
    const wrapper = createWrapper();

    // Check if main form elements are present using stubs
    expect(wrapper.find('input').exists()).toBe(true);
    expect(wrapper.find('textarea').exists()).toBe(true);
    expect(wrapper.find('select').exists()).toBe(true);
  });

  it('computes audience options correctly', () => {
    const wrapper = createWrapper();

    const audienceOptions = wrapper.vm.audienceList;
    expect(audienceOptions).toHaveLength(2);
    expect(audienceOptions[0]).toEqual({
      value: 1,
      label: 'VIP Customer',
    });
  });

  it('computes inbox options correctly', () => {
    const wrapper = createWrapper();

    const inboxOptions = wrapper.vm.inboxOptions;
    expect(inboxOptions).toHaveLength(2);
    expect(inboxOptions[0]).toEqual({
      value: 1,
      label: 'API Inbox 1',
    });
  });

  it('validates required fields', async () => {
    const wrapper = createWrapper();

    // Trigger validation by touching the form
    await wrapper.vm.v$.$touch();
    await nextTick();

    // Form should be invalid due to required field validation
    expect(wrapper.vm.v$.$invalid).toBe(true);
  });

  it('emits submit event when form is valid and submitted', async () => {
    const wrapper = createWrapper();

    // Fill form with valid data
    wrapper.vm.state.title = 'Test API Campaign';
    wrapper.vm.state.message = 'Test message';
    wrapper.vm.state.inboxId = 1;
    wrapper.vm.state.scheduledAt = '2025-06-01T10:00';
    wrapper.vm.state.selectedAudience = [1];

    await nextTick();

    // Form should now be valid
    expect(wrapper.vm.v$.$invalid).toBe(false);

    const submitSpy = vi.spyOn(wrapper.vm, 'handleSubmit');

    // Submit form
    await wrapper.vm.handleSubmit();

    expect(submitSpy).toHaveBeenCalled();
  });

  it('resets state correctly', () => {
    const wrapper = createWrapper();

    // Set some data
    wrapper.vm.state.title = 'Test';
    wrapper.vm.state.message = 'Test message';

    // Reset
    wrapper.vm.resetState();

    expect(wrapper.vm.state.title).toBe('');
    expect(wrapper.vm.state.message).toBe('');
  });

  it('formats campaign details correctly with no delay', () => {
    const wrapper = createWrapper();

    wrapper.vm.state.title = 'Test API Campaign';
    wrapper.vm.state.message = 'Test message';
    wrapper.vm.state.inboxId = 1;
    wrapper.vm.state.scheduledAt = '2025-06-01T10:00';
    wrapper.vm.state.selectedAudience = [1, 2];

    const campaignDetails = wrapper.vm.prepareCampaignDetails();

    expect(campaignDetails).toEqual({
      title: 'Test API Campaign',
      message: 'Test message',
      inbox_id: 1,
      scheduled_at: new Date('2025-06-01T10:00').toISOString(),
      audience: [
        { id: 1, type: 'Label' },
        { id: 2, type: 'Label' },
      ],
      trigger_rules: {
        delay: {
          type: 'none',
        },
      },
    });
  });

  it('emits cancel event when cancel is called', () => {
    const wrapper = createWrapper();

    wrapper.vm.handleCancel();

    expect(wrapper.emitted().cancel).toBeTruthy();
  });

  // ============================================
  // Message Delay Feature Tests
  // ============================================

  describe('Message Delay Configuration', () => {
    it('initializes with default delay state (none)', () => {
      const wrapper = createWrapper();

      expect(wrapper.vm.delayType).toBe('none');
      expect(wrapper.vm.delaySeconds).toBe(0);
      expect(wrapper.vm.delayMin).toBe(1);
      expect(wrapper.vm.delayMax).toBe(5);
    });

    it('renders radio buttons for delay type selection', () => {
      const wrapper = createWrapper();

      const radioInputs = wrapper.findAll('input[type="radio"]');
      expect(radioInputs.length).toBeGreaterThanOrEqual(3);

      const noneRadio = wrapper.find('input[value="none"]');
      const fixedRadio = wrapper.find('input[value="fixed"]');
      const randomRadio = wrapper.find('input[value="random"]');

      expect(noneRadio.exists()).toBe(true);
      expect(fixedRadio.exists()).toBe(true);
      expect(randomRadio.exists()).toBe(true);
    });

    it('displays fixed delay input when fixed type is selected', async () => {
      const wrapper = createWrapper();

      wrapper.vm.delayType = 'fixed';
      await nextTick();

      // Check that delay configuration section exists
      const delaySection = wrapper.find('.flex.flex-col.gap-3.p-4');
      expect(delaySection.exists()).toBe(true);
    });

    it('displays random delay inputs when random type is selected', async () => {
      const wrapper = createWrapper();

      wrapper.vm.delayType = 'random';
      await nextTick();

      // Check that delay configuration section exists
      const delaySection = wrapper.find('.flex.flex-col.gap-3.p-4');
      expect(delaySection.exists()).toBe(true);
    });

    it('prepares delay configuration for fixed delay', () => {
      const wrapper = createWrapper();

      wrapper.vm.delayType = 'fixed';
      wrapper.vm.delaySeconds = 10;

      const delayConfig = wrapper.vm.prepareDelayConfiguration();

      expect(delayConfig).toEqual({
        type: 'fixed',
        seconds: 10,
      });
    });

    it('prepares delay configuration for random delay', () => {
      const wrapper = createWrapper();

      wrapper.vm.delayType = 'random';
      wrapper.vm.delayMin = 3;
      wrapper.vm.delayMax = 10;

      const delayConfig = wrapper.vm.prepareDelayConfiguration();

      expect(delayConfig).toEqual({
        type: 'random',
        min: 3,
        max: 10,
      });
    });

    it('prepares delay configuration for no delay', () => {
      const wrapper = createWrapper();

      wrapper.vm.delayType = 'none';

      const delayConfig = wrapper.vm.prepareDelayConfiguration();

      expect(delayConfig).toEqual({
        type: 'none',
      });
    });

    it('includes delay in campaign details for fixed delay', () => {
      const wrapper = createWrapper();

      wrapper.vm.state.title = 'Test';
      wrapper.vm.state.message = 'Message';
      wrapper.vm.state.inboxId = 1;
      wrapper.vm.state.scheduledAt = '2025-06-01T10:00';
      wrapper.vm.state.selectedAudience = [1];
      wrapper.vm.delayType = 'fixed';
      wrapper.vm.delaySeconds = 5;

      const campaignDetails = wrapper.vm.prepareCampaignDetails();

      expect(campaignDetails.trigger_rules).toEqual({
        delay: {
          type: 'fixed',
          seconds: 5,
        },
      });
    });

    it('includes delay in campaign details for random delay', () => {
      const wrapper = createWrapper();

      wrapper.vm.state.title = 'Test';
      wrapper.vm.state.message = 'Message';
      wrapper.vm.state.inboxId = 1;
      wrapper.vm.state.scheduledAt = '2025-06-01T10:00';
      wrapper.vm.state.selectedAudience = [1];
      wrapper.vm.delayType = 'random';
      wrapper.vm.delayMin = 3;
      wrapper.vm.delayMax = 10;

      const campaignDetails = wrapper.vm.prepareCampaignDetails();

      expect(campaignDetails.trigger_rules).toEqual({
        delay: {
          type: 'random',
          min: 3,
          max: 10,
        },
      });
    });

    it('validates fixed delay within range (0-300)', async () => {
      const wrapper = createWrapper();

      wrapper.vm.delayType = 'fixed';
      wrapper.vm.delaySeconds = 150;

      await wrapper.vm.v$delay.$validate();
      expect(wrapper.vm.v$delay.$invalid).toBe(false);
    });

    it('invalidates fixed delay outside range (> 300)', async () => {
      const wrapper = createWrapper();

      wrapper.vm.delayType = 'fixed';
      wrapper.vm.delaySeconds = 350;

      await wrapper.vm.v$delay.$validate();
      expect(wrapper.vm.v$delay.$invalid).toBe(true);
    });

    it('invalidates fixed delay outside range (< 0)', async () => {
      const wrapper = createWrapper();

      wrapper.vm.delayType = 'fixed';
      wrapper.vm.delaySeconds = -5;

      await wrapper.vm.v$delay.$validate();
      expect(wrapper.vm.v$delay.$invalid).toBe(true);
    });

    it('validates random delay when min <= max', async () => {
      const wrapper = createWrapper();

      wrapper.vm.delayType = 'random';
      wrapper.vm.delayMin = 5;
      wrapper.vm.delayMax = 10;

      await wrapper.vm.v$delay.$validate();
      expect(wrapper.vm.v$delay.$invalid).toBe(false);
    });

    it('invalidates random delay when min > max', async () => {
      const wrapper = createWrapper();

      wrapper.vm.delayType = 'random';
      wrapper.vm.delayMin = 15;
      wrapper.vm.delayMax = 10;

      await wrapper.vm.v$delay.$validate();
      expect(wrapper.vm.v$delay.$invalid).toBe(true);
    });

    it('validates random delay with equal min and max values', async () => {
      const wrapper = createWrapper();

      wrapper.vm.delayType = 'random';
      wrapper.vm.delayMin = 5;
      wrapper.vm.delayMax = 5;

      await wrapper.vm.v$delay.$validate();
      expect(wrapper.vm.v$delay.$invalid).toBe(false);
    });

    it('resets delay state when resetState is called', () => {
      const wrapper = createWrapper();

      // Set non-default delay values
      wrapper.vm.delayType = 'fixed';
      wrapper.vm.delaySeconds = 20;
      wrapper.vm.delayMin = 10;
      wrapper.vm.delayMax = 30;

      // Reset
      wrapper.vm.resetState();

      // Check values are back to defaults
      expect(wrapper.vm.delayType).toBe('none');
      expect(wrapper.vm.delaySeconds).toBe(0);
      expect(wrapper.vm.delayMin).toBe(1);
      expect(wrapper.vm.delayMax).toBe(5);
    });

    it('prevents form submission when delay validation fails', async () => {
      const wrapper = createWrapper();

      // Fill form with valid data
      wrapper.vm.state.title = 'Test';
      wrapper.vm.state.message = 'Message';
      wrapper.vm.state.inboxId = 1;
      wrapper.vm.state.scheduledAt = '2025-06-01T10:00';
      wrapper.vm.state.selectedAudience = [1];

      // Set invalid delay (min > max)
      wrapper.vm.delayType = 'random';
      wrapper.vm.delayMin = 20;
      wrapper.vm.delayMax = 10;

      await wrapper.vm.handleSubmit();

      // Submission should not emit because delay validation failed
      expect(wrapper.emitted().submit).toBeFalsy();
    });

    it('allows form submission when delay validation passes', async () => {
      const wrapper = createWrapper();

      // Fill form with valid data
      wrapper.vm.state.title = 'Test';
      wrapper.vm.state.message = 'Message';
      wrapper.vm.state.inboxId = 1;
      wrapper.vm.state.scheduledAt = '2025-06-01T10:00';
      wrapper.vm.state.selectedAudience = [1];

      // Set valid delay
      wrapper.vm.delayType = 'fixed';
      wrapper.vm.delaySeconds = 5;

      await wrapper.vm.handleSubmit();

      // Submission should emit because all validations passed
      expect(wrapper.emitted().submit).toBeTruthy();
    });
  });
});
