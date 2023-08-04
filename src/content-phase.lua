local random_json = require("src/random-json")
ngx.log(ngx.NOTICE, "hello from the content phase")

random_json.generate_content()