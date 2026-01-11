FROM node:18-alpine

WORKDIR /app

# Install dependencies first (caching layer)
COPY package.json .
RUN npm install

# Copy source code
COPY . .

# React's default port
EXPOSE 3000

# Start the development server
CMD ["npm", "start"]