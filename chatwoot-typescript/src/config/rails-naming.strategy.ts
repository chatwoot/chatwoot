import { DefaultNamingStrategy, NamingStrategyInterface, Table } from 'typeorm';
import { snakeCase } from 'typeorm/util/StringUtils';
import pluralize from 'pluralize';

/**
 * Rails Naming Strategy for TypeORM
 *
 * Ensures TypeORM entities match Rails Active Record naming conventions:
 * - Table names: plural, snake_case (e.g., "user_accounts")
 * - Column names: snake_case (e.g., "created_at")
 * - Foreign keys: <table_name>_id (e.g., "account_id")
 * - Join tables: <table1>_<table2> (e.g., "accounts_users")
 *
 * This allows TypeORM to work seamlessly with an existing Rails database.
 */
export class RailsNamingStrategy
  extends DefaultNamingStrategy
  implements NamingStrategyInterface
{
  /**
   * Convert class name to table name
   * Examples:
   * - User → users
   * - AccountUser → account_users
   * - Channel::FacebookPage → channel_facebook_pages
   */
  tableName(targetName: string, userSpecifiedName: string | undefined): string {
    if (userSpecifiedName) {
      return userSpecifiedName;
    }

    // Convert class name to snake_case and pluralize
    return pluralize(snakeCase(targetName));
  }

  /**
   * Convert property name to column name
   * Examples:
   * - createdAt → created_at
   * - accountId → account_id
   */
  columnName(
    propertyName: string,
    customName: string | undefined,
    embeddedPrefixes: string[],
  ): string {
    if (customName) {
      return customName;
    }

    // Apply embedded prefixes if any
    const nameWithPrefix = embeddedPrefixes.concat(propertyName).join('_');
    return snakeCase(nameWithPrefix);
  }

  /**
   * Convert relation name to column name
   * Example: account → account
   */
  relationName(propertyName: string): string {
    return snakeCase(propertyName);
  }

  /**
   * Generate foreign key column name
   * Examples:
   * - account, id → account_id
   * - user, id → user_id
   */
  joinColumnName(relationName: string, referencedColumnName: string): string {
    return snakeCase(`${relationName}_${referencedColumnName}`);
  }

  /**
   * Generate join table name for many-to-many relationships
   * Examples:
   * - accounts, users → accounts_users
   * - tags, conversations → conversations_tags (alphabetical order)
   */
  joinTableName(
    firstTableName: string,
    secondTableName: string,
    _firstPropertyName?: string,
    _secondPropertyName?: string,
  ): string {
    // Rails convention: alphabetical order
    const tables = [firstTableName, secondTableName].sort();
    return snakeCase(`${tables[0]}_${tables[1]}`);
  }

  /**
   * Generate join table column name
   * Examples:
   * - users, id → user_id
   */
  joinTableColumnName(
    tableName: string,
    propertyName: string,
    columnName?: string,
  ): string {
    const singularTableName = pluralize.singular(tableName);
    return snakeCase(
      `${singularTableName}_${columnName ? columnName : propertyName}`,
    );
  }

  /**
   * Generate index name
   * Rails convention: index_<table>_on_<column(s)>
   */
  indexName(
    tableOrName: Table | string,
    columnNames: string[],
    _where?: string,
  ): string {
    const tableName =
      typeof tableOrName === 'string' ? tableOrName : tableOrName.name;
    const columnsSnakeCase = columnNames
      .map((col) => snakeCase(col))
      .join('_and_');
    return `index_${tableName}_on_${columnsSnakeCase}`;
  }

  /**
   * Generate unique constraint name
   * Rails convention: unique_<table>_on_<column(s)>
   */
  uniqueConstraintName(
    tableOrName: Table | string,
    columnNames: string[],
  ): string {
    const tableName =
      typeof tableOrName === 'string' ? tableOrName : tableOrName.name;
    const columnsSnakeCase = columnNames
      .map((col) => snakeCase(col))
      .join('_and_');
    return `unique_${tableName}_on_${columnsSnakeCase}`;
  }

  /**
   * Generate foreign key name
   * Rails convention: fk_rails_<hash>
   */
  foreignKeyName(
    tableOrName: Table | string,
    columnNames: string[],
    _referencedTablePath?: string,
    _referencedColumnNames?: string[],
  ): string {
    const tableName =
      typeof tableOrName === 'string' ? tableOrName : tableOrName.name;
    const columnsSnakeCase = columnNames
      .map((col) => snakeCase(col))
      .join('_');

    // Generate a simple hash (Rails uses MD5 but we'll use a simple version)
    const hash = this.generateHash(`${tableName}_${columnsSnakeCase}`);
    return `fk_rails_${hash}`;
  }

  /**
   * Simple hash generator for foreign key names
   */
  private generateHash(input: string): string {
    let hash = 0;
    for (let i = 0; i < input.length; i++) {
      const char = input.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return Math.abs(hash).toString(16).substring(0, 10);
  }
}
