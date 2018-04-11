--[[实现对upstream的操作，并写入配置文件，upstream与上层应用对应]]

local upstream_name = ngx.var.upstream_name

local function GET()
    -- check exists of the upstream config file
    local exists = utils.exec(string.format("ls %s|wc -l", dao.get_stream_upstream_file(upstream_name)))

    if exists ~= "1" then
        ngx.status = 517
        ngx.print("does not exist the upstream: "..upstream_name)
        ngx.log(ngx.ERR, "does not exist the upstream: "..upstream_name)
        return
    end

    -- get upstream already exists list by dyups api
    local result = dao.stream_upstream_read(upstream_name)
    local json = cjsonf.encode(result)

    -- 处理结果
    ngx.log(ngx.INFO, json)
    ngx.print(json)
end

-- 创建或更新指定upstream
local function POST()
    -- 获取请求体，数据格式：{"name": "80.service.ns.kube.local.", "servers": ["127.0.0.1:8088", "127.0.0.1:8089"]}
    ngx.req.read_body()
    local data_str = ngx.req.get_body_data()

    -- 转为map形式
    local data_table = cjsonf.decode(data_str)
    data_table.name = upstream_name

    -- 将server列表拼接为单行形式："server 127.0.0.1:8089;server 127.0.0.1:8088;"
    local servers_line = ""
    for _, item in pairs(data_table.servers) do
        servers_line = servers_line .. "server " .. item .. ";"
    end

    -- 创建或更新指定upstream
    local status, r = dyups.update(upstream_name, servers_line);

    -- 返回结果
    if status == ngx.HTTP_OK then
        ngx.log(ngx.INFO, r)
        ngx.print(r)
    else
        ngx.log(ngx.ERR, r)
        ngx.status = status
    end

    -- 更新持久层
    dao.stream_upstream_save(data_table)
end

local function UPDATE()
    POST()
end

local function DELETE()
    -- 创建或更新指定upstream
    local status, r = dyups.delete(upstream_name)

    -- 返回结果
    if status == ngx.HTTP_OK then
        ngx.log(ngx.INFO, r)
        ngx.print(r)
    else
        ngx.log(ngx.ERR, r)
        ngx.status = status
    end

    -- 更新持久层
    dao.stream_upstream_delete(upstream_name)
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