FROM node:18-alpine AS build

WORKDIR /usr/src/app

COPY ./package*.json ./

RUN --mount=type=cache,target=/usr/src/app/.npm \
    npm set cache /usr/src/app/.npm && \
    npm ci

COPY . .

CMD ["npm", "run", "dev"]