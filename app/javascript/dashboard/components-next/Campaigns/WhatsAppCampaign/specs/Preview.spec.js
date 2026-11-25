import { shallowMount } from '@vue/test-utils';
import AccountInformationCard from '../AccountInformationCard.vue';
import TemplatePreview from 'dashboard/components-next/template-preview/TemplatePreview.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key, te: () => false }),
}));

describe('campaign previews', () => {
  it('renders safely while account health is absent', async () => {
    const wrapper = shallowMount(AccountInformationCard);
    expect(wrapper.text()).toContain(
      'CAMPAIGN.WHATSAPP.FORM.ACCOUNT_INFORMATION'
    );
    await wrapper.setProps({
      healthData: { messaging_limit_tier: 'TIER_1K', quality_rating: 'GREEN' },
    });
    await wrapper.setProps({ healthData: null });
    expect(wrapper.exists()).toBe(true);
  });

  it('uses campaign media instead of template examples, including clearing media', async () => {
    const wrapper = shallowMount(TemplatePreview, {
      props: {
        platform: 'whatsapp',
        mediaUrl: 'https://example.com/campaign.jpg',
        template: {
          name: 'image',
          components: [
            {
              type: 'HEADER',
              format: 'IMAGE',
              example: { header_handle: ['https://example.com/sample.jpg'] },
            },
            { type: 'BODY', text: 'Hello' },
          ],
        },
      },
    });
    expect(wrapper.vm.processedTemplate.image_url).toBe(
      'https://example.com/campaign.jpg'
    );
    await wrapper.setProps({ mediaUrl: '' });
    expect(wrapper.vm.processedTemplate.image_url).toBe('');
    await wrapper.setProps({ mediaUrl: null });
    expect(wrapper.vm.processedTemplate.image_url).toBe(
      'https://example.com/sample.jpg'
    );
  });
});
