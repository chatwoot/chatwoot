export function DuplicateContactException(data) {
  this.data = data;
  this.message = 'DUPLICATE_CONTACT';
}
