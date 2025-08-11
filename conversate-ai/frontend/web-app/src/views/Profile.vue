<template>
  <div class="profile-page">
    <h2>My Profile</h2>
    <div v-if="loading" class="loading">Loading...</div>
    <div v-if="error" class="error">{{ error }}</div>
    <div v-if="user" class="profile-details">
      <p><strong>User ID:</strong> {{ user.id }}</p>
      <p><strong>Email:</strong> {{ user.email }}</p>
      <p><strong>Account ID:</strong> {{ user.account_id }}</p>
      <p><strong>Active:</strong> {{ user.is_active }}</p>
      <p><strong>Member since:</strong> {{ new Date(user.created_at).toLocaleDateString() }}</p>
    </div>
  </div>
</template>

<script setup>
import { onMounted, computed, ref } from 'vue';
import { useAuthStore } from '../store/auth';

const authStore = useAuthStore();
const loading = ref(false);
const error = ref(null);

const user = computed(() => authStore.user);

onMounted(async () => {
  // If the user data is not already in the store, fetch it.
  if (!authStore.user) {
    loading.value = true;
    error.value = null;
    try {
      await authStore.fetchUser();
    } catch (e) {
      error.value = 'Failed to fetch user profile.';
    } finally {
      loading.value = false;
    }
  }
});
</script>

<style scoped>
.profile-page {
  padding: 1rem;
  background: white;
  border-radius: 8px;
}
.profile-details p {
  margin: 0.5rem 0;
}
.loading, .error {
  text-align: center;
  padding: 2rem;
  font-size: 1.2rem;
}
.error {
  color: red;
}
</style>
