FROM node:21-slim as builder

WORKDIR /app

RUN npm install -g pnpm

COPY package.json-lock.yaml ./

RUN pnpm install --frozen-lockfile --prefer-offline

COPY . .

RUN pnpm run build

FROM node:21-slim as deploy

WORKDIR /app

ARG PORT=3000
ENV PORT $PORT
EXPOSE $PORT

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json-lock.yaml ./

RUN pnpm install --production --ignore-scripts --prefer-offline && npm cache clean --force

RUN addgroup -g 1001 -S nodejs && adduser -S -u 1001 nodejs \
    && rm -rf /usr/local/bin/.npm /usr/local/bin/.node-gyp

RUN pnpm add -g pm2

CMD ["pm2-runtime", "start", "dist/app.js"]