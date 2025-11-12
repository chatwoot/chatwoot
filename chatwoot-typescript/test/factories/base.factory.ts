import { DeepPartial, ObjectLiteral, Repository } from 'typeorm';

/**
 * Base factory class for creating test entities
 * Provides common methods for building and creating entities
 */
export abstract class BaseFactory<T extends ObjectLiteral> {
  /**
   * Get the TypeORM repository for this entity
   */
  protected abstract getRepository(): Repository<T>;

  /**
   * Get default attributes for this entity
   * Override in subclasses to provide faker data
   */
  protected abstract getDefaultAttributes(): DeepPartial<T>;

  /**
   * Build an entity without saving to database
   * Useful for testing entity logic without database
   *
   * @param overrides - Attributes to override defaults
   * @returns Entity instance (not saved)
   */
  build(overrides?: DeepPartial<T>): T {
    const defaults = this.getDefaultAttributes();
    return this.getRepository().create({ ...defaults, ...overrides } as DeepPartial<T>);
  }

  /**
   * Build multiple entities without saving
   *
   * @param count - Number of entities to build
   * @param overrides - Attributes to override defaults
   * @returns Array of entity instances (not saved)
   */
  buildMany(count: number, overrides?: DeepPartial<T>): T[] {
    return Array.from({ length: count }, () => this.build(overrides));
  }

  /**
   * Create and save an entity to database
   *
   * @param overrides - Attributes to override defaults
   * @returns Saved entity with ID
   */
  async create(overrides?: DeepPartial<T>): Promise<T> {
    const entity = this.build(overrides);
    return this.getRepository().save(entity);
  }

  /**
   * Create and save multiple entities
   *
   * @param count - Number of entities to create
   * @param overrides - Attributes to override defaults
   * @returns Array of saved entities with IDs
   */
  async createMany(count: number, overrides?: DeepPartial<T>): Promise<T[]> {
    const entities = this.buildMany(count, overrides);
    return this.getRepository().save(entities);
  }

  /**
   * Create entity with related entities
   * Useful for complex entity graphs
   *
   * @param overrides - Attributes to override defaults
   * @param relations - Related entities to attach
   * @returns Saved entity with relations
   */
  async createWithRelations(
    overrides?: DeepPartial<T>,
    relations?: Record<string, any>,
  ): Promise<T> {
    const entity = await this.create(overrides);
    if (relations) {
      Object.assign(entity as object, relations);
      return this.getRepository().save(entity);
    }
    return entity;
  }
}
