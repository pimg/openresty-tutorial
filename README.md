# Openresty Tutorial
Some quick primers about Openresty and experimenting with Lua inside the Nginx.

Different lessons are available in branches. Some branches only have an `*-init` branch. These are branches to demonstrate certain aspects of Openresty. Other branches have both an `*-init` as well as a `*-solution` branch. Where the init branch can be used as the start of an excersise and the solution branch contains the solution.

Note, some init branches when run result in errors, this is delibirate to demonstrate certain pitfalls in Openresty.

## Lesson 1
the start is to simply observer the different Nginx phases.
Checkout the branch `lesson-1-init`
start the nginx server by executing:
```shell
nginx -p `pwd`/ -c conf/nginx.conf
```
Nginx is started as a foreground process with `stdout` as log. This makes it easier to restart and observe the logging.
When Nginx is started observe the logging, it should among other things contai:
```
...
nginx: [warn] [lua] init-phase.lua:1: hello from the init phase
...
2023/08/04 10:55:53 [notice] 3634383#3634383: *1 [lua] init-worker-phase.lua:1: hello from the init worker phase, context: init_worker_by_lua*
```
Now make a request to the endpoint and observe the logging again:
```shell
2023/08/04 10:57:28 [notice] 3634383#3634383: *2 [lua] set-phase.lua:1: hello from the set phase, client: 127.0.0.1, server: , request: "GET / HTTP/1.1", host: "localhost:8080"
2023/08/04 10:57:28 [notice] 3634383#3634383: *2 [lua] rewrite-phase.lua:1: hello from the rewrite phase, client: 127.0.0.1, server: , request: "GET / HTTP/1.1", host: "localhost:8080"
2023/08/04 10:57:28 [notice] 3634383#3634383: *2 [lua] access-phase.lua:1: hello from the access phase, client: 127.0.0.1, server: , request: "GET / HTTP/1.1", host: "localhost:8080"
2023/08/04 10:57:28 [notice] 3634383#3634383: *2 [lua] content-phase.lua:1: hello from the content phase, client: 127.0.0.1, server: , request: "GET / HTTP/1.1", host: "localhost:8080"
2023/08/04 10:57:28 [notice] 3634383#3634383: *2 [lua] header-filter-phase.lua:1: hello from the header-filter phase, client: 127.0.0.1, server: , request: "GET / HTTP/1.1", host: "localhost:8080"
2023/08/04 10:57:28 [notice] 3634383#3634383: *2 [lua] body-filter-phase.lua:1: hello from the body-filter phase, client: 127.0.0.1, server: , request: "GET / HTTP/1.1", host: "localhost:8080"
2023/08/04 10:57:28 [error] 3634383#3634383: *2 attempt to set ngx.header.HEADER after sending out response headers, client: 127.0.0.1, server: , request: "GET / HTTP/1.1", host: "localhost:8080"
2023/08/04 10:57:28 [notice] 3634383#3634383: *2 [lua] body-filter-phase.lua:1: hello from the body-filter phase, client: 127.0.0.1, server: , request: "GET / HTTP/1.1", host: "localhost:8080"
2023/08/04 10:57:28 [error] 3634383#3634383: *2 attempt to set ngx.header.HEADER after sending out response headers, client: 127.0.0.1, server: , request: "GET / HTTP/1.1", host: "localhost:8080"
2023/08/04 10:57:28 [notice] 3634383#3634383: *2 [lua] log-phase.lua:1: hello from the log phase while logging request, client: 127.0.0.1, server: , request: "GET / HTTP/1.1", host: "localhost:8080"
```
