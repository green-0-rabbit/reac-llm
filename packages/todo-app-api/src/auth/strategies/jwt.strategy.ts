import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { passportJwtSecret } from 'jwks-rsa';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  private readonly logger = new Logger(JwtStrategy.name);

  constructor(configService: ConfigService) {
    const issuer = configService.get<string>('AUTH_ISSUER_URL');
    const jwksUri = configService.get<string>('AUTH_JWKS_URI');

    if (!issuer) {
      throw new Error('AUTH_ISSUER_URL is not defined');
    }

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKeyProvider: passportJwtSecret({
        cache: true,
        rateLimit: true,
        jwksRequestsPerMinute: 5,
        jwksUri: jwksUri || `${issuer}/protocol/openid-connect/certs`,
      }),
      issuer: issuer,
      algorithms: ['RS256'],
    });
  }

  async validate(payload: any) {
    this.logger.debug(`Validated payload: ${JSON.stringify(payload)}`);
    return { 
      userId: payload.sub, 
      username: payload.preferred_username, 
      roles: payload.realm_access?.roles,
      email: payload.email
    };
  }
}
