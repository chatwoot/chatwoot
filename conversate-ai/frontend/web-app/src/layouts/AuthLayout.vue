<template>
  <div class="app-layout">
    <aside class="sidebar">
      <div class="logo">Conversate AI</div>
      <nav>
        <ul>
          <li>Dashboard</li>
          <li>Conversations</li>
          <li>Contacts</li>
          <li>Settings</li>
        </ul>
      </nav>
      <div class="user-profile">
        <p>{{ userEmail }}</p>
        <button @click="handleLogout">Logout</button>
      </div>
    </aside>
    <main class="main-content">
      <router-view />
    </main>
  </div>
</template>

<script setup>
import { computed } from 'vue';
import { useAuthStore } from '../store/auth';
import { useRouter } from 'vue-router';

const authStore = useAuthStore();
const router = useRouter();

const userEmail = computed(() => authStore.user?.email || '...');

const handleLogout = () => {
  authStore.logout();
  router.push({ name: 'login' });
};
</script>

<style scoped>
.app-layout {
  display: flex;
  height: 100vh;
}
.sidebar {
  width: 240px;
  background-color: #2c3e50;
  color: white;
  display: flex;
  flex-direction: column;
  padding: 1rem;
}
.logo {
  font-size: 1.5rem;
  font-weight: bold;
  text-align: center;
  margin-bottom: 2rem;
}
nav ul {
  list-style: none;
  padding: 0;
}
nav li {
  padding: 0.75rem 1rem;
  cursor: pointer;
  border-radius: 4px;
}
nav li:hover {
  background-color: #34495e;
}
.user-profile {
  margin-top: auto;
  text-align: center;
}
.user-profile button {
  width: 100%;
  padding: 0.5rem;
  margin-top: 0.5rem;
  background-color: #e74c3c;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
.main-content {
  flex-grow: 1;
  padding: 2rem;
  background-color: #f0f2f5;
  overflow-y: auto;
}
</style>
