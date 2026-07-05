import { mount } from '@vue/test-utils';
import { describe, it, expect } from 'vitest';

import BuilderReview from './BuilderReview.vue';

// Local NextButton stub renders the `label` prop (the global stub only renders
// the slot, and NextButton is label-driven here) so we can assert the CTA order
// and identity in the DOM. Other design-system children are shallow-stubbed.
const stubs = {
  NextButton: {
    props: ['label', 'icon', 'solid', 'outline', 'disabled', 'isLoading'],
    template: '<button :disabled="disabled">{{ label }}</button>',
  },
  Avatar: true,
  TextArea: true,
  Select: true,
};

const externalAgent = {
  id: 1,
  name: 'Ada',
  agent_type: 'support',
  actuation: 'external',
  greeting: 'Hi there',
  human_card: 'A support agent',
  starter_questions: [],
};

const mountReview = (agentOverrides = {}, propOverrides = {}) =>
  mount(BuilderReview, {
    props: {
      agent: { ...externalAgent, ...agentOverrides },
      eligibleInboxes: [{ id: 10, name: 'Inbox 1' }],
      approvedCount: 2,
      confidencePct: 85,
      isSavingGreeting: false,
      isConnecting: false,
      ...propOverrides,
    },
    global: { stubs },
  });

const ctaLabels = wrapper => wrapper.findAll('button').map(btn => btn.text());

describe('BuilderReview CTA order', () => {
  it('renders the activate CTA before Test and Back for an external agent', () => {
    const labels = ctaLabels(mountReview());

    const activateIndex = labels.indexOf('Connect and activate');
    const testIndex = labels.indexOf('Test');
    const backIndex = labels.indexOf('Back');

    expect(activateIndex).toBeGreaterThanOrEqual(0);
    expect(testIndex).toBeGreaterThan(activateIndex);
    expect(backIndex).toBeGreaterThan(activateIndex);
  });

  it('makes the internal copilot activate CTA primary (before Test)', () => {
    const labels = ctaLabels(
      mountReview({ actuation: 'internal', agent_type: 'support' })
    );

    const activateIndex = labels.indexOf('Activate copilot');
    const testIndex = labels.indexOf('Test');

    expect(activateIndex).toBeGreaterThanOrEqual(0);
    expect(testIndex).toBeGreaterThan(activateIndex);
    // Internal agents never connect an inbox.
    expect(labels).not.toContain('Connect and activate');
  });

  it('keeps the Test CTA visible and does not force testing before activation', async () => {
    const wrapper = mountReview();
    // Test stays available (optional).
    expect(ctaLabels(wrapper)).toContain('Test');

    // Once an inbox is picked, activate is enabled with NO "tested first" gate —
    // the only gate is inbox selection, not prior testing.
    wrapper.vm.selectedInbox = 10;
    await wrapper.vm.$nextTick();

    const activateBtn = wrapper
      .findAll('button')
      .find(btn => btn.text() === 'Connect and activate');
    expect(activateBtn.attributes('disabled')).toBeUndefined();
  });

  it('emits connect (activation) directly from the review step', async () => {
    const wrapper = mountReview();
    wrapper.vm.selectedInbox = 10;
    await wrapper.vm.$nextTick();

    const activateBtn = wrapper
      .findAll('button')
      .find(btn => btn.text() === 'Connect and activate');
    await activateBtn.trigger('click');

    expect(wrapper.emitted('connect')).toBeTruthy();
    expect(wrapper.emitted('connect')[0]).toEqual([10]);
  });
});
