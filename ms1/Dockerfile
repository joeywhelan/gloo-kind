FROM node:lts-slim
COPY package*.json ./
RUN npm install
COPY ms1.js /app/ms1.js
EXPOSE 8000
CMD ["node", "/app/ms1.js"]