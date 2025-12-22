import { ExecutionContext, Injectable, Logger, UnauthorizedException } from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { ExecutionContextHost } from "@nestjs/core/helpers/execution-context-host";
import { AuthGuard } from "@nestjs/passport";
import { CustomContextType } from "../types";
import { IS_PUBLIC_KEY } from "../decorators";

@Injectable()
export class JwtAuthGuard extends AuthGuard("jwt") {
  private readonly logger = new Logger(JwtAuthGuard.name);

  constructor(private reflector: Reflector) {
    super();
  }
  canActivate(ctx: ExecutionContext) {
    const restContext = ctx.switchToHttp().getRequest();
    const contextType = ctx.getType<CustomContextType>();
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      ctx.getHandler(),
      ctx.getClass()
    ]);
    if (isPublic) {
      return true;
    }
    if (contextType === "http") {
      return super.canActivate(ctx);
    }

    const { req } = restContext.getContext();
    return super.canActivate(new ExecutionContextHost([req])); // NOTE
  }

  handleRequest(err: any, user: any, info: any) {
    if (err || !user) {
      this.logger.error(`Authentication failed: ${info?.message || err?.message}`);
      if (err) {
        this.logger.error(err);
      }
      if (info) {
        this.logger.error(info);
      }
      throw err || new UnauthorizedException();
    }
    return user;
  }
}
