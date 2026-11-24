import { flushPromises, mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import CustomerSatisfaction from '../CustomerSatisfaction.vue';

const buildStore = updateMessage =>
  createStore({
    modules: {
      appConfig: {
        namespaced: true,
        getters: { getWidgetColor: () => '#1f93ff' },
      },
      message: {
        namespaced: true,
        actions: { update: updateMessage },
      },
    },
  });

const mountSurvey = (updateMessage, props = {}) =>
  mount(CustomerSatisfaction, {
    props: { messageId: 1, ...props },
    global: {
      plugins: [buildStore(updateMessage)],
      directives: {
        dompurifyHtml: (element, binding) => {
          element.textContent = binding.value;
        },
      },
    },
  });

const selectFirstRating = async wrapper => {
  await wrapper.find('.emoji-button').trigger('click');
  await flushPromises();
};

describe('CustomerSatisfaction', () => {
  it('shows the expired message and locks the survey when the rating is rejected as expired', async () => {
    const updateMessage = vi.fn().mockRejectedValue({
      response: { status: 422 },
    });
    const wrapper = mountSurvey(updateMessage);

    await selectFirstRating(wrapper);

    expect(wrapper.find('h6').text()).toContain('CSAT.EXPIRED_TITLE');
    expect(wrapper.find('.feedback-form').exists()).toBe(false);
    expect(wrapper.find('.emoji-button.selected').exists()).toBe(false);

    await selectFirstRating(wrapper);
    expect(updateMessage).toHaveBeenCalledTimes(1);
  });

  it('keeps the previously submitted rating when a change is rejected as expired', async () => {
    const updateMessage = vi.fn().mockRejectedValue({
      response: { status: 422 },
    });
    const wrapper = mountSurvey(updateMessage, {
      messageContentAttributes: { csat_survey_response: { rating: 3 } },
    });

    await selectFirstRating(wrapper);

    expect(wrapper.find('h6').text()).toContain('CSAT.EXPIRED_TITLE');
    expect(wrapper.findAll('.emoji-button')[2].classes()).toContain('selected');
  });

  it('keeps the survey open when the update fails for another reason', async () => {
    const updateMessage = vi.fn().mockRejectedValue({
      response: { status: 500 },
    });
    const wrapper = mountSurvey(updateMessage);

    await selectFirstRating(wrapper);

    expect(wrapper.find('h6').text()).toContain('CSAT.TITLE');
    expect(wrapper.find('.feedback-form').exists()).toBe(true);
  });
});
