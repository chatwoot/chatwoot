import { Entity, Column, Index } from 'typeorm';
import { BaseEntity } from '../base.entity';

export enum UserRole {
  ADMINISTRATOR = 'administrator',
  AGENT = 'agent',
}

@Entity('users')
@Index(['email'], { unique: true })
export class User extends BaseEntity {
  @Column({ type: 'varchar', length: 255 })
  name!: string;

  @Column({ type: 'varchar', length: 255, unique: true })
  email!: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  password?: string;

  @Column({ type: 'varchar', length: 255, nullable: true, name: 'avatar_url' })
  avatarUrl?: string;

  @Column({
    type: 'enum',
    enum: UserRole,
    default: UserRole.AGENT,
  })
  role!: UserRole;

  @Column({ type: 'boolean', default: true })
  active!: boolean;

  @Column({ type: 'timestamp', nullable: true, name: 'confirmed_at' })
  confirmedAt?: Date;

  @Column({ type: 'timestamp', nullable: true, name: 'last_sign_in_at' })
  lastSignInAt?: Date;

  @Column({ type: 'varchar', length: 255, nullable: true, name: 'confirmation_token' })
  confirmationToken?: string;

  @Column({ type: 'varchar', length: 255, nullable: true, name: 'reset_password_token' })
  resetPasswordToken?: string;

  @Column({ type: 'timestamp', nullable: true, name: 'reset_password_sent_at' })
  resetPasswordSentAt?: Date;
}
