<template>
  <div class="billing-page p-4">
    <!-- Current Plan Information Cards -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
      <!-- Package Details -->
      <div class="bg-gradient-to-r from-cyan-500 to-cyan-400 text-white rounded-lg p-4">
        <h3 class="text-sm font-medium mb-2">Package Details</h3>
        <h2 class="text-2xl font-bold mb-3">{{ subscription?.[0]?.plan_name }}</h2>
        <div class="flex items-center text-sm">
          <span class="inline-block mr-2">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <circle cx="12" cy="12" r="10"></circle>
              <path d="M12 6v6l4 2"></path>
            </svg>
          </span>
          <span>Expires on {{ subscription?.length > 0 ? formatDate(subscription?.[0]?.ends_at) : 'N/A' }}</span>
        </div>
      </div>

      <!-- Monthly Active Users -->
      <div class="bg-gradient-to-r from-violet-500 to-violet-400 text-white rounded-lg p-4">
        <h3 class="text-sm font-medium mb-2">Monthly Active Users (Limit Percakapan)</h3>
        <div class="flex items-center">
          <h2 class="text-2xl font-bold">{{ usage.activeUsers }}</h2>
          <span class="text-sm ml-2">({{ subscription?.[0]?.max_mau }} MAU)</span>
        </div>
        <p class="text-sm mb-2">Additional MAU: {{ usage.additionalMau }}</p>
        <button @click="topUpMau" class="bg-white text-purple-500 rounded px-2 py-1 text-xs font-medium">Top Up MAU</button>
        <div class="flex items-center text-sm mt-3">
          <span class="inline-block mr-2">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <circle cx="12" cy="12" r="10"></circle>
              <path d="M12 6v6l4 2"></path>
            </svg>
          </span>
          <span>Reset Setup Tanggal: {{ usage.resetDate }}</span>
        </div>
      </div>

      <!-- AI Responses -->
      <div class="bg-gradient-to-r from-blue-500 to-blue-400 text-white rounded-lg p-4">
        <h3 class="text-sm font-medium mb-2">AI Responses</h3>
        <div class="flex items-center">
          <h2 class="text-2xl font-bold">{{ usage.aiResponses.used }} Used</h2>
          <span class="text-sm ml-2">({{ subscription?.[0]?.max_ai_responses }} AI Responses Limit)</span>
        </div>
        <div class="flex items-center text-sm mt-5">
          <span class="inline-block mr-2">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <circle cx="12" cy="12" r="10"></circle>
              <path d="M12 6v6l4 2"></path>
            </svg>
          </span>
          <span>Reset Setup Tanggal: {{ usage.resetDate }}</span>
        </div>
      </div>

      <!-- Additional AI Responses -->
      <div class="bg-gradient-to-r from-blue-500 to-blue-400 text-white rounded-lg p-4">
        <h3 class="text-sm font-medium mb-2">Additional AI Responses</h3>
        <h2 class="text-2xl font-bold mb-2">{{ usage.additionalResponses }} Responses</h2>
        <!-- <button @click="topUpResponses" class="bg-white text-blue-400 rounded px-2 py-1 text-xs font-medium mb-2">Top Up Responses</button> -->
        <button @click="topUpResponses" class="bg-white text-purple-500 rounded px-2 py-1 text-xs font-medium">Top Up Responses</button>
        <div class="flex items-center text-sm">
          <span class="inline-block mr-2">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <circle cx="12" cy="12" r="10"></circle>
              <path d="M18 6l-12 12"></path>
              <path d="M6 6l12 12"></path>
            </svg>
          </span>
          <span>AI Responses Permanent</span>
        </div>
      </div>
    </div>

    <!-- Ramadan Special Package -->
    <div v-if="specialPromo" class="mb-6 border border-gray-300 rounded-lg relative overflow-hidden">
      <!-- Ribbon -->
      <div class="absolute top-0 right-0 bg-gradient-to-r from-yellow-500 to-yellow-600 text-white transform rotate-45 translate-x-8 translate-y-2 py-1 px-8 text-xs font-bold">
        POPULER
      </div>

      <div class="p-5">
        <div class="flex flex-wrap md:flex-nowrap">
          <!-- Left Side with Gift Icon -->
          <div class="w-full md:w-auto flex justify-center md:justify-start md:mr-4">
            <div class="w-16 h-16 flex items-center justify-center bg-gray-200 rounded-full">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-blue-500">
                <rect x="3" y="8" width="18" height="4" rx="1"></rect>
                <path d="M12 8v13"></path>
                <path d="M19 12v7a2 2 0 01-2 2H7a2 2 0 01-2-2v-7"></path>
                <path d="M7.5 8a2.5 2.5 0 100-5 2.5 2.5 0 000 5z"></path>
                <path d="M16.5 8a2.5 2.5 0 100-5 2.5 2.5 0 000 5z"></path>
                <path d="M12 8H7.5C6.12 8 5 6.88 5 5.5 5 4.12 6.12 3 7.5 3h0a2.5 2.5 0 014.5 2v3"></path>
                <path d="M12 8h4.5C17.88 8 19 6.88 19 5.5 19 4.12 17.88 3 16.5 3h0a2.5 2.5 0 00-4.5 2v3"></path>
              </svg>
            </div>
          </div>

          <!-- Main Content -->
          <div class="w-full">
            <p class="text-sm text-blue-500 font-medium">{{ specialPromo.title }}</p>
            <h2 class="text-xl text-blue-500 font-medium mb-2">{{ specialPromo.name }}</h2>
            
            <div class="flex items-center mb-3">
              <span class="text-xl md:text-2xl font-bold text-blue-600">Rp {{ formatPrice(specialPromo.price) }}</span>
              <span class="text-sm line-through text-gray-500 ml-2">Rp {{ formatPrice(specialPromo.originalPrice) }}</span>
              <span class="ml-2 bg-red-500 text-white text-xs px-2 py-0.5 rounded">{{ specialPromo.promoTag }}</span>
            </div>
            
            <ul class="space-y-2 mb-4">
              <li v-for="(feature, index) in specialPromo.features" :key="index" class="flex items-start">
                <span class="text-gray-700 mr-2">•</span>
                <span v-html="feature"></span>
              </li>
            </ul>
            
            <p class="text-sm text-gray-600 mb-4">
              {{ specialPromo.description }}
            </p>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <!-- Left Benefits -->
              <div>
                <h4 class="font-medium mb-2">Manfaat Utama</h4>
                <ul class="space-y-2">
                  <li v-for="(benefit, index) in specialPromo.mainBenefits" :key="index" class="flex items-start">
                    <span class="text-blue-500 mr-2">
                      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"></circle>
                        <path d="M8 14s1.5 2 4 2 4-2 4-2"></path>
                        <line x1="9" y1="9" x2="9.01" y2="9"></line>
                        <line x1="15" y1="9" x2="15.01" y2="9"></line>
                      </svg>
                    </span>
                    <div>
                      <p class="font-medium">{{ benefit.title }}</p>
                      <p class="text-sm text-gray-600">{{ benefit.description }}</p>
                    </div>
                  </li>
                </ul>
              </div>
              
              <!-- Right Benefits -->
              <div>
                <h4 class="font-medium mb-2">Bonus Eksklusif</h4>
                <ul class="space-y-2">
                  <li v-for="(bonus, index) in specialPromo.exclusiveBonuses" :key="index" class="flex items-start">
                    <span class="text-green-500 mr-2">
                      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M22 11.08V12a10 10 0 11-5.93-9.14"></path>
                        <polyline points="22 4 12 14.01 9 11.01"></polyline>
                      </svg>
                    </span>
                    <div>
                      <p class="font-medium">{{ bonus.title }}</p>
                      <p class="text-sm text-gray-600">{{ bonus.description }}</p>
                    </div>
                  </li>
                </ul>
              </div>
            </div>
            
            <div class="text-center bg-red-100 p-2 rounded text-sm mb-4">
              {{ specialPromo.limitedOffer }}
            </div>
            
            <div class="text-center">
              <button @click="purchaseSpecialPromo" class="bg-blue-500 hover:bg-blue-600 text-white font-medium py-2 px-6 rounded-full inline-flex items-center">
                {{ specialPromo.ctaText }}
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="ml-1">
                  <line x1="5" y1="12" x2="19" y2="12"></line>
                  <polyline points="12 5 19 12 12 19"></polyline>
                </svg>
              </button>
              <p class="text-sm text-gray-600 mt-2">
                {{ specialPromo.guaranteeText }}
              </p>
              <p class="text-xs text-gray-500 mt-1">
                {{ specialPromo.contactInfo }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Platform & Duration Tabs -->
    <div class="mb-6">
      <div class="flex justify-center mb-2">
        <div class="bg-gray-100 rounded-full inline-flex p-1">
          <button 
            v-for="platform in platformOptions" 
            :key="platform.id"
            @click="changePlatform(platform.id)"
            :class="[
              'px-4 py-1 rounded-full text-sm', 
              selectedPlatform === platform.id ? 'bg-blue-500 text-white' : 'text-gray-600'
            ]"
          >
            {{ platform.name }}
          </button>
        </div>
      </div>
      
      <div class="flex justify-center">
        <div class="inline-flex items-center">
          <button 
            v-for="duration in durationOptions" 
            :key="duration.id"
            @click="changeDuration(duration.id)"
            :class="[
              'px-4 py-1 text-sm border-b-2', 
              selectedDuration === duration.id ? 'border-blue-500 text-blue-500 font-medium' : 'border-transparent'
            ]"
          >
            {{ duration.name }}
          </button>
          <div v-if="getDurationPromo(selectedDuration)" class="text-xs bg-blue-100 text-blue-800 px-2 py-0.5 rounded-sm ml-1">
            {{ getDurationPromo(selectedDuration) }}
          </div>
        </div>
      </div>
    </div>

    <!-- Pricing Plans -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
      <div 
        v-for="plan in filteredPlans" 
        :key="plan.id" 
        class="border border-gray-200 rounded-lg overflow-hidden"
      >
        <div class="p-4">
          <h3 class="text-lg font-medium mb-4">{{ plan.name }}</h3>
          <div class="mb-4">
            <p class="text-2xl font-bold">{{ formatPrice(plan.price) }}</p>
            <p class="text-gray-600">IDR / {{ getDurationLabel(selectedDuration) }}</p>
            <p class="text-xs text-gray-500">{{ plan.packageType }}</p>
          </div>
          <div class="mb-4">
            <h4 class="font-medium mb-2">{{ plan.name }} Features</h4>
            <ul class="space-y-2">
              <li v-for="(feature, index) in plan.features" :key="index" class="flex items-center">
                <span class="text-blue-500 mr-2">
                  <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M22 11.08V12a10 10 0 11-5.93-9.14"></path>
                    <polyline points="22 4 12 14.01 9 11.01"></polyline>
                  </svg>
                </span>
                <span>{{ feature }}</span>
              </li>
            </ul>
          </div>
          <button @click="purchasePlan(plan.id)" class="w-full bg-gray-700 hover:bg-gray-800 text-white font-medium py-2 px-4 rounded">
            Buy Package
          </button>
        </div>
      </div>
    </div>

    <!-- Recent Transactions Section -->
    <div class="mb-6">
      <h3 class="text-lg font-medium mb-4">Recent Transactions</h3>
      <div class="overflow-x-auto">
        <table class="min-w-full bg-white border border-gray-200">
          <thead>
            <tr>
              <th class="py-2 px-4 border-b border-gray-200 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">PACKAGE</th>
              <th class="py-2 px-4 border-b border-gray-200 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">DURATION</th>
              <th class="py-2 px-4 border-b border-gray-200 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">STATUS</th>
              <th class="py-2 px-4 border-b border-gray-200 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">TRANSACTION DATE</th>
              <th class="py-2 px-4 border-b border-gray-200 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ACTION</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="transactions.length === 0">
              <td colspan="5" class="py-4 px-4 text-center text-gray-500">No recent transactions</td>
            </tr>
            <tr v-for="(transaction, index) in transactions" :key="index" class="border-b border-gray-200">
              <td class="py-2 px-4">{{ transaction.package }}</td>
              <td class="py-2 px-4">{{ transaction.duration }}</td>
              <td class="py-2 px-4">
                <span 
                  :class="[
                    'px-2 py-1 text-xs rounded-full',
                    transaction.status === 'Paid' ? 'bg-green-100 text-green-800' : 
                    transaction.status === 'Pending' ? 'bg-yellow-100 text-yellow-800' : 
                    'bg-red-100 text-red-800'
                  ]"
                >
                  {{ transaction.status }}
                </span>
              </td>
              <td class="py-2 px-4">{{ formatDate(transaction.date) }}</td>
              <td class="py-2 px-4">
                <button @click="viewTransactionDetails(transaction.id)" class="text-blue-500 hover:text-blue-700">
                  View
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState, mapActions } from 'vuex';

export default {
  name: 'BillingPage',
  data() {
    return {
      loading: true,
      error: null,
      planDetails: {
        name: 'FREE',
        expiryDate: '2025-04-15'
      },
      usage: {
        activeUsers: 0,
        additionalMau: 0,
        resetDate: 1,
        aiResponses: {
          used: 0,
          limit: 2000
        },
        additionalResponses: 0
      },
      specialPromo: null,
      selectedPlatform: 'ai',
      selectedDuration: '3mo',
      platformOptions: [
        { id: 'ai', name: 'AI Platform' },
        { id: 'crm', name: 'CRM Only (Lite)' }
      ],
      durationOptions: [
        { id: 'monthly', name: 'Monthly' },
        { id: '3mo', name: '3 Months' },
        { id: 'halfyearly', name: 'Half-Yearly' },
        { id: 'yearly', name: 'Yearly' }
      ],
      durationPromos: {
        '3mo': '1 Month Free!',
        'halfyearly': '2 Months Free!',
        'yearly': '3 Months Free!'
      },
      plans: [],
      transactions: []
    };
  },
  computed: {
    ...mapState({
      subscription: state => state.billing.myActiveSubscription,
      isFetching: state => state.uiFlags.isFetching,
    }),
    filteredPlans() {
      return this.plans.filter(plan => 
        plan.platformType === this.selectedPlatform && 
        plan.durationType === this.selectedDuration
      );
    }
  },
  methods: {
    ...mapActions(['myActiveSubscription']),
    async fetchData() {
      try {
        this.loading = true;
        
        // Fetch current plan details
        // try {
        //   await this.$store.dispatch('myActiveSubscription');
        // } catch (error) {
        //   alertMessage =
        //     parseAPIErrorResponse(error) ||
        //     // this.$t('RESET_PASSWORD.API.ERROR_MESSAGE');
        // }
        
        const planResponse = await this.apiGet('/api/billing/current-plan');
        this.planDetails = planResponse.data;
        
        // Fetch usage statistics
        const usageResponse = await this.apiGet('/api/billing/usage');
        this.usage = usageResponse.data;
        
        // Fetch special promotions
        const promoResponse = await this.apiGet('/api/billing/special-promos');
        this.specialPromo = promoResponse.data.active ? promoResponse.data : null;
        
        // Fetch available plans
        const plansResponse = await this.apiGet('/api/billing/plans');
        this.plans = plansResponse.data;
        
        // Fetch recent transactions
        const transactionsResponse = await this.apiGet('/api/billing/transactions');
        this.transactions = transactionsResponse.data;
        
      } catch (error) {
        this.error = 'Failed to load billing data';
        console.error('Error fetching billing data:', error);
      } finally {
        this.loading = false;
      }
    },
    
    // API request helpers
    async apiGet(url) {
      // Mock API call - replace with actual axios call
      return this.getMockData(url);
    },
    
    async apiPost(url, data) {
      // Mock API post - replace with actual axios call
      console.log('API POST', url, data);
      return { success: true };
    },
    
    // Mock data for demonstration
    getMockData(url) {
      const mockResponses = {
        '/api/billing/current-plan': {
          data: {
            name: 'FREE',
            expiryDate: '2025-04-15'
          }
        },
        '/api/billing/usage': {
          data: {
            activeUsers: 0,
            additionalMau: 0,
            resetDate: 1,
            aiResponses: {
              used: 0,
              limit: 2000
            },
            additionalResponses: 0
          }
        },
        '/api/billing/special-promos': {
          data: {
            active: true,
            title: 'Paket Special Ramadan',
            name: 'Paket Ramadan "Terima Beres"',
            price: 4497000,
            originalPrice: 8997000,
            promoTag: 'LIMITED TIME',
            features: [
              'Setup AI dan Flows dengan Prompt Specialist - <span class="text-gray-700">Rp 4.000.000</span> - <span class="text-blue-500 font-medium">FREE</span>',
              'WhatsApp Anti Banned - <span class="text-gray-700">Rp 500.000</span> - <span class="text-blue-500 font-medium">FREE</span>',
              'Early Akses dan 1-on-1 Training fitur Flows, Ticketing, dan Advanced AI mode'
            ],
            description: 'Scale up penjualan dan tetap layani pelanggan di Bulan Ramadan ini! Selesaikan dalam sekali dan biarkan AIUI Prompt kami membuat AI untuk anda "Terima beres"',
            mainBenefits: [
              {
                title: 'Paket Cepat/i Business 3 bulan',
                description: 'Layanan AI otomatis untuk bisnis Anda'
              },
              {
                title: 'Setup Lengkap oleh Tim AIUI',
                description: 'Anda tinggal terima beres, semua diatur'
              },
              {
                title: 'Konsultasi Pribadi dengan AIUI Prompt',
                description: 'Optimalisasi AI Anda dengan pakar kami'
              }
            ],
            exclusiveBonuses: [
              {
                title: 'Akses Model AI & Fitur Flows Terbaru',
                description: 'Gunakan teknologi AI paling canggih'
              },
              {
                title: 'Fitur Anti-Banned WhatsApp',
                description: 'Jaga akun WhatsApp Anda tetap aman'
              },
              {
                title: 'Dukungan Prioritas 24 Jam',
                description: 'Bantuan cepat kapanpun Anda butuhkan'
              }
            ],
            limitedOffer: 'Promo Terbatas - Hanya 100 Slot!',
            ctaText: 'Dapatkan Paket Ramadan Sekarang',
            guaranteeText: 'Garansi Uang Kembali 7 Hari Jika Anda Tidak Puas',
            contactInfo: 'Promo khusus Ramadan saja. Anda akan di-contact oleh tim kami setelah pembelian.'
          }
        },
        '/api/billing/plans': {
          data: [
            {
              id: 'pro-ai-3mo',
              name: 'Pro',
              price: 1737000,
              platformType: 'ai',
              durationType: '3mo',
              packageType: 'Quarterly Package',
              features: [
                '1000 Monthly Active Users',
                '2 Human Agents',
                'Unlimited AI Agents',
                'Unlimited Connected Platforms',
                '5,000 AI Responses',
                'Cakat.AI Advanced AI Models'
              ]
            },
            {
              id: 'business-ai-3mo',
              name: 'Business',
              price: 4497000,
              platformType: 'ai',
              durationType: '3mo',
              packageType: 'Quarterly Package',
              features: [
                '5,000 Monthly Active Users',
                '5 Human Agents',
                'Unlimited AI Agents',
                'Unlimited Connected Platforms',
                '25,000 AI Responses',
                'Cakat.AI Advanced AI Models'
              ]
            },
            {
              id: 'enterprise-ai-3mo',
              name: 'Enterprise',
              price: 17397000,
              platformType: 'ai',
              durationType: '3mo',
              packageType: 'Quarterly Package',
              features: [
                '10,000 Monthly Active Users',
                '10 Human Agents',
                'Unlimited AI Agents',
                'Unlimited Connected Platforms',
                '150,000 AI Responses',
                'Cakat.AI Advanced AI Models'
              ]
            },
            {
              id: 'unlimited-ai-3mo',
              name: 'Unlimited',
              price: 47397000,
              platformType: 'ai',
              durationType: '3mo',
              packageType: 'Quarterly Package',
              features: [
                'Unlimited Monthly Active Users',
                'Unlimited Human Agents',
                'Unlimited AI Agents',
                'Unlimited Connected Platforms',
                '500,000 AI Responses',
                'Cakat.AI Advanced AI Models + Exclusive AI Models'
              ]
            }
          ]
        },
        '/api/billing/transactions': {
          data: []
        }
      };
      
      return Promise.resolve(mockResponses[url] || { data: [] });
    },
    
    // Utility methods
    formatDate(dateString) {
      const date = new Date(dateString);
      return new Intl.DateTimeFormat('en-US', { 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric' 
      }).format(date);
    },
    
    formatPrice(price) {
      return price.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".");
    },
    
    getDurationLabel(durationId) {
      switch(durationId) {
        case 'monthly': return '1mo';
        case '3mo': return '3mo';
        case 'halfyearly': return '6mo';
        case 'yearly': return '12mo';
        default: return durationId;
      }
    },
    
    getDurationPromo(durationId) {
      return this.durationPromos[durationId] || null;
    },
    
    // Action methods
    changePlatform(platformId) {
      this.selectedPlatform = platformId;
    },
    
    changeDuration(durationId) {
      this.selectedDuration = durationId;
    },
    
    async topUpMau() {
      try {
        await this.apiPost('/api/billing/topup-mau', {});
        // Handle success - perhaps show a modal or navigate to checkout
        alert('Redirecting to MAU top-up page...');
      } catch (error) {
        console.error('Error topping up MAU:', error);
      }
    },
    
    async topUpResponses() {
      try {
        await this.apiPost('/api/billing/topup-responses', {});
        // Handle success
        alert('Redirecting to AI responses top-up page...');
      } catch (error) {
        console.error('Error topping up responses:', error);
      }
    },
    
    async purchaseSpecialPromo() {
      try {
        await this.apiPost('/api/billing/purchase-promo', { promoId: 'ramadan-special' });
        // Handle success
        alert('Redirecting to checkout for Ramadan Special package...');
      } catch (error) {
        console.error('Error purchasing promo:', error);
      }
    },
    
    async purchasePlan(planId) {
      try {
        await this.apiPost('/api/billing/purchase-plan', { planId });
        // Handle success
        alert(`Redirecting to checkout for plan: ${planId}...`);
      } catch (error) {
        console.error('Error purchasing plan:', error);
      }
    },
    
    async viewTransactionDetails(transactionId) {
      try {
        // Fetch transaction details
        const response = await this.apiGet(`/api/billing/transactions/${transactionId}`);
        // Display transaction details - perhaps in a modal
        alert(`Viewing details for transaction: ${transactionId}`);
      } catch (error) {
        console.error('Error viewing transaction details:', error);
      }
    }
  },
  mounted() {
    // this.myActiveSubscription();
    this.$store.dispatch('myActiveSubscription');
    this.fetchData();
  }
};
</script>

<style scoped>
.billing-page {
  font-family: 'Inter', sans-serif;
}
.bg-gradient-to-r {
    background-image: linear-gradient(to right, var(--tw-gradient-stops));
}
.from-cyan-500 {
    --tw-gradient-from: #06b6d4 var(--tw-gradient-from-position);
    --tw-gradient-to: rgba(6, 182, 212, 0) var(--tw-gradient-to-position);
    --tw-gradient-stops: var(--tw-gradient-from), var(--tw-gradient-to);
}
.to-cyan-400 {
    --tw-gradient-to: #22d3ee var(--tw-gradient-to-position);
}
.to-violet-400 {
    --tw-gradient-to: #a78bfa var(--tw-gradient-to-position);
}
.from-violet-500 {
    --tw-gradient-from: #8b5cf6 var(--tw-gradient-from-position);
    --tw-gradient-to: rgba(139, 92, 246, 0) var(--tw-gradient-to-position);
    --tw-gradient-stops: var(--tw-gradient-from), var(--tw-gradient-to);
}
.to-blue-400 {
    --tw-gradient-to: #60a5fa var(--tw-gradient-to-position);
}
.from-blue-500 {
    --tw-gradient-from: #3b82f6 var(--tw-gradient-from-position);
    --tw-gradient-to: rgba(59, 130, 246, 0) var(--tw-gradient-to-position);
    --tw-gradient-stops: var(--tw-gradient-from), var(--tw-gradient-to);
}
.panel {
    position: relative;
    --tw-bg-opacity: 1;
    background-color: rgb(255 255 255 / var(--tw-bg-opacity));
    --tw-shadow: 0 1px 3px 0 rgba(0, 0, 0, .1), 0 1px 2px -1px rgba(0, 0, 0, .1);
    --tw-shadow-colored: 0 1px 3px 0 var(--tw-shadow-color), 0 1px 2px -1px var(--tw-shadow-color);
    box-shadow: var(--tw-ring-offset-shadow, 0 0 #0000), var(--tw-ring-shadow, 0 0 #0000), var(--tw-shadow);
    border-radius: 0.375rem;
    padding: 1.25rem;
}
</style>