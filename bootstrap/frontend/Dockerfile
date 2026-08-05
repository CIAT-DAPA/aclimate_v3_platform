# syntax=docker/dockerfile:1
#
# ACLIMATE v3 — Frontend auto-cloning Dockerfile
# ============================================================================
# Clones aclimate_v3_frontend from GitHub automatically and builds it.
# Users do NOT need to clone the repo locally.
#
# Build-time ARGs (NEXT_PUBLIC_*) → injected into the Next.js bundle
# Runtime ENVs (KEYCLOAK_CLIENT_SECRET, PORT) → passed to the container
# ============================================================================

# ──────────────────────────────────────────────
# STAGE 0: clone from GitHub
# ──────────────────────────────────────────────
FROM alpine/git:latest AS clone
WORKDIR /repo
RUN git clone --depth 1 https://github.com/CIAT-DAPA/aclimate_v3_frontend.git .

# ──────────────────────────────────────────────
# STAGE 1: dependencies (full for build)
# ──────────────────────────────────────────────
FROM node:20-alpine AS deps
WORKDIR /app/src
COPY --from=clone /repo/src/package*.json ./
RUN npm ci && \
    npm cache clean --force

# ──────────────────────────────────────────────
# STAGE 2: build
# ──────────────────────────────────────────────
FROM node:20-alpine AS builder
WORKDIR /app/src

# Next.js build-time variables (NEXT_PUBLIC_*)
ARG NEXT_PUBLIC_ACLIMATE_API_URL
ARG NEXT_PUBLIC_ACLIMATE_API_FRONTEND_URL
ARG NEXT_PUBLIC_KEYCLOAK_URL
ARG NEXT_PUBLIC_KEYCLOAK_REALM
ARG NEXT_PUBLIC_KEYCLOAK_CLIENT_ID
ARG NEXT_PUBLIC_COUNTRY_NAME
ARG NEXT_PUBLIC_ACLIMATE_APP_ID
ARG NEXT_PUBLIC_GEOSERVER_URL
ARG NEXT_PUBLIC_SHOW_STATIONS_MODULE
ARG NEXT_PUBLIC_SHOW_USERS_MODULE
ARG NEXT_PUBLIC_FORECAST_API_URL
ARG NEXT_PUBLIC_AUTH_API_URL

# Expose as ENV so Next.js picks them up during the build
ENV NEXT_PUBLIC_ACLIMATE_API_URL=$NEXT_PUBLIC_ACLIMATE_API_URL \
    NEXT_PUBLIC_ACLIMATE_API_FRONTEND_URL=$NEXT_PUBLIC_ACLIMATE_API_FRONTEND_URL \
    NEXT_PUBLIC_KEYCLOAK_URL=$NEXT_PUBLIC_KEYCLOAK_URL \
    NEXT_PUBLIC_KEYCLOAK_REALM=$NEXT_PUBLIC_KEYCLOAK_REALM \
    NEXT_PUBLIC_KEYCLOAK_CLIENT_ID=$NEXT_PUBLIC_KEYCLOAK_CLIENT_ID \
    NEXT_PUBLIC_COUNTRY_NAME=$NEXT_PUBLIC_COUNTRY_NAME \
    NEXT_PUBLIC_ACLIMATE_APP_ID=$NEXT_PUBLIC_ACLIMATE_APP_ID \
    NEXT_PUBLIC_GEOSERVER_URL=$NEXT_PUBLIC_GEOSERVER_URL \
    NEXT_PUBLIC_SHOW_STATIONS_MODULE=$NEXT_PUBLIC_SHOW_STATIONS_MODULE \
    NEXT_PUBLIC_SHOW_USERS_MODULE=$NEXT_PUBLIC_SHOW_USERS_MODULE \
    NEXT_PUBLIC_FORECAST_API_URL=$NEXT_PUBLIC_FORECAST_API_URL \
    NEXT_PUBLIC_AUTH_API_URL=$NEXT_PUBLIC_AUTH_API_URL

# Copy dependencies and source code (from the cloned repo)
COPY --from=deps /app/src/node_modules ./node_modules
COPY --from=clone /repo/src/ ./

# Build Next.js
RUN npm run build

# ──────────────────────────────────────────────
# STAGE 3: runner (final image)
# ──────────────────────────────────────────────
FROM node:20-alpine AS runner
ENV NODE_ENV=production \
    PORT=3000 \
    HOSTNAME=0.0.0.0

WORKDIR /app/src

# dumb-init for proper signal handling (SIGTERM → graceful shutdown)
RUN apk add --no-cache dumb-init && \
    addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Copy build artifacts (without node_modules/ to avoid devDependencies)
COPY --from=builder --chown=nextjs:nodejs /app/src/.next ./.next
COPY --from=builder --chown=nextjs:nodejs /app/src/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/src/package.json ./package.json
COPY --from=builder --chown=nextjs:nodejs /app/src/package-lock.json ./package-lock.json
COPY --from=builder --chown=nextjs:nodejs /app/src/next.config.mjs ./next.config.mjs

# Install only production dependencies (no TypeScript, eslint, etc.)
RUN npm ci --omit=dev && \
    npm cache clean --force

# Runtime: KEYCLOAK_CLIENT_SECRET is passed via docker run -e (NOT build-time)
# No ENV for KEYCLOAK_CLIENT_SECRET here — it is provided externally

USER nextjs
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=5 \
  CMD node -e "fetch('http://127.0.0.1:' + (process.env.PORT || '3000') + '/api/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

ENTRYPOINT ["dumb-init", "--"]
CMD ["npm", "run", "start"]