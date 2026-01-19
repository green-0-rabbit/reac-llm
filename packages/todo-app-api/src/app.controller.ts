import { Controller, Get, UseGuards } from '@nestjs/common';
import { AppService } from './app.service';
import { Roles } from './auth_saml/infrastructure/decorators/roles.decorator';
import { UserRole } from './auth_saml/domain/enums/user-role.enum';
import { AuthGuard } from './auth_saml/infrastructure/guards/auth.guard';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  // @UseGuards(AuthGuard)
  @Roles(UserRole.ADMIN)
  getHello(): string {
    return this.appService.getHello();
  }
}
