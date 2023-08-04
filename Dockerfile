FROM  openresty/openresty

EXPOSE 8080/tcp
RUN mkdir -p /myapp
WORKDIR /myapp

COPY . .

ENTRYPOINT [ "nginx" ]
CMD [ "-p", "/myapp/", "-c", "conf/nginx.conf" ]