FROM node:17-alpine

ENV PORT 3000

WORKDIR /usr/src/app/

COPY www/package.json .
RUN yarn

COPY www .

EXPOSE 3000

RUN yarn build

CMD [ "yarn", "start" ]