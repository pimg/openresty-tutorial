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
## Lesson 2 picking the right phase and troubleshooting phase errors
The Nginx config in this lesson has the intent of changing the response from lesson 1 into an HTML response.
For this we change the output to be enclosed in <p> tags and modify the `Content-Type` header into `text/html`

To start is to simply checkout the branch `lesson-2-init`.

The init branch uses the `body-filter` phase to change the body and set `Content-Type` header.
start the nginx server by executing:
```shell
nginx -p `pwd`/ -c conf/nginx.conf
```
And execute a request.

Unfortunately this does not work!
They way to troubleshoot this error is to first observe the log. Here we can find the entry:
```shell
2023/08/04 11:08:13 [error] 3650923#3650923: *12 failed to run body_filter_by_lua*: ...l/workspace/openresty-tutorial/src/body-filter-phase.lua:2: API disabled in the context of body_filter_by_lua*
stack traceback:
        [C]: in function 'say'
        ...l/workspace/openresty-tutorial/src/body-filter-phase.lua:2: in main chunk, client: 127.0.0.1, server: , request: "GET / HTTP/1.1", host: "localhost:8080"
```

The crux of the message is: "API disabled in the context of body_filter_by_lua*" This means a Lua api is used in a phase where it is not available. The next line of the log gives us a clue about what api is the culprit. In this case it is "say".

While developing on Openresty these errors can occur frequently. Fortunately the documentation describes on what phases the api is available.
The documentation of the ngx.say api can be found here: https://github.com/openresty/lua-nginx-module#ngxsay
Indeed it appears the ngx.say api is not available in the `body-filter` phase.

Since we are  trying to modify the content of the response the `content` phase seems appropriate for this.

Move the `ngx.say` from the `body-filter` phase to the `content` phase and try again.

This is an improvement, the response comes back with status `200` and indeed we see our text.
`However, when we better observe the response, we still notice the Content-Type header is set to text/plain instead of text/html`

This is caused by the streaming event-loop based architeture of Nginx. In Nginx the headers are sent out before the body is sent out. Something that is also reflected in the order of the phases being executed. Where the `header-filter` phase is executed before the `body-filter` phase.

To solve this move the `ngx.header...` from the `body-filter` phase to the `header-filter` phase and try again.

*advanced* It might still be confusing on why the `body-filter` phase cannot change the response body. Some more information about the specifics of the body-filter phase and how it works can be found here: https://github.com/openresty/lua-nginx-module#body_filter_by_lua_block 