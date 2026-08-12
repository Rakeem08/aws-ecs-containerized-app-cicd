FROM node:16

WORKDIR /app

ARG REACT_APP_API_URL=http://localhost:8080/
ENV REACT_APP_API_URL=$REACT_APP_API_URL

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build

RUN npm install -g serve

EXPOSE 3000

CMD ["serve", "-s", "build", "-l", "3000"]