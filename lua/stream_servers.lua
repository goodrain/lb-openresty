--返回已存在server列表

local function GET()
    local str = utils.exec(string.format("ls %s|grep -e '.conf$'|awk -F '.' '{print $1}'", dynamic_stream_servers_dir))
    local arr = utils.split(str, "\n")
    local json = cjsonf.encode(arr)

    -- 返回结果
    ngx.print(json)
    ngx.log(ngx.INFO, json)
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