<script setup>
import FeatureSpotlight from './FeatureSpotlight.vue';
</script>

<template>
  <Story
    title="Components/FeatureSpotlight/Default"
    :layout="{ type: 'grid', width: '1000px' }"
  >
    <Variant title="Default with learn more URL">
      <div class="p-6 bg-n-background">
        <FeatureSpotlight
          title="Captain Assistant"
          note="Captain Assistant engages directly with customers, learns from your help docs and past conversations, and delivers instant, accurate responses. It handles the initial queries, providing quick resolutions before transferring to an agent when needed."
          video-url=""
          thumbnail=""
          fallback-thumbnail="/assets/images/dashboard/captain/assistant-light.svg"
          fallback-thumbnail-dark="/assets/images/dashboard/captain/assistant-dark.svg"
          learn-more-url="https://www.chatwoot.com/hc/user-guide/articles/1738101547-creating-an-assistant-with-captain"
        />
      </div>
    </Variant>

    <Variant title="With Video URL and Thumbnail">
      <div class="p-6 bg-n-background">
        <FeatureSpotlight
          title="Captain Assistant"
          note="Captain Assistant engages directly with customers, learns from your help docs and past conversations, and delivers instant, accurate responses. It handles the initial queries, providing quick resolutions before transferring to an agent when needed."
          video-url="https://www.youtube.com/watch?v=E4xUHyAAktY"
          thumbnail="https://i.ytimg.com/an_webp/E4xUHyAAktY/mqdefault_6s.webp?du=3000&sqp=CJaKmL4G&rs=AOn4CLCmfy1TMOcW4UsjQTgyKRp4TSGZgg"
          fallback-thumbnail="/assets/images/dashboard/captain/assistant-light.svg"
          fallback-thumbnail-dark="/assets/images/dashboard/captain/assistant-dark.svg"
          learn-more-url="https://www.chatwoot.com/hc/user-guide/articles/1738101547-creating-an-assistant-with-captain"
        />
      </div>
    </Variant>
  </Story>
</template>
