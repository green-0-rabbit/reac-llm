import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-saml';
import { Inject, Injectable } from '@nestjs/common';
import { AuthService } from '../../application/auth.service';
import { authSamlConfig } from 'src/configuration/auth-saml.config';
import type { ConfigType } from '@nestjs/config';

@Injectable()
export class SamlStrategy extends PassportStrategy(Strategy, 'saml') {
  constructor(
    private readonly authService: AuthService,
    @Inject(authSamlConfig.KEY)
    private readonly authCfg: ConfigType<typeof authSamlConfig>,
  ) {
    const { entryPoint, issuer, cert, path } = authCfg;

    if (!cert) {
      throw new Error('SAML certificate (cert) must be defined in auth config');
    }

    super({
      path,
      entryPoint,
      issuer,
      cert,
      validateInResponseTo: false,
      disableRequestedAuthnContext: true,
      acceptedClockSkewMs: 300000,
    });
  }

  async validate(profile: any, done: Function) {
    try {
      const user = await this.authService.validateUserFromSamlProfile(profile);
      done(null, user);
    } catch (error) {
      done(error, false);
    }
  }
}
