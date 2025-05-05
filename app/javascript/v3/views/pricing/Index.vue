<script>
import PricingCard from '../../components/Pricing/PricingCard.vue';

export default {
  name: 'PricingPage',
  components: {
    PricingCard,
    // ComparisonTable, FAQSection
  },
  data() {
    return {
      plans: [],
      compareFeatures: [],
      faqs: [
        {
          question: 'Apakah bisa bayar pakai kartu kredit?',
          answer:
            'Ya, kami menerima pembayaran dengan kartu kredit termasuk Visa dan Mastercard.',
          isOpen: false,
        },
        {
          question: 'Apa itu MAU (Monthly Active User)?',
          answer:
            'MAU adalah jumlah pengguna unik yang mengakses layanan dalam periode satu bulan.',
          isOpen: false,
        },
        {
          question: 'Bagaimana cara AI credit dihitung?',
          answer:
            'AI credit dihitung berdasarkan jumlah respons yang dihasilkan oleh AI assistant.',
          isOpen: false,
        },
        {
          question: 'Apakah saya bisa top-up AI credit?',
          answer:
            'Ya, Anda dapat menambah AI credit kapan saja melalui dashboard akun Anda.',
          isOpen: false,
        },
        {
          question: 'Kapan batas penggunaan bulanan (monthly limit) direset?',
          answer:
            'Batas penggunaan bulanan akan direset pada tanggal pertama setiap bulan.',
          isOpen: false,
        },
        {
          question:
            'Jika saya upgrade paket, apakah sisa penggunaan akan direset?',
          answer:
            'Tidak, sisa penggunaan akan dibawa ke paket baru dengan penambahan kuota sesuai paket.',
          isOpen: false,
        },
        {
          question:
            'Apakah di credit hand top-up memiliki masa berlaku atau bisa diakumulasi?',
          answer:
            'Credit top-up memiliki masa berlaku 12 bulan dan dapat diakumulasi.',
          isOpen: false,
        },
        {
          question:
            'Apakah saya bisa memajukan metode pembayaran dari one-time payment ke kartu kredit atau recurring payment?',
          answer:
            'Ya, Anda dapat mengubah metode pembayaran kapan saja melalui pengaturan akun.',
          isOpen: false,
        },
        {
          question: 'Apakah ada collab gratis untuk CatBot?',
          answer:
            'Kami menyediakan program collab untuk para kreator dan pengembang komunitas.',
          isOpen: false,
        },
        {
          question: 'Apakah CatBot melalukan Refund?',
          answer:
            'Kami memiliki kebijakan pengembalian uang dalam 7 hari jika Anda tidak puas dengan layanan.',
          isOpen: false,
        },
      ],
    };
  },
  async created() {
    try {
      const response = await fetch('/api/v1/subscriptions/plans');
      const data = await response.json();
      this.plans = data;
      this.compareFeatures = this.transformApiDataToCompareFeatures(data);
    } catch (error) {
      console.error('Gagal mengambil data pricing:', error);
    }
  },
  methods: {
    formattedPrice(value) {
      if (value >= 1000) {
        return Math.round(value / 1000).toLocaleString('id-ID') + 'K'; // Gunakan toLocaleString untuk menambahkan titik
      }
      return value.toLocaleString('id-ID'); // Format angka kecil dengan titik juga
    },
    toggleFaq(index) {
      this.faqs[index].isOpen = !this.faqs[index].isOpen;
    },
    transformApiDataToCompareFeatures(apiData) {
      // Definisikan struktur dasar untuk compareFeatures
      const compareFeatures = [
        {
          name: 'Maximum Active Users (MAU)',
          values: {},
        },
        {
          name: 'WhatsApp',
          values: {},
        },
        {
          name: 'LiveChat',
          values: {},
        },
        {
          name: 'Telegram',
          values: {},
        },
        {
          name: 'Human Agents',
          values: {},
        },
        {
          name: 'AI Agents',
          values: {},
        },
        {
          name: 'AI Responses',
          values: {},
        },
        {
          name: 'AI Models',
          values: {},
        },
        {
          name: 'AI Training',
          values: {},
        },
        {
          name: 'AI Ticketing & CRM',
          values: {},
        },
        {
          name: 'Prompting Support',
          values: {},
        },
        {
          name: 'Documentation',
          values: {},
        },
        {
          name: 'API Access',
          values: {},
        },
        {
          name: 'Dedicated WA Group',
          values: {},
        },
        {
          name: 'Feature Requests',
          values: {},
        },
        {
          name: 'Early Access',
          values: {},
        },
      ];

      // Untuk setiap plan dari API
      apiData.forEach(plan => {
        const planKey = plan.name.toLowerCase();

        // Maximum Active Users (MAU)
        compareFeatures[0].values[planKey] =
          plan.max_mau === 0
            ? 'Unlimited MAU'
            : `${plan.max_mau.toLocaleString()} MAU`;

        // WhatsApp
        compareFeatures[1].values[planKey] =
          plan.available_channels.includes('Whatsapp');

        // LiveChat
        compareFeatures[2].values[planKey] =
          plan.available_channels.includes('Livechat');

        // Telegram
        compareFeatures[3].values[planKey] =
          plan.available_channels.includes('Telegram');

        // Human Agents
        compareFeatures[4].values[planKey] =
          plan.max_human_agents === 0
            ? 'Unlimited'
            : plan.max_human_agents.toString();

        // AI Agents
        compareFeatures[5].values[planKey] =
          plan.max_ai_agents === 0 ? true : plan.max_ai_agents > 0;

        // AI Responses
        compareFeatures[6].values[planKey] =
          plan.max_ai_responses.toLocaleString();

        // AI Models - tidak ada di API, set default ke true
        compareFeatures[7].values[planKey] = true;

        // AI Training - tidak ada di API, set default ke true
        compareFeatures[8].values[planKey] = true;

        // AI Ticketing & CRM - tidak ada di API, set default ke true
        compareFeatures[9].values[planKey] = true;

        // Prompting Support
        compareFeatures[10].values[planKey] =
          plan.support_level === 'Dedicated'
            ? 'Dedicated Support'
            : 'Standard Support';

        // Documentation
        compareFeatures[11].values[planKey] = 'Complete';

        // API Access - tidak ada di API, set default berdasarkan level
        compareFeatures[12].values[planKey] =
          plan.name.toLowerCase() !== 'free trial';

        // Dedicated WA Group - tidak ada di API, set default berdasarkan level
        if (plan.name.toLowerCase() === 'growth') {
          compareFeatures[13].values[planKey] = '24/7 WA Group';
        } else if (plan.name.toLowerCase() === 'enterprise') {
          compareFeatures[13].values[planKey] = '24/7 Exclusive Support';
        } else {
          compareFeatures[13].values[planKey] = '-';
        }

        // Feature Requests - tidak ada di API, set default ke true hanya untuk enterprise
        compareFeatures[14].values[planKey] =
          plan.name.toLowerCase() === 'enterprise';

        // Early Access - tidak ada di API, set default ke true hanya untuk enterprise
        compareFeatures[15].values[planKey] =
          plan.name.toLowerCase() === 'enterprise';
      });

      return compareFeatures;
    },
  },
};
</script>

<template>
  <div class="pricing-page">
    <!-- Header -->
    <header class="header">
      <div class="container header-content">
        <div class="logo">
          <img src="/brand-assets/logo.svg" alt="Catbot.AI Logo" />
        </div>
        <nav>
          <ul>
            <li><a href="/">Home</a></li>
            <li><a href="#">Fitur</a></li>
            <li><a href="/app/pricing">Harga</a></li>
            <li><a href="#enterprise">Enterprise</a></li>
            <li><a href="#">Dokumentasi</a></li>
          </ul>
        </nav>
        <div class="login-buttons">
          <a href="/app/login" class="login-link">Log In</a>
          <button class="order-button">
            <a href="/app/auth/signup?slug=pricing">Daftar Sekarang</a>
          </button>
        </div>
      </div>
    </header>

    <main class="container">
      <!-- Pricing Header -->
      <section class="pricing-header">
        <h1>Harga</h1>
        <div class="pricing-subheader">
          Simple & Predictable pricing. No Surprises.
        </div>
      </section>

      <!-- Promo Banner -->
      <section class="promo-banner">
        <div class="promo-image">
          <img src="/pricing/promo-image.webp" alt="Promo Banner" />
        </div>
        <div class="promo-content">
          <h3>Lebaran Tetap Jualan, Layanan Tetap Aman!</h3>
          <p class="promo-details">
            • 1 on 1 dengan Prompt Specialist. Terima Bonus setup AI dan Fitur
            Terbaru<br />
            • Bebas WhatsApp API Banned<br />
            • Bonus Akses ke API Tanpa di Blokir kembali
          </p>
          <div class="promo-buttons">
            <button class="promo-button promo-button-primary">
              Mulai 7 Hari Gratisan Promo
            </button>
            <button class="promo-button promo-button-secondary">
              Info Lebih Lanjut
            </button>
          </div>
        </div>
      </section>

      <!-- Pricing Cards -->
      <!-- <section class="pricing-cards">
        <PricingCard :plans="plans" />
      </section> -->
      <section class="pricing-cards">
        <div
          v-for="plan in plans"
          :key="plan.id"
          class="pricing-card"
          :class="[`${plan.name.toLowerCase()}-card`]"
        >
          <div class="card-header">
            <div class="card-type">{{ plan.name }}</div>
            <div class="card-price">
              {{ formattedPrice(plan.monthly_price) }}<span>/bulan</span>
            </div>
            <!-- <div class="card-billing">{{ plan.description }}</div> -->
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
          <button class="order-now-btn">
            <a href="/app/auth/signup?slug=pricing">Pesan Sekarang!</a>
          </button>
        </div>
      </section>

      <!-- Corporate Section -->
      <section id="enterprise" class="corporate-section">
        <div class="corporate-content">
          <h2>Corporate & Government</h2>
          <p>
            Solusi yang disesuaikan untuk kebutuhan perusahaan spesifik dan
            mendukung pekerjaan yang ditujukan organisasi besar.
          </p>
          <button class="contact-sales-btn">Hubungi Sales</button>
        </div>
        <div class="corporate-image">
          <img src="/pricing/building-icon.png" alt="Building Icon" />
        </div>
      </section>

      <!-- Compare Plans -->
      <section class="compare-section">
        <div class="compare-header">
          <h2>Compare Plans</h2>
          <div class="compare-subtext">
            Use the table below to compare the features of this product.
          </div>
        </div>

        <table class="compare-table">
          <thead>
            <tr>
              <th>Compare Plans</th>
              <th v-for="plan in plans" :key="plan.id">{{ plan.name }}</th>
            </tr>
          </thead>
          <tbody>
            <tr class="price-row">
              <td />
              <td v-for="plan in plans" :key="plan.id">
                {{ plan.monthly_price }}/mo
              </td>
            </tr>
            <tr>
              <td />
              <td v-for="plan in plans" :key="plan.id">
                <button class="compare-btn">See Details</button>
              </td>
            </tr>
            <!-- <tr v-for="(feature, index) in compareFeatures" :key="index">
              <td>{{ feature.name }}</td>
              <td v-for="plan in plans" :key="plan.id">
                <span v-if="typeof feature.values[plan.name.toLowerCase()] === 'boolean'">
                  <span v-if="feature.values[plan.name.toLowerCase()]" class="compare-check">✓</span>
                  <span v-else>-</span>
                </span>
                <span v-else>{{ feature.values[plan.name.toLowerCase()] }}</span>
              </td>
            </tr> -->
            <tr v-for="(feature, index) in compareFeatures" :key="index">
              <td>{{ feature.name }}</td>
              <td v-for="plan in plans" :key="plan.id">
                <span
                  v-if="
                    typeof feature.values[plan.name.toLowerCase()] === 'boolean'
                  "
                >
                  <span
                    v-if="feature.values[plan.name.toLowerCase()]"
                    class="compare-check"
                    >✓</span
                  >
                  <span v-else>-</span>
                </span>
                <span v-else>{{
                  feature.values[plan.name.toLowerCase()]
                }}</span>
              </td>
            </tr>
          </tbody>
        </table>
      </section>

      <!-- FAQ Section -->
      <section class="faq-section">
        <div class="faq-header">
          <h2>FAQ</h2>
          <div class="faq-subtext">Frequently asked questions</div>
        </div>

        <div v-for="(faq, index) in faqs" :key="index" class="faq-item">
          <div class="faq-question" @click="toggleFaq(index)">
            {{ faq.question }}
            <span class="faq-icon">{{ faq.isOpen ? '▲' : '▼' }}</span>
          </div>
          <div v-if="faq.isOpen" class="faq-answer">
            {{ faq.answer }}
          </div>
        </div>
      </section>
    </main>

    <!-- Footer -->
    <footer>
      <div class="container footer-content">
        <div class="footer-column">
          <div class="company-info">
            <img
              src="/brand-assets/logo.svg"
              alt="Catbot.AI Logo"
              class="footer-logo"
            />
            <div class="company-name">PT Teknologi Catbot Indonesia</div>
            <div class="company-address">
              Jalan Merdeka Permai Blok B No.10, Pagedangan
            </div>
          </div>
          <div class="app-stores">
            <img
              src="/pricing/google-play.png"
              alt="Google Play"
              class="app-store-badge"
            />
            <img
              src="/pricing/app-store.png"
              alt="App Store"
              class="app-store-badge"
            />
          </div>
        </div>

        <div class="footer-column">
          <h3>Company</h3>
          <ul class="footer-links">
            <li><a href="#">Blog</a></li>
            <li><a href="#">About</a></li>
            <li><a href="#">Integrations</a></li>
          </ul>
        </div>

        <div class="footer-column">
          <h3>Product</h3>
          <ul class="footer-links">
            <li><a href="#">Features</a></li>
            <li><a href="#">Pricing</a></li>
            <li><a href="#">Integrations</a></li>
          </ul>
        </div>

        <div class="footer-column">
          <h3>Resources</h3>
          <ul class="footer-links">
            <li><a href="#">Documentation</a></li>
            <li><a href="#">Knowledge Support</a></li>
            <li><a href="#">Email Support</a></li>
          </ul>
        </div>
      </div>

      <div class="footer-bottom">
        <p>Copyright © 2025 Catbot.AI. All rights reserved.</p>
        <div class="footer-links">
          <a href="#">Terms</a> • <a href="#">Privacy</a>
        </div>
      </div>
    </footer>
  </div>
</template>

<style scoped>
/* Base styles */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen,
    Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
}

.pricing-page {
  background-color: #f5f7fa;
  color: #333;
  line-height: 1.6;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

/* Header styles */
.header {
  background-color: white;
  padding: 15px 0;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.logo img {
  height: 30px;
}

nav ul {
  display: flex;
  list-style: none;
}

nav ul li {
  margin-left: 25px;
}

nav ul li a {
  text-decoration: none;
  color: #333;
  font-weight: 500;
  font-size: 14px;
}

.login-buttons {
  display: flex;
  align-items: center;
}

.login-link {
  margin-right: 15px;
  text-decoration: none;
  color: #333;
  font-weight: 500;
  font-size: 14px;
}

.order-button {
  background-color: #3b82f6;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 5px;
  font-weight: 500;
  font-size: 14px;
  cursor: pointer;
}

/* Pricing header styles */
.pricing-header {
  text-align: center;
  padding: 50px 0 20px;
}

.pricing-header h1 {
  font-size: 32px;
  font-weight: 700;
  margin-bottom: 10px;
}

.pricing-subheader {
  font-size: 16px;
  color: #555;
}

/* Promo banner */
.promo-banner {
  background-color: #e6f7eb;
  border-radius: 12px;
  padding: 20px;
  margin: 30px auto;
  max-width: 900px;
  display: flex;
  align-items: center;
}

.promo-image {
  width: 180px;
  margin-right: 20px;
}

.promo-image img {
  width: 100%;
}

.promo-content h3 {
  color: #1a5336;
  font-size: 18px;
  margin-bottom: 5px;
}

.promo-details {
  font-size: 14px;
  color: #333;
  margin-bottom: 15px;
}

.promo-buttons {
  display: flex;
  gap: 10px;
}

.promo-button {
  padding: 8px 16px;
  border-radius: 5px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
}

.promo-button-primary {
  background-color: #10b981;
  color: white;
  border: none;
}

.promo-button-secondary {
  background-color: white;
  color: #10b981;
  border: 1px solid #10b981;
}

/* Pricing cards */
.pricing-cards {
  display: flex;
  gap: 20px;
  margin: 40px 0;
  justify-content: center;
}

.pricing-card {
  background-color: white;
  border-radius: 10px;
  box-shadow: 0 3px 10px rgba(0, 0, 0, 0.1);
  padding: 25px;
  flex: 1;
  max-width: 270px;
  display: flex;
  flex-direction: column;
}

.card-header {
  margin-bottom: 15px;
}

.card-type {
  font-size: 14px;
  font-weight: 600;
  margin-bottom: 5px;
}

.card-price {
  font-size: 24px;
  font-weight: 700;
  margin-bottom: 5px;
}

.card-price span {
  font-size: 14px;
  font-weight: normal;
}

.card-billing {
  font-size: 12px;
  color: #666;
}

.card-description {
  font-size: 12px;
  color: #666;
  margin-bottom: 15px;
  min-height: 50px;
}

.card-features {
  flex-grow: 1;
}

.feature-item {
  display: flex;
  align-items: center;
  font-size: 13px;
  margin-bottom: 10px;
}

.feature-dot {
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background-color: #10b981;
  margin-right: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: bold;
  font-size: 10px;
}

.order-now-btn {
  background-color: white;
  color: #3b82f6;
  border: 1px solid #3b82f6;
  border-radius: 5px;
  padding: 8px 0;
  font-size: 14px;
  font-weight: 500;
  margin-top: 20px;
  cursor: pointer;
  width: 100%;
}

/* Pro card specific */
.pro-card .card-type {
  color: #3b82f6;
}

/* Business card specific */
.business-card {
  border: 2px solid #f97316;
}

.business-card .card-type {
  color: #f97316;
}

/* Enterprise card specific */
.enterprise-card .card-type {
  color: #8b5cf6;
}

/* Unlimited card specific */
.unlimited-card .card-type {
  color: #f59e0b;
}

/* Corporate section */
.corporate-section {
  background-color: white;
  border-radius: 10px;
  box-shadow: 0 3px 10px rgba(0, 0, 0, 0.1);
  padding: 25px;
  margin: 40px 0;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.corporate-content {
  flex: 3;
}

.corporate-content h2 {
  font-size: 20px;
  margin-bottom: 10px;
}

.corporate-content p {
  font-size: 14px;
  color: #666;
  margin-bottom: 15px;
}

.corporate-image {
  flex: 1;
  text-align: right;
}

.corporate-image img {
  width: 80px;
}

.contact-sales-btn {
  background-color: #3b82f6;
  color: white;
  border: none;
  border-radius: 5px;
  padding: 8px 16px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
}

/* Compare Plans section */
.compare-section {
  margin: 40px 0;
}

.compare-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.compare-header h2 {
  font-size: 20px;
}

.compare-subtext {
  font-size: 14px;
  color: #666;
}

.compare-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 20px;
}

.compare-table th,
.compare-table td {
  padding: 12px 10px;
  text-align: center;
  font-size: 14px;
  border-bottom: 1px solid #eee;
}

.compare-table th {
  font-weight: 600;
}

.compare-table tr td:first-child {
  text-align: left;
  font-weight: 500;
}

.compare-check {
  color: #10b981;
  font-size: 18px;
}

.price-row {
  font-weight: 700;
  font-size: 16px;
}

.compare-btn {
  background-color: #3b82f6;
  color: white;
  border: none;
  border-radius: 20px;
  padding: 6px 16px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  margin-top: 5px;
}

/* FAQ section */
.faq-section {
  margin: 60px 0;
}

.faq-header {
  text-align: center;
  margin-bottom: 30px;
}

.faq-header h2 {
  font-size: 28px;
  margin-bottom: 10px;
}

.faq-subtext {
  font-size: 16px;
  color: #666;
}

.faq-item {
  border-bottom: 1px solid #ddd;
  padding: 15px 0;
}

.faq-question {
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  font-weight: 500;
}

.faq-icon {
  font-size: 12px;
}

.faq-answer {
  margin-top: 10px;
  padding: 10px;
  background-color: #f8f9fa;
  border-radius: 5px;
}

/* Footer */
footer {
  background-color: white;
  padding: 40px 0;
  border-top: 1px solid #eee;
}

.footer-content {
  display: flex;
  justify-content: space-between;
}

.footer-column {
  flex: 1;
}

.footer-column h3 {
  font-size: 16px;
  margin-bottom: 15px;
}

.footer-links {
  list-style: none;
}

.footer-links li {
  margin-bottom: 10px;
}

.footer-links a {
  text-decoration: none;
  color: #666;
  font-size: 14px;
}

.footer-logo {
  height: 30px;
  margin-bottom: 10px;
}

.company-info {
  margin-bottom: 20px;
}

.company-name {
  font-weight: 600;
  margin-bottom: 5px;
}

.company-address {
  font-size: 12px;
  color: #666;
}

.app-stores {
  display: flex;
  gap: 10px;
  margin-top: 15px;
}

.app-store-badge {
  height: 40px;
}

.footer-bottom {
  text-align: center;
  margin-top: 40px;
  padding-top: 20px;
  border-top: 1px solid #eee;
  font-size: 12px;
  color: #666;
}

/* Responsive */
@media (max-width: 992px) {
  .pricing-cards {
    flex-wrap: wrap;
  }

  .pricing-card {
    max-width: calc(50% - 10px);
    margin-bottom: 20px;
  }

  .promo-banner {
    flex-direction: column;
  }

  .promo-image {
    width: 150px;
    margin-right: 0;
    margin-bottom: 15px;
  }
}

@media (max-width: 768px) {
  .pricing-card {
    max-width: 100%;
  }

  .compare-table th,
  .compare-table td {
    padding: 8px 5px;
    font-size: 12px;
  }

  .corporate-section {
    flex-direction: column;
  }

  .corporate-image {
    margin-top: 20px;
    text-align: center;
  }

  .footer-content {
    flex-direction: column;
  }

  .footer-column {
    margin-bottom: 30px;
  }
}
</style>
