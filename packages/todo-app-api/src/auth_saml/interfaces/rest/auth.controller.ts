import {
  Controller,
  Get,
  HttpStatus,
  Inject,
  InternalServerErrorException,
  Logger,
  Post,
  Req,
  Res,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from '../../application/auth.service';
import { type ConfigType } from '@nestjs/config';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiCookieAuth,
} from '@nestjs/swagger';
import { Public } from '../../infrastructure/decorators/public.decorator';
import { authSamlConfig } from 'src/configuration/auth-saml.config';

const cookieOptions = {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'lax',
};

@Public()
@ApiTags('auth')
@ApiCookieAuth()
@Controller('auth')
export class AuthController {
  private readonly logger = new Logger(AuthController.name);

  constructor(
    private authService: AuthService,
    @Inject(authSamlConfig.KEY)
    private readonly authCfg: ConfigType<typeof authSamlConfig>,
  ) {}

  @Get('login')
  @ApiOperation({ summary: 'Initiate SAML login' })
  @UseGuards(AuthGuard('saml'))
  login() {}

  @Post('saml/callback')
  @ApiOperation({ summary: 'SAML callback endpoint' })
  @UseGuards(AuthGuard('saml'))
  async callback(@Req() req: any, @Res() res: any) {
    try {
      if (!req.user) {
        throw new InternalServerErrorException('User not set in request');
      }

      this.logger.log('User authenticated via SAML', req.user);
      const { user } = await this.authService.findOrCreateUser(req.user);

      const { accessToken, expires } =
        await this.authService.createAccessTokenForUser(user);
        
      // TODO: Implement refresh token logic if needed
      // const { refreshToken, expires: refreshExpires } =
      //   await this.authService.createRefreshTokenForUser(user);

      res.cookie(
        this.authCfg.jwtAccessCookieName,
        accessToken,
        {
            ...cookieOptions,
            expires,
        } // as CookieOptions,
      );
      
      // res.cookie(
      //   this.authCfg.jwtRefreshCookieName,
      //   refreshToken,
      //   {
      //       ...cookieOptions,
      //       expires: refreshExpires,
      //   }
      // );

      return res.redirect(`${this.authCfg.frontendUrl}`);
    } catch (error) {
      this.logger.error('SAML callback error', error);
      res.status(HttpStatus.INTERNAL_SERVER_ERROR).send('Authentication failed');
    }
  }
}
