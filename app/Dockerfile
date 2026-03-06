# -------- Stage 1: Build Stage --------
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production
COPY . .

# -------- Stage 2: Runtime Stage --------
FROM node:18-alpine
WORKDIR /app

# Create non-root user
RUN addgroup -S nodegroup && adduser -S nodeuser -G nodegroup
COPY --from=builder /app /app
USER nodeuser
EXPOSE 3000
CMD ["node", "app.js"]

