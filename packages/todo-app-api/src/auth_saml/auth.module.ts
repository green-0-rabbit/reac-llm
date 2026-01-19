import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { AuthService } from './application/auth.service';
import { SamlStrategy } from './infrastructure/strategies/saml.strategy';
import { AuthController } from './interfaces/rest/auth.controller';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { authSamlConfig } from '../configuration/auth-saml.config';
import { JwtModule } from '@nestjs/jwt';
import { APP_GUARD } from '@nestjs/core';
import { AuthGuard } from './infrastructure/guards/auth.guard';
import { MikroOrmModule } from '@mikro-orm/nestjs';
import { User } from './domain/entities/user.entity';

@Module({
  imports: [
    PassportModule.register({ session: false, defaultStrategy: 'saml' }),
    ConfigModule.forFeature(authSamlConfig),
    MikroOrmModule.forFeature([User]),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('auth_saml.jwtSecret'),
        signOptions: {
          expiresIn: config.get<number>('auth_saml.jwtAccessExpiresIn'),
        },
      }),
    }),
  ],
  providers: [
    AuthService,
    SamlStrategy,
    {
      provide: APP_GUARD,
      useClass: AuthGuard,
    },
  ],
  controllers: [AuthController],
  exports: [AuthService],
})
export class AuthModule {}
