<!-- app/javascript/dashboard/components/ui/FAQSection.vue -->
<script>
export default {
  data() {
    return {
      activeIndex: null,
      faqs: [
        {
          question: 'Apakah bisa bayar pakai kartu kredit?',
          answer: 'Ya, kami menerima pembayaran kartu kredit.',
        },
        {
          question: 'Apa itu MAU (Monthly Active Users)?',
          answer: 'MAU adalah jumlah pengguna aktif setiap bulan.',
        },
        {
          question: 'Bagaimana cara AI credit dihitung?',
          answer: 'Berdasarkan jumlah respons AI yang digunakan.',
        },
      ],
    };
  },
  methods: {
    toggleFAQ(index) {
      this.activeIndex = this.activeIndex === index ? null : index;
    },
  },
};
</script>

<template>
  <div class="bg-gray-100 py-12">
    <div class="max-w-4xl mx-auto">
      <h2 class="text-2xl font-bold text-center mb-6">
        Frequently Asked Questions
      </h2>
      <div
        v-for="(faq, index) in faqs"
        :key="index"
        class="bg-white p-4 mb-2 rounded-lg shadow-md cursor-pointer"
        @click="toggleFAQ(index)"
      >
        <div class="flex justify-between">
          <h3 class="text-lg font-medium">{{ faq.question }}</h3>
          <span>{{ activeIndex === index ? '▲' : '▼' }}</span>
        </div>
        <p v-if="activeIndex === index" class="mt-2 text-gray-600">
          {{ faq.answer }}
        </p>
      </div>
    </div>
  </div>
</template>
