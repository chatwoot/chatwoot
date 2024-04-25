export function useAlert(message, action) {
  bus.$emit('newToastMessage', message, action);
}
