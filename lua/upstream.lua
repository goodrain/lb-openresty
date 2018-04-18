--[[实现对upstream的操作，并写入配置文件，upstream与上层应用对应]]

local upstream_name = ngx.var.src_name

local function GET()
    local str = utils.exec(string.format("ls %s|grep -e '.conf$'|xargs -I CC basename CC .conf", dynamic_upstreams_dir))
    local arr = utils.split(str, "\n")
    local json = cjsonf.encode(arr)

    ngx.log(ngx.INFO, json)
    ngx.status = HTTP_OK
    ngx.print(json)

end

-- 创建或更新指定upstream
local function UPDATE()
    -- 获取请求体，数据格式：{"name": "80.service.ns.kube.local.", "servers": [{"addr":"127.0.0.1:8088", "weight": 5}, {"addr":"127.0.0.1:8089", "weight": 5}]}
    ngx.req.read_body()
    local data_str = ngx.req.get_body_data()
    ngx.log(ngx.INFO, "POST upstream ", ngx.req.get_body_data())

    -- 转为map形式
    local data_table = cjsonf.decode(data_str)
    data_table.name = upstream_name

    -- 将server列表拼接为单行形式："server 127.0.0.1:8089;server 127.0.0.1:8088;"
    local servers_line = ""
    for _, item in pairs(data_table.servers) do
        servers_line =  string.format("%sserver %s;", servers_line, item.addr)
    end

    -- 更新内存中的upstream
    local status, r = dyups.update(upstream_name, servers_line);

    -- 更新持久层
    local err = dao.upstream_save(data_table)

    -- 合并日志信息
    if err ~= nil then
        r = string.format("%s; %s", r, err)
    end

    -- 返回结果
    if status == ngx.HTTP_OK and err == nil then
        ngx.log(ngx.INFO, r)
        ngx.status = HTTP_OK
        ngx.print(r)
    else
        ngx.log(ngx.ERR, r)
        ngx.status = status
        ngx.print(r)
        -- 回退
        --dao.upstream_delete(upstream_name)
    end

end

local function POST()
    UPDATE()
end

local function DELETE()
    -- 创建或更新指定upstream
    local status, r = dyups.delete(upstream_name)

    -- 返回结果
    if status == ngx.HTTP_OK or status == 404 then
        ngx.log(ngx.INFO, r)
        ngx.status = HTTP_OK
        ngx.print(r)
    else
        ngx.log(ngx.ERR, r)
        ngx.status = status
    end

    -- 更新持久层
    dao.upstream_delete(upstream_name)
end



-- 处理请求
local function main()
    local method = ngx.req.get_method()

    if method == post then
        POST()
    elseif method == del then
        DELETE()
    elseif method == update then
        UPDATE()
    elseif method == get then
        GET()
    else
        ngx.status = ngx.HTTP_NOT_FOUND
    end
end

main()