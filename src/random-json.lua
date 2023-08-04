local cjson = require("cjson")
local random = require("resty.random")

--This function is not part of the module and therefore cannot be invoked from clients of the module.
-- It can be used within the module. It resembles a 'private' function
local function generate_random_number()
    local numbr = random.bytes(1)
    return string.byte(numbr) % 10 + 1
end

local _M = {}

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
return _M