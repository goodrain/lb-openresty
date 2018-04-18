
function GET()
    local r = [[{"action": "/api", "items": ["/v1/upstreams", "/v1/servers"]}]]
    ngx.status = HTTP_OK
    ngx.print(r)
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