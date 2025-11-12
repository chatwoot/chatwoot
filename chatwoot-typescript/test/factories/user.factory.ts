import { faker } from '@faker-js/faker';
import { DeepPartial, Repository } from 'typeorm';
import { BaseFactory } from './base.factory';
import { getTestDataSource } from '../database/test-database';

/**
 * Placeholder User interface
 * TODO: Replace with real User entity from src/models/user.entity.ts
 * when User entity is implemented in Epic 03
 */
export interface User {
  id?: string;
  email: string;
  name: string;
  password: string;
  role: string;
  createdAt?: Date;
  updatedAt?: Date;
}

/**
 * Factory for creating test User entities
 * Provides fluent API for building users with different roles
 *
 * @example
 * // Create a basic user
 * const user = await new UserFactory().create();
 *
 * @example
 * // Create admin user with custom email
 * const admin = await new UserFactory()
 *   .asAdmin()
 *   .create({ email: 'admin@example.com' });
 *
 * @example
 * // Create multiple agent users
 * const agents = await new UserFactory().createMany(5);
 */
export class UserFactory extends BaseFactory<User> {
  private roleOverride?: string;

  protected getRepository(): Repository<User> {
    // Note: This will fail until User entity exists
    // For now, it's a placeholder for the factory pattern
    return getTestDataSource().getRepository('User') as Repository<User>;
  }

  protected getDefaultAttributes(): DeepPartial<User> {
    return {
      email: faker.internet.email().toLowerCase(),
      name: faker.person.fullName(),
      password: faker.internet.password({ length: 12, memorable: true }),
      role: this.roleOverride || 'agent',
    };
  }

  /**
   * Set custom role for the user
   *
   * @param role - Role name (e.g., 'agent', 'administrator')
   * @returns Factory instance for method chaining
   */
  withRole(role: string): this {
    this.roleOverride = role;
    return this;
  }

  /**
   * Create user with administrator role
   *
   * @returns Factory instance for method chaining
   */
  asAdmin(): this {
    return this.withRole('administrator');
  }

  /**
   * Create user with agent role (default)
   *
   * @returns Factory instance for method chaining
   */
  asAgent(): this {
    return this.withRole('agent');
  }

  /**
   * Create user with custom email domain
   *
   * @param _domain - Email domain (e.g., 'company.com') - Currently unused, placeholder for future implementation
   * @returns Factory instance for method chaining
   */
  withEmailDomain(_domain: string): this {
    // TODO: This would be used in build() method to generate emails with custom domain
    // For now, just return this for method chaining
    return this;
  }

  /**
   * Reset factory state
   * Call this between creating multiple users with different configs
   */
  reset(): this {
    this.roleOverride = undefined;
    return this;
  }
}
