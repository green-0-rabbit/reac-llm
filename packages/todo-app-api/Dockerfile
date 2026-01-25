FROM node:22-alpine AS builder

WORKDIR /usr/src/app

COPY package.json ./
COPY prisma ./prisma
RUN yarn install

COPY . .
RUN yarn run build

FROM node:22-alpine AS runner
WORKDIR /usr/src/app

ENV NODE_ENV=production

COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/prisma ./prisma
COPY scripts ./scripts
COPY entrypoint.sh .

RUN chmod +x entrypoint.sh

# Create appgroup and appuser
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set permissions for /usr/src/app
# We chown the current directory recursively
RUN chown -R appuser:appgroup /usr/src/app

# Ensure specific directories exist and are writable if needed
# The user asked for "mkdir -p /usr/src/app/generated && chown ..."
RUN mkdir -p /usr/src/app/generated && chown appuser:appgroup /usr/src/app/generated

USER appuser

EXPOSE 8080

CMD ["./entrypoint.sh"]
