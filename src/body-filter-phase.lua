ngx.log(ngx.NOTICE, "hello from the body-filter phase")
ngx.say("<p>Congrats you've executed all the Nginx phases, please look at the log.</p>")
ngx.header.content_type = "text/html"