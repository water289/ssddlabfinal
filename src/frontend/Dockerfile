FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
ARG VITE_API_URL=http://backend:8000
ENV VITE_API_URL=${VITE_API_URL}
RUN npm ci --silent || npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
