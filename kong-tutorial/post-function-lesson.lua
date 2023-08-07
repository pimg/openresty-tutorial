local cjson = require("cjson")

local function process_body(body) 
    local decoded_body = cjson.decode(body)
    local custom_header = decoded_body.headers.HTTP_CUSTOM
    if custom_header ~= nil then
        kong.log.debug(">>>>> Custom header is not nil")
        if custom_header == "Foo" then
            kong.log.debug(">>>>> Custom Header contains Foo")
            decoded_body.headers.HTTP_CUSTOM = "Bar"
        end
    else
        kong.log.debug(">>>>> Custom Header does not contain Foo: ", custom_header)
        decoded_body.headers.HTTP_CUSTOM = "Baz"
    end
   return cjson.encode(decoded_body) 
end

local body = kong.response.get_raw_body()

if body ~= nil then
    kong.log.debug(">>>>> Response body found, starting tranformation....")
    local transformed_body = process_body(body)

    kong.response.set_raw_body(transformed_body)
end