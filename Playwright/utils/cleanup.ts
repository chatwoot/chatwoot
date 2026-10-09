import { db } from '@utils/db';

export class Cleanup {
  static async clearResetPasswordToken(token: string) {
    console.log('Clearing reset password token from any user...');
    const result = await db.query(
      `UPDATE users SET reset_password_token = NULL WHERE reset_password_token = $1`,
      [token]
    );
    if (result.rowCount > 0) {
      console.log(`Reset password token cleared from ${result.rowCount} user(s)`);
    } else {
      console.log('No reset password token found to clear');
    }
    return result.rowCount;
  }

  static async deleteUserByEmail(email: string) {
    console.log(`Deleting user: ${email}...`);
    const result = await db.query(
      `DELETE FROM users WHERE uid = $1`,
      [email]
    );
    console.log(`Deleted ${result.rowCount} user(s)`);
    return result.rowCount;
  }

  static async deleteUsersByEmails(emails: string[]) {
    console.log(`Deleting ${emails.length} user(s)...`);
    const result = await db.query(
      `DELETE FROM users WHERE uid = ANY($1)`,
      [emails]
    );
    console.log(`Deleted ${result.rowCount} user(s)`);
    return result.rowCount;
  }
}
