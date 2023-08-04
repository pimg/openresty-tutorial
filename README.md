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

For this lesson we created a separate lua file for each Nginx phase. But this is certainly not required and in practice quite uncommon.
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

## Lesson 3 Openresty module
Although not restricted, there are certain conventions and practices when it comes to developing on Openresty. One of the main conventions is to package functionality as a module. In this lesson we are going to create a json response as a Openresty module. In order to encode our response in json we are also going to use a 3rd party library. Furtunatey this library is already installed but we do need to import it.

All our code is going to be executed in the `content phase`. Although not required this does keep it clean for this example.

Just like a lot of real world modules, our module is going to reside in it's own file: `src/random-json.lua`

To start with this lesson checkout the branch `lesson-3-init`, the solution for this lesson can be found on the branch `lesson-3-solution`.

The exact functionality we are going to create is:
generate a random number between 0 and 10
if the number is one, the response should be: 
```json
{
    "number": 4,
    "isEven": true 
}
```

In the `src/random-json.lua` file on the `lesson-3-init` branch we can find our scaffold for our module, let's walk through the code:
The lines `local cjson = require("cjson")` and `local random = require("resty.random")` import the two external libraries we will need for this module. 

`Note:` normally only external libraries with the name `*-resty` must be used. This is a convention the library is built specifically fo use within Nginx/Openresty. `cjson` is an exception and can be used safely.

The module itself is a Lua table which by convention has the name `_M` and is currently empty. The file returns the module. This means it can be included using `require("random-json")` in Lua files that want to use this module.

In our case the module is used in the `src/content-phase.lua` file:
`local random-json = require("random-json")`

Currently the module is completely empty. And is not even executed since is is only included but not invoked.
Let's quickly fix this.

In the `src/random-json.lua` file add a function `generate_content` to our module and for now just add a log statement: `ngx.log(ngx.NOTICE, "hello from the random-json module")`

Now we need to invoke this function in our `src/content-phase.lua` file:
`random_json.generate_content()`

When the Nginx server is started and a request is made this log should contain:
```shell
2023/08/04 13:28:18 [notice] 4071017#4071017: *3 [lua] random-json.lua:7: generate_content(): hello from the random-json module, client: 127.0.0.1, server: , request: "GET / HTTP/1.1", host: "localhost:8080"
```
Now we have a solid foundation of building our desired endpoint.

The next step is to add a `private` function. This function is not part of the API of the module and therefore cannot be invoked by users of the module. It can however be invoked within the module. Which is exactly what we are going to do.

add the following code to the `src/random-json.lua` file above the `local _M = {}` line.
```lua
local function generate_random_number()
    local numbr = random.bytes(1)
    return string.byte(numbr) % 10 + 1
end
```

Inside our `generate_content` function we are going to invoke the `generate_randum_number` function and determine of the out put is `odd` or `even`.
Add the following code inside the `generate_content` function. Where our response object is a Lua table. Which we encode in the end to JSON using the cjson library we imported earlier.
```lua
function _M.generate_content()
    ngx.log(ngx.NOTICE, "hello from the random-json module")
    
    local response = {}

    local numbr = generate_random_number()
    response.number = numbr
    
    if numbr %2 == 0 then
        response.isEven = true
    else
        response.isEven = false
    end

    ngx.header.content_type = "application/json"
    ngx.say(cjson.encode(response))
end
```

The module is now ready, start the Nginx server if not already running and invoke the endpoint.