import fs from 'fs/promises';
import path from 'path';
import Ajv from 'ajv';
import { createSchema } from 'genson-js';
import addFormats from 'ajv-formats';

const SCHEMA_BASE_PATH = path.resolve(__dirname, '../response-schemas');
const ajv = new Ajv({ allErrors: true, strict: false });
addFormats(ajv);

/**
 * Validates API response against a stored JSON schema.
 *
 * @param dirName - Directory name under response-schemas/ (e.g., 'agent', 'inbox', 'conversation')
 * @param fileName - Schema file name without extension (e.g., 'create_agent')
 * @param responseBody - The API response body to validate
 * @param createSchemaFlag - If true, generates new schema from response (useful for initial setup)
 *
 * @example
 * ```typescript
 * // Validate agent creation response
 * await validateSchema('agent', 'create_agent', responseData);
 *
 * // Generate schema on first run, then validate
 * await validateSchema('agent', 'create_agent', responseData, true);
 * ```
 *
 * @throws Error if schema validation fails or schema file cannot be read
 */
export async function validateSchema(
  dirName: string,
  fileName: string,
  responseBody: object,
  createSchemaFlag: boolean = false
) {
  const schemaPath = path.join(SCHEMA_BASE_PATH, dirName, `${fileName}_schema.json`);

  if (createSchemaFlag) {
    await generateNewSchema(responseBody, schemaPath);
    console.log(`[SchemaValidator] Generated new schema: ${schemaPath}`);
  }

  const schema = await loadSchema(schemaPath);
  const validate = ajv.compile(schema);

  const valid = validate(responseBody);
  if (!valid) {
    throw new Error(
      `Schema validation failed for ${fileName}_schema.json:\n` +
        `${JSON.stringify(validate.errors, null, 4)}\n\n` +
        `Actual response body:\n` +
        `${JSON.stringify(responseBody, null, 4)}`
    );
  }
}

/**
 * Loads a JSON schema from the file system.
 *
 * @param schemaPath - Absolute or relative path to schema file
 * @returns Parsed JSON schema object
 * @throws Error if schema file cannot be read or parsed
 */
async function loadSchema(schemaPath: string) {
  try {
    const schemaContent = await fs.readFile(schemaPath, 'utf-8');
    return JSON.parse(schemaContent);
  } catch (error: any) {
    throw new Error(`Failed to read schema file at ${schemaPath}: ${error.message}`);
  }
}

/**
 * Generates a JSON schema from a response body using genson-js.
 *
 * @param responseBody - The API response to generate schema from
 * @param schemaPath - Path where the schema file should be saved
 * @throws Error if schema generation or file write fails
 */
async function generateNewSchema(responseBody: object, schemaPath: string) {
  try {
    const generatedSchema = createSchema(responseBody);
    await fs.mkdir(path.dirname(schemaPath), { recursive: true });
    await fs.writeFile(schemaPath, JSON.stringify(generatedSchema, null, 4));
  } catch (error: any) {
    throw new Error(`Failed to create schema file at ${schemaPath}: ${error.message}`);
  }
}
