<!-- Pricing Cards -->
<script>
export default {
  name: 'PricingCards',
  props: {
    plans: Array,
  },
};
</script>

<template>
  <!-- <section class="pricing-cards"> -->
  <div
    v-for="plan in plans"
    :key="plan.id"
    class="pricing-card"
    :class="[`${plan.type.toLowerCase()}-card`]"
  >
    <div class="card-header">
      <div class="card-type">{{ plan.type }}</div>
      <div class="card-price">{{ plan.price }}<span>/bulan</span></div>
      <div class="card-billing">{{ plan.billing }}</div>
    </div>
    <div class="card-description">
      {{ plan.description }}
    </div>
    <div class="card-features">
      <div
        v-for="(feature, index) in plan.features"
        :key="index"
        class="feature-item"
      >
        <div class="feature-dot">✓</div>
        <span>{{ feature }}</span>
      </div>
    </div>
    <button class="order-now-btn">Pesan Sekarang!</button>
  </div>
  <!-- </section> -->
</template>
<!-- 
<script>
export default {
  name: 'PricingCards',
  data() {
    return {
      plans: [
        {
          type: 'Pro',
          price: 'Rp 579K',
          billing: 'Mulai Order Dibayar',
          description: '',
          features: [
            '1.000 Maximum Active Users',
            '3 Human Agents',
            'Unlimited AI Agents',
            '5.000 AI Responses',
            'Models',
            'Complete Documentation',
            'Free App Training',
            'Free Support'
          ]
        },
        {
          type: 'Business',
          price: 'Rp 1.499K',
          billing: 'Mulai Order Dibayar',
          description: 'Untuk bisnis dengan MAU dibawah 5ribu users',
          features: [
            '5.000 Maximum Active Users',
            '5 Human Agents',
            'Unlimited AI Agents',
            '25.000 AI Responses',
            'Multiple Advanced AI Models',
            'Free Onboarding and Setup',
            'Dedicated Support',
            'Complete Documentation',
            'OpenAI Access',
            'Free App Training',
            'Free 3 API Banned'
          ]
        },
        {
          type: 'Enterprise',
          price: 'Rp 5.799K',
          billing: 'Order Lihat plan terbaik',
          description: 'Untuk Deployments besar dengan dedicated servers',
          features: [
            '30.000 Maximum Active Users',
            '10 Human Agents',
            'Unlimited AI Agents',
            '100.000 AI Responses',
            'Multiple Advanced AI Models',
            'Free Onboarding and Setup',
            'Dedicated Support',
            'Complete Documentation',
            'OpenAI Access',
            'Free App Training',
            'Free 3 API Banned'
          ]
        },
        {
          type: 'Unlimited',
          price: 'Rp 15.799K',
          billing: 'Untuk paket growth dan pembangunan terintegrasi AI',
          description: '',
          features: [
            'Unlimited Maximum Active Users',
            'Unlimited Human Agents',
            'Unlimited AI Agents',
            '500.000 AI Responses',
            'Multiple Advanced AI Models',
            'Free Onboarding and Setup',
            'Dedicated Support',
            'Complete Documentation',
            'Open API Access',
            '24/7 On Call Support',
            'Free 7 API Banned'
          ]
        }
      ]
    };
  }
};
</script> -->
