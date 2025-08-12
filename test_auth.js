// No console do navegador, execute:
const authData = JSON.parse(localStorage.getItem('authData') || '{}');
console.log('Auth data:', authData);

// Ou verifique os cookies:
document.cookie.split(';').forEach(cookie => {
  if (cookie.includes('access-token') || cookie.includes('client') || cookie.includes('uid')) {
    console.log(cookie.trim());
  }
});