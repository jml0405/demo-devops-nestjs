FROM node:18-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci --omit=dev

COPY . .

FROM node:18-alpine AS runtime

USER node

WORKDIR /app

COPY --chown=node:node --from=builder /app .

ENV NODE_ENV=production \
    PORT=8000 \
    DATABASE_NAME="./dev.sqlite" \
    DATABASE_USER="user" \
    DATABASE_PASSWORD="password"

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:8000/api/users || exit 1

CMD ["node", "index.js"]
