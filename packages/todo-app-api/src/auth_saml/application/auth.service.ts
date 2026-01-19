import {
  Inject,
  Injectable,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { EntityManager } from '@mikro-orm/core';
import type { ConfigType } from '@nestjs/config';
import { authSamlConfig } from '../../configuration/auth-saml.config';
import { User } from '../domain/entities/user.entity';
import { UserRole } from '../domain/enums/user-role.enum';

interface SamlProfile {
  attributes?: Record<string, any>;
}

interface UserData {
  email: string;
  role: string;
  firstName?: string | null;
  lastName?: string | null;
  entity?: string | null;
  country?: string | null;
}

const COUNTRY_CODE_BY_SUFFIX: Record<string, string> = {
    MC: 'MC',
    HK: 'HK',
    SG: 'SG',
    IT: 'IT',
    CH: 'CH',
    BE: 'BE',
    ES: 'ES',
    LU: 'LU',
};

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private jwtService: JwtService,
    private readonly em: EntityManager,
    @Inject(authSamlConfig.KEY)
    private readonly authCfg: ConfigType<typeof authSamlConfig>,
  ) {}

  async validateUserFromSamlProfile(profile: SamlProfile): Promise<UserData> {
    try {
      this.logger.log('Validating SAML profile', profile);
      const attrs = profile.attributes || {};

      const email = attrs.email || attrs.mail || attrs.Email || null;
      const role = attrs.Role || attrs.role || null;
      const firstName =
        attrs.firstName || attrs.givenName || attrs['FirstName'] || null;
      const lastName =
        attrs.lastName ||
        attrs.sn ||
        attrs.surname ||
        attrs['LastName'] ||
        null;
      const entity = attrs.entity || attrs['Entity'] || null;
      const country = attrs.country || attrs['Country'] || null;

      if (!email) throw new Error('Email missing in SAML profile');

      return { email, role, firstName, lastName, entity, country };
    } catch (error) {
      if (error instanceof Error) {
        this.logger.error(
          'Error validating SAML profile',
          error.stack || error.message,
        );
      }
      throw new InternalServerErrorException('Failed to validate SAML profile');
    }
  }

  private resolveCountryCodeFromEmail(email: string): string {
      if (!email) return 'FR';
      const atIndex = email.lastIndexOf('@');
      if (atIndex === -1 || atIndex === email.length - 1) return 'FR';

      const domain = email.slice(atIndex + 1).toUpperCase();
      const lastSegment = domain.split('.').pop() || '';

      if (lastSegment === 'UAE') return 'AE';
      const suffix2 = lastSegment.slice(-2);
      return COUNTRY_CODE_BY_SUFFIX[suffix2] || 'FR';
  }

  async findOrCreateUser(userData: UserData) {
    try {
      const email = userData.email;
      const country = userData.country || this.resolveCountryCodeFromEmail(email);
      let user = await this.em.findOne(User, { email });

      const requestedRole = userData.role as UserRole;
      const role = Object.values(UserRole).includes(requestedRole)
        ? requestedRole
        : UserRole.VIEWER;

      if (user) {
        if (user.role !== role) {
          user.role = role;
          await this.em.flush();
        }
        return { user };
      }

      user = this.em.create(User, {
        email,
        firstName: userData.firstName ?? undefined,
        lastName: userData.lastName ?? undefined,
        role: role,
        country: country,
      });
      
      await this.em.persist(user).flush();

      return { user };
    } catch (error) {
       if (error instanceof Error) {
        this.logger.error(
            'Error finding or creating user',
            error.stack || error.message,
        );
       }
      throw new InternalServerErrorException('Failed to find or create user');
    }
  }

  async createAccessTokenForUser(
    user: any,
  ): Promise<{ accessToken: string; expires: Date }> {
    try {
      const payload = {
        userId: user.id,
        email: user.email,
        role: user.role,
        name: `${user.firstName ?? ''} ${user.lastName ?? ''}`.trim(),
      };

      const token = await this.jwtService.signAsync(payload, {
        expiresIn: this.authCfg.jwtAccessExpiresIn,
      });

      return {
        accessToken: token,
        expires: new Date(Date.now() + (this.authCfg.jwtAccessExpiresIn || 3600) * 1000),
      };
    } catch (error) {
       this.logger.error('Error creating access token', error);
      throw new InternalServerErrorException('Failed to create access token');
    }
  }

  async validateAccessToken(token: string): Promise<any> {
    try {
      const payload = await this.jwtService.verifyAsync(token);
      return payload;
    } catch {
      return null;
    }
  }
}
