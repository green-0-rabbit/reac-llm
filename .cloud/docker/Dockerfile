FROM node:23-alpine

WORKDIR /usr/src/app

# Create a non-root user for security best practices
# RUN addgroup --system --gid 1001 node
# RUN adduser --system --uid 1001 node
USER node

COPY --chown=node:node ./dist ./dist

EXPOSE 3000

CMD ["node", "dist/main.js"]