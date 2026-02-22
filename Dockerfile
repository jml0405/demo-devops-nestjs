# ─── Stage 1: Builder ────────────────────────────────────────────────────────
FROM node:18-alpine AS builder

WORKDIR /app

# Copy dependency manifests first (layer cache optimisation)
COPY package.json package-lock.json ./

# Clean install – only production deps
RUN npm ci --omit=dev

# Copy application source
COPY . .

# ─── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM node:18-alpine AS runtime

# Run as non-root user (built-in "node" user on alpine)
USER node

WORKDIR /app

# Copy production node_modules + app from builder
COPY --chown=node:node --from=builder /app/node_modules ./node_modules
COPY --chown=node:node --from=builder /app .

# Runtime environment variables (overridden by ConfigMap/Secret in k8s)
ENV NODE_ENV=production \
    PORT=8000 \
    DATABASE_NAME="./dev.sqlite" \
    DATABASE_USER="user" \
    DATABASE_PASSWORD="password"

EXPOSE 8000

# Healthcheck – probes the users endpoint every 30s
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:8000/api/users || exit 1

CMD ["node", "index.js"]
