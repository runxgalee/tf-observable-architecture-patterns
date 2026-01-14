FROM node:20-slim

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production

# Copy application code
COPY index.js ./

# Run as non-root user
USER node

# Expose port (Cloud Run uses PORT env variable)
EXPOSE 8080

# Start the application
CMD ["node", "index.js"]
