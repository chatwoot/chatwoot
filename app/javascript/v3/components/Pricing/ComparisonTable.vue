<!-- app/javascript/dashboard/components/ui/ComparisonTable.vue -->
<script>
export default {
  data() {
    return {
      features: [
        {
          name: 'Maximum Active Users',
          pro: '1,000',
          business: '5,000',
          enterprise: '30,000',
          unlimited: 'Unlimited',
        },
        {
          name: 'Human Agents',
          pro: '2',
          business: '5',
          enterprise: '10',
          unlimited: 'Unlimited',
        },
        {
          name: 'AI Agents',
          pro: 'Unlimited',
          business: 'Unlimited',
          enterprise: 'Unlimited',
          unlimited: 'Unlimited',
        },
        {
          name: 'AI Responses',
          pro: '5,000',
          business: '25,000',
          enterprise: '150,000',
          unlimited: '500,000',
        },
        {
          name: 'Dedicated Support',
          pro: 'Standard',
          business: 'Yes',
          enterprise: 'Yes',
          unlimited: 'Yes',
        },
      ],
    };
  },
};
</script>

<template>
  <div class="bg-white shadow-md rounded-lg overflow-hidden">
    <table class="w-full border-collapse">
      <thead>
        <tr class="bg-gray-100 text-left">
          <th class="p-4">Feature</th>
          <th class="p-4">Pro</th>
          <th class="p-4">Business</th>
          <th class="p-4">Enterprise</th>
          <th class="p-4">Unlimited+</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(feature, index) in features" :key="index" class="border-t">
          <td class="p-4">{{ feature.name }}</td>
          <td class="p-4 text-center">{{ feature.pro }}</td>
          <td class="p-4 text-center">{{ feature.business }}</td>
          <td class="p-4 text-center">{{ feature.enterprise }}</td>
          <td class="p-4 text-center">{{ feature.unlimited }}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
