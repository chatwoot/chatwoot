<template>
  <div class="auth-container">
    <div class="auth-form">
      <h2>Create your Conversate AI Account</h2>
      <form @submit.prevent="handleRegister">
        <div class="form-group">
          <label for="accountName">Account Name</label>
          <input type="text" id="accountName" v-model="accountName" required />
        </div>
        <div class="form-group">
          <label for="email">Email</label>
          <input type="email" id="email" v-model="email" required />
        </div>
        <div class="form-group">
          <label for="password">Password</label>
          <input type="password" id="password" v-model="password" required />
        </div>
        <div v-if="error" class="error-message">{{ error }}</div>
        <button type="submit" :disabled="loading">
          {{ loading ? 'Creating Account...' : 'Sign Up' }}
        </button>
      </form>
      <p class="switch-form">
        Already have an account?
        <!-- In a real app, this would be a <router-link> -->
        <a href="#">Login</a>
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useAuthStore } from '../store/auth';
// import { useRouter } from 'vue-router';

const accountName = ref('');
const email = ref('');
const password = ref('');
const loading = ref(false);
const error = ref(null);

const authStore = useAuthStore();
// const router = useRouter();

const handleRegister = async () => {
  loading.value = true;
  error.value = null;
  const success = await authStore.register(email.value, password.value, accountName.value);
  loading.value = false;

  if (success) {
    // router.push({ name: 'dashboard' });
    alert('Registration successful! You are now logged in.');
  } else {
    error.value = 'Registration failed. Please try again.';
  }
};
</script>

<style scoped>
/* Re-using the same styles as Login.vue for consistency */
.auth-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  background-color: #f0f2f5;
}
.auth-form {
  padding: 2rem;
  background: white;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  width: 100%;
  max-width: 400px;
}
h2 {
  margin-bottom: 1.5rem;
  text-align: center;
}
.form-group {
  margin-bottom: 1rem;
}
label {
  display: block;
  margin-bottom: 0.5rem;
}
input {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ccc;
  border-radius: 4px;
}
button {
  width: 100%;
  padding: 0.75rem;
  border: none;
  background-color: #007bff;
  color: white;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
}
button:disabled {
  background-color: #a0cfff;
}
.error-message {
  color: red;
  margin-bottom: 1rem;
  text-align: center;
}
.switch-form {
  text-align: center;
  margin-top: 1rem;
}
</style>
