import { db } from '@utils/db';

export class Cleanup {
  static async deleteUserByEmail(email: string) {
    console.log(`Deleting user: ${email}...`);

    // user_sessions has a NO ACTION foreign key on users, so a raw delete has
    // to clear the sessions first.
    await db.query(
      `DELETE FROM user_sessions WHERE user_id IN (SELECT id FROM users WHERE uid = $1)`,
      [email]
    );

    const result = await db.query(`DELETE FROM users WHERE uid = $1`, [email]);
    const rowCount = result.rowCount ?? 0;
    console.log(`Deleted ${rowCount} user(s)`);
    return rowCount;
  }
}
