ngx.log(ngx.NOTICE, "hello from the header-filter phase")
ngx.header.content_type = "text/html"