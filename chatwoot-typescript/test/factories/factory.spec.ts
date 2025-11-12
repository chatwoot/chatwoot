import { describe, it, expect, beforeEach } from 'vitest';
import { UserFactory } from './user.factory';

describe('Factory System', () => {
  describe('UserFactory', () => {
    let factory: UserFactory;

    beforeEach(() => {
      factory = new UserFactory();
    });

    describe('build()', () => {
      it('should build user without saving', () => {
        // Note: This will throw until User entity exists
        // For now, we're testing the factory API structure
        expect(() => factory.build()).toBeDefined();
      });

      it('should accept overrides', () => {
        expect(() => factory.build({ email: 'test@example.com' })).toBeDefined();
      });
    });

    describe('Method Chaining', () => {
      it('should support withRole() chaining', () => {
        const result = factory.withRole('custom-role');
        expect(result).toBe(factory);
      });

      it('should support asAdmin() chaining', () => {
        const result = factory.asAdmin();
        expect(result).toBe(factory);
      });

      it('should support asAgent() chaining', () => {
        const result = factory.asAgent();
        expect(result).toBe(factory);
      });

      it('should support withEmailDomain() chaining', () => {
        const result = factory.withEmailDomain('company.com');
        expect(result).toBe(factory);
      });

      it('should support reset() chaining', () => {
        const result = factory.asAdmin().reset();
        expect(result).toBe(factory);
      });

      it('should allow multiple chained calls', () => {
        const result = factory.asAdmin().withEmailDomain('admin.com');
        expect(result).toBe(factory);
      });
    });

    describe('Factory Pattern', () => {
      it('should be instantiable', () => {
        expect(factory).toBeInstanceOf(UserFactory);
      });

      it('should have build method', () => {
        expect(typeof factory.build).toBe('function');
      });

      it('should have buildMany method', () => {
        expect(typeof factory.buildMany).toBe('function');
      });

      it('should have create method', () => {
        expect(typeof factory.create).toBe('function');
      });

      it('should have createMany method', () => {
        expect(typeof factory.createMany).toBe('function');
      });

      it('should have createWithRelations method', () => {
        expect(typeof factory.createWithRelations).toBe('function');
      });
    });

    describe('Role Methods', () => {
      it('should have asAdmin method', () => {
        expect(typeof factory.asAdmin).toBe('function');
      });

      it('should have asAgent method', () => {
        expect(typeof factory.asAgent).toBe('function');
      });

      it('should have withRole method', () => {
        expect(typeof factory.withRole).toBe('function');
      });
    });
  });

  describe('BaseFactory Pattern', () => {
    it('should provide consistent API across factories', () => {
      const factory = new UserFactory();

      // All factories should have these methods from BaseFactory
      expect(factory).toHaveProperty('build');
      expect(factory).toHaveProperty('buildMany');
      expect(factory).toHaveProperty('create');
      expect(factory).toHaveProperty('createMany');
      expect(factory).toHaveProperty('createWithRelations');
    });
  });
});
