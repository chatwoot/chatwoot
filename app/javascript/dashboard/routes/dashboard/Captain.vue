<script setup>
import { ref } from 'vue';
import integrations from '../../api/integrations';

const isLoading = ref(true);
const captainURL = ref('');

const loadCaptainFrame = async () => {
  try {
    isLoading.value = true;
    const { data } = await integrations.fetchCaptainURL();
    captainURL.value = data.sso_url;
  } catch (error) {
    // ignore error
  } finally {
    isLoading.value = false;
  }
};

loadCaptainFrame();
</script>

<template>
  <div class="flex-1 overflow-auto flex gap-8 flex-col">
    <iframe
      v-if="captainURL"
      :src="captainURL"
      class="w-full min-h-[800px] h-full"
    />
  </div>
</template>
