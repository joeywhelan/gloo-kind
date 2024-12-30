FROM node:lts-slim
COPY package*.json ./
RUN npm install
COPY ms2.js /app/ms2.js
EXPOSE 9000
CMD ["node", "/app/ms2.js"]