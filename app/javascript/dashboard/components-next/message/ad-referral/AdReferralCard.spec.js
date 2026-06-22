import { mount } from '@vue/test-utils';
import AdReferralCard from './AdReferralCard.vue';

const adReferral = {
  ref: 'sim_ref_abc123',
  source: 'ADS',
  type: 'OPEN_THREAD',
  adId: '6089986171001',
  adsContextData: {
    adTitle: 'Summer Sale – 30% Off All Items',
    photoUrl: 'https://picsum.photos/seed/simad/800/400',
    videoUrl: null,
    postId: '123456789_987654321',
    productId: null,
  },
};

const mountCard = referral =>
  mount(AdReferralCard, {
    props: { referral },
    global: { mocks: { $t: key => key } },
  });

describe('AdReferralCard', () => {
  it('renders the card when source is ADS and has content', () => {
    const wrapper = mountCard(adReferral);
    expect(wrapper.find('div').exists()).toBe(true);
  });

  it('shows the ad thumbnail image', () => {
    const wrapper = mountCard(adReferral);
    const img = wrapper.find('img');
    expect(img.exists()).toBe(true);
    expect(img.attributes('src')).toBe(adReferral.adsContextData.photoUrl);
  });

  it('shows the Sponsored label', () => {
    const wrapper = mountCard(adReferral);
    expect(wrapper.find('span').text()).toBe(
      'CONVERSATION.AD_REFERRAL.SPONSORED'
    );
  });

  it('shows the ad title', () => {
    const wrapper = mountCard(adReferral);
    expect(wrapper.find('p').text()).toBe(adReferral.adsContextData.adTitle);
  });

  it('renders without image when photoUrl is empty', () => {
    const noImage = {
      ...adReferral,
      adsContextData: { ...adReferral.adsContextData, photoUrl: '' },
    };
    const wrapper = mountCard(noImage);
    expect(wrapper.find('img').exists()).toBe(false);
    expect(wrapper.find('p').text()).toBe(adReferral.adsContextData.adTitle);
  });

  it('does NOT render when source is not ADS', () => {
    const shortlink = {
      ref: 'some_link',
      source: 'SHORTLINK',
      type: 'OPEN_THREAD',
      adId: null,
      adsContextData: null,
    };
    const wrapper = mountCard(shortlink);
    expect(wrapper.find('div').exists()).toBe(false);
  });

  it('does NOT render when adsContextData has no content', () => {
    const emptyAd = {
      ...adReferral,
      adsContextData: { adTitle: '', photoUrl: '' },
    };
    const wrapper = mountCard(emptyAd);
    expect(wrapper.find('div').exists()).toBe(false);
  });

  it('does NOT render when adsContextData is null', () => {
    const nullData = { ...adReferral, adsContextData: null };
    const wrapper = mountCard(nullData);
    expect(wrapper.find('div').exists()).toBe(false);
  });
});
