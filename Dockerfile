# Stage 1: Build stage
FROM node:16-alpine AS build

WORKDIR /apps

COPY . .

RUN npm install

# Stage 2: Run stage
FROM node:16-alpine AS run

WORKDIR /apps

COPY --from=build /apps .

# Copy the .env file
COPY .env .

RUN npm install --only=production

CMD ["npm", "run", "start"]
