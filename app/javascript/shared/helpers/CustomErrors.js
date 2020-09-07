export class DuplicateContactException extends Error {
  constructor(data) {
    super('DUPLICATE_CONTACT');
    this.data = data;
    this.name = 'DuplicateContactException';
  }
}
