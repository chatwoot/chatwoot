import { faker } from '@faker-js/faker';

// Interfaces for type safety
export interface AgentData {
  name: string;
  email: string;
  role: 'agent' | 'administrator';
  phone: string;
  availability: 'available' | 'busy' | 'offline';
  signature: string;
  password: string;
}

export interface UserCredentials {
  email: string;
  password: string;
}

// Main fake data generator object
export const fake = {
  // User related
  get email(): string {
    return `${faker.person.firstName().toLowerCase()}@example.com`;
  },

  get password(): string {
    return this.generateStrongPassword();
  },

  get firstName(): string {
    return faker.person.firstName();
  },

  get lastName(): string {
    return faker.person.lastName();
  },

  get fullName(): string {
    return faker.person.fullName();
  },

  // Company related
  get companyName(): string {
    const str = `${faker.company.name()} ${faker.person.lastName()}`;
    return str.substring(0, str.indexOf(' ')).replace(/[^a-zA-Z ]/g, '');
  },

  // Inbox related
  inboxName(): string {
    const adjective = faker.word.adjective();
    const noun = faker.word.noun();
    return `${adjective.charAt(0).toUpperCase() + adjective.slice(1)} ${noun.charAt(0).toUpperCase() + noun.slice(1)} Inbox`;
  },



  // Text content
  get randomSentence(): string {
    return faker.lorem.sentence();
  },




  // Additional useful test data generators
  get phoneNumber(): string {
    const number = faker.string.numeric(10);
    return `+1${number}`;
  },

  get randomWord(): string {
    return faker.lorem.word();
  },

  get randomWords(): string {
    return faker.lorem.words(3);
  },

  get randomBoolean(): boolean {
    return faker.datatype.boolean();
  },

  get randomNumber(): number {
    return faker.number.int(1000);
  },

  get randomUuid(): string {
    return faker.string.uuid();
  },

  get randomUrl(): string {
    return faker.internet.url();
  },

  get randomImageUrl(): string {
    return faker.image.avatar();
  },

  // Existing functions as methods
  generateStrongPassword(length = 12): string {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const special = '!@#$%^&*()_+~`|}{[]\\:;?><,./-=';
    
    const all = uppercase + lowercase + numbers + special;
    let password = '';
    
    // Ensure at least one character from each set
    password += uppercase[Math.floor(Math.random() * uppercase.length)];
    password += lowercase[Math.floor(Math.random() * lowercase.length)];
    password += numbers[Math.floor(Math.random() * numbers.length)];
    password += special[Math.floor(Math.random() * special.length)];
    
    // Fill the rest randomly
    for (let i = password.length; i < length; i++) {
      password += all[Math.floor(Math.random() * all.length)];
    }
    
    // Shuffle the password to avoid predictable patterns
    return password.split('').sort(() => 0.5 - Math.random()).join('');
  },

  // Generate agent data
  agent(overrides: Partial<AgentData> = {}): AgentData {
    return {
      name: this.fullName,
      email: this.email,
      role: faker.helpers.arrayElement<AgentData['role']>(['agent', 'administrator']),
      phone: this.phoneNumber,
      availability: faker.helpers.arrayElement<AgentData['availability']>(['available', 'busy', 'offline']),
      signature: this.randomSentence,
      password: this.password,
      ...overrides,
    };
  },

  // Generate user credentials
  user(overrides: Partial<UserCredentials> = {}): UserCredentials {
    return {
      email: this.email,
      password: this.password,
      ...overrides,
    };
  },

  // Alias for backward compatibility
  generateAgentData(overrides: Partial<AgentData> = {}): AgentData {
    return this.agent(overrides);
  },

  // Alias for backward compatibility
  generateUserCredentials(overrides: Partial<UserCredentials> = {}): UserCredentials {
    return this.user(overrides);
  },

  // Alias for backward compatibility
  randomString(length: number): string {
    return faker.string.alphanumeric(length);
  },

  // Alias for backward compatibility
  randomInt(min: number = 1, max: number = 1000): number {
    return faker.number.int({ min, max });
  }
};

// Export type for better type inference
export type FakeData = typeof fake;

// Export individual functions for backward compatibility
export const {
  generateAgentData,
  generateUserCredentials,
  randomString,
  randomNumber: randomInt
} = fake;
