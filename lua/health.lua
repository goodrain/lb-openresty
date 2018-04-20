
function GET()
    ngx.status = HTTP_OK
    ngx.say("ok")
end

-- 处理请求
local function main()
    local method = ngx.req.get_method()

    if method == get then
        GET()
    else
        ngx.status = ngx.HTTP_NOT_FOUND
    end
end

main()