import { Entity, Property, Enum } from '@mikro-orm/sqlite';
import { CustomBaseEntity } from '../../../common';
import { UserRole } from '../enums/user-role.enum';

@Entity()
export class User extends CustomBaseEntity<any> {
  @Property({ unique: true })
  email!: string;

  @Enum(() => UserRole)
  role!: UserRole;

  @Property({ nullable: true })
  firstName?: string;

  @Property({ nullable: true })
  lastName?: string;

  @Property({ nullable: true })
  country?: string;

  @Property({ nullable: true })
  jobTitle?: string;

  @Property({ nullable: true })
  entity?: string;

  @Property({ nullable: true })
  signedAt?: Date;
}
