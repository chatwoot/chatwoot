import { faker } from '@faker-js/faker';

export interface AgentData {
  name: string;
  email: string;
  role: 'agent' | 'administrator';
  phone: string;
  availability: 'available' | 'busy' | 'offline';
  signature: string;
  password: string;
}

export const fake = {
  get email(): string {
    // Suffixed so repeat runs (and parallel workers) cannot collide on the
    // small faker first-name pool.
    return `${faker.person.firstName().toLowerCase()}-${faker.string.alphanumeric(8).toLowerCase()}@example.com`;
  },

  get password(): string {
    return this.generateStrongPassword();
  },

  get fullName(): string {
    return faker.person.fullName();
  },

  get randomSentence(): string {
    return faker.lorem.sentence();
  },

  get phoneNumber(): string {
    return `+1${faker.string.numeric(10)}`;
  },

  inboxName(): string {
    const adjective = faker.word.adjective();
    const noun = faker.word.noun();
    return `${adjective.charAt(0).toUpperCase() + adjective.slice(1)} ${noun.charAt(0).toUpperCase() + noun.slice(1)} Inbox`;
  },

  generateStrongPassword(length = 12): string {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const special = '!@#$%^&*()_+~`|}{[]\\:;?><,./-=';
    const all = uppercase + lowercase + numbers + special;

    // Guarantee one character from each set, then fill the rest.
    const required = [
      faker.helpers.arrayElement(uppercase.split('')),
      faker.helpers.arrayElement(lowercase.split('')),
      faker.helpers.arrayElement(numbers.split('')),
      faker.helpers.arrayElement(special.split('')),
    ];
    const rest = Array.from({ length: length - required.length }, () =>
      faker.helpers.arrayElement(all.split(''))
    );

    return faker.helpers.shuffle([...required, ...rest]).join('');
  },

  agent(overrides: Partial<AgentData> = {}): AgentData {
    return {
      name: this.fullName,
      email: this.email,
      role: faker.helpers.arrayElement<AgentData['role']>([
        'agent',
        'administrator',
      ]),
      phone: this.phoneNumber,
      availability: faker.helpers.arrayElement<AgentData['availability']>([
        'available',
        'busy',
        'offline',
      ]),
      signature: this.randomSentence,
      password: this.password,
      ...overrides,
    };
  },
};
