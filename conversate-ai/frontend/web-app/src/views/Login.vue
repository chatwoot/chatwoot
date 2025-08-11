<template>
  <div class="auth-container">
    <div class="auth-form">
      <h2>Login to Conversate AI</h2>
      <form @submit.prevent="handleLogin">
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
          {{ loading ? 'Logging in...' : 'Login' }}
        </button>
      </form>
      <p class="switch-form">
        Don't have an account?
        <!-- In a real app, this would be a <router-link> -->
        <a href="#">Register</a>
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useAuthStore } from '../store/auth';
// import { useRouter } from 'vue-router'; // Would be used to redirect after login

const email = ref('');
const password = ref('');
const loading = ref(false);
const error = ref(null);

const authStore = useAuthStore();
// const router = useRouter();

const handleLogin = async () => {
  loading.value = true;
  error.value = null;
  const success = await authStore.login(email.value, password.value);
  loading.value = false;

  if (success) {
    // router.push({ name: 'dashboard' }); // Redirect to a protected route
    alert('Login successful!');
  } else {
    error.value = 'Login failed. Please check your credentials.';
  }
};
</script>

<style scoped>
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
