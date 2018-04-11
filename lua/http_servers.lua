--返回已存在server列表

local function GET()
    local str = utils.exec(string.format("ls %s|grep -e '.conf$'|awk -F '.' '{print $1}'", dynamic_http_servers_dir))
    local arr = utils.split(str, "\n")
    local json = cjsonf.encode(arr)

    ngx.log(ngx.INFO, json)
    ngx.print(json)
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