<script setup>
import ReferralBubble from './ReferralBubble.vue';

const imageReferral = {
  source_url: 'https://fb.me/sample-ad',
  source_id: '1234567890',
  source_type: 'ad',
  headline: 'Online Marketing Course 2026',
  body: 'Learn to sell on social media from scratch. Limited seats — start this week and unlock 10 bonus lessons.',
  media_type: 'image',
  image_url: 'https://picsum.photos/seed/ad1/800/420.jpg',
  thumbnail_url: 'https://picsum.photos/seed/ad1/300/180.jpg',
  ctwa_clid: 'ARAkLkA8rmlFeiCktEJQTEST',
  welcome_message: { text: 'Hi, I want more info about the course' },
};

// Real-world note: Meta delivers `video_url` as a Facebook/Instagram Reel
// page (HTML), not a media file. The component never tries to play it; it
// renders the thumbnail and links to `source_url` instead.
const videoReferral = {
  ...imageReferral,
  media_type: 'video',
  video_url: 'https://www.facebook.com/reel/3585119514960925/',
  thumbnail_url: 'https://picsum.photos/seed/ad2/300/180.jpg',
};

const textOnlyReferral = {
  source_url: 'https://fb.me/sample-post',
  source_type: 'post',
  headline: 'Big news from our team',
  body: 'We just shipped a brand-new feature you have been asking for.',
  welcome_message: { text: 'Tell me more' },
};

const minimalReferral = {
  source_url: 'https://fb.me/sample-ad',
  source_type: 'ad',
  headline: 'Special Offer',
  body: 'Limited time only.',
};
</script>

<template>
  <Story
    title="Components/Conversation/ReferralBubble"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <Variant title="Ad with image">
      <ul>
        <ReferralBubble :referral="imageReferral" />
      </ul>
    </Variant>

    <Variant title="Ad with video">
      <ul>
        <ReferralBubble :referral="videoReferral" />
      </ul>
    </Variant>

    <Variant title="Post (organic) without media">
      <ul>
        <ReferralBubble :referral="textOnlyReferral" />
      </ul>
    </Variant>

    <Variant title="Minimal payload (no media, no welcome message)">
      <ul>
        <ReferralBubble :referral="minimalReferral" />
      </ul>
    </Variant>
  </Story>
</template>
