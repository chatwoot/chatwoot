<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import SubscriptionPaywall from 'dashboard/components/subscription/SubscriptionPaywall.vue';

const route = useRoute();

// Get feature name from query params - make it reactive to route changes
const featureName = computed(() => route.query.feature || 'premium_feature');
</script>

<template>
  <SubscriptionPaywall :feature-name="featureName" />
</template>
