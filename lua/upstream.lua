--[[实现对upstream的操作，并写入配置文件，upstream与上层应用对应]]

ngx.req.read_body()
local data_json = ngx.req.get_body_data()
local upstream_name = ngx.var.src_name .. "." .. http_suffix_url


-- request {"protocol": "http/https/tcp/udp"}
-- response {"protocol": "none", "items": ["up1", "up2"]}
local function GET()
    local data_table = cjsonf.decode(data_json)

    -- 参数验证
    if data_table == nil or
            data_table.protocol == nil or
            string.len(data_table.protocol) < 3 or
            string.len(data_table.protocol) > 5 or
            string.match(data_table.protocol, "%a+") == nil then
        ngx.log(ngx.ERR, string.format("Illegal parameter protocol: %s", data_json))
        ngx.status = HTTP_NOT_ALLOWED
        ngx.print(string.format("Illegal parameter protocol: %s", data_json))
        return
    end

    local protocol = data_table.protocol

    local lines = utils.exec(string.format("ls %s 2>/dev/null|grep -e '%s.conf$'|xargs -I CC basename CC .%s.%s.conf", dynamic_upstreams_dir, protocol, http_suffix_url, protocol))
    local items = utils.split(lines, "\n")

    local result = {}
    result.protocol = data_table.protocol
    result.items = items

    ngx.status = HTTP_OK
    ngx.print(cjsonf.encode(result))

end

-- request {"name": "5000.grb5060d.vzrd9po6", "servers": [{"addr":"127.0.0.1:8088", "weight": 5}, {"addr":"127.0.0.1:8089", "weight": 5}], "protocol": "tcp"}
-- response {"status": 205, "message": "success"}
local function UPDATE()
    local data_table = cjsonf.decode(data_json)

    -- 参数验证
    if data_table == nil then
        ngx.log(ngx.ERR, string.format("Illegal parameter body: %s", data_json))
        ngx.status = HTTP_NOT_ALLOWED
        ngx.print(string.format("Illegal parameter body: %s", data_json))
        return
    end

    data_table.name = upstream_name

    -- 将server列表拼接为单行形式："server 127.0.0.1:8089;server 127.0.0.1:8088;"
    local servers_line = ""
    for _, item in pairs(data_table.servers) do
        servers_line =  string.format("%sserver %s weight=%s max_fails=3 fail_timeout=6s;", servers_line, item.addr, item.weight)
    end

    -- 通过dyups插件更新内存中的upstream
    local status, r = dyups.update(upstream_name, servers_line);

    local result = {}
    result.status = status

    -- 根据协议名称获取文件全名
    local filename = dao.get_upstream_file(data_table)

    -- 如果文件存在则备份
    local is_exists = utils.file_is_exists(filename)
    if is_exists then
        utils.file_backup(filename)
    end

    -- 更新持久层
    local err = dao.upstream_save(data_table)

    if data_table.protocol == "tcp" then
        -- 热加载配置
        local err1 = utils.shell(utils.cmd_restart_nginx, "0")

        -- 合并日志信息
        if err1 ~= nil then
            err = string.format("%s; %s", err, err1)
        end

    end

    -- 合并日志信息
    if err ~= nil then
        result.message = string.format("%s; %s", r, err)
    end

    -- 处理结果
    result.message = r
    if result.status == ngx.HTTP_OK and err == nil then
        result.status = HTTP_OK
        -- 如果配置文件正常加载则清除备份文件
        utils.file_clean_bak(filename)
    else
        ngx.log(ngx.ERR, result.message)
        -- 如果配置文件错误则恢复到之前的状态
        if is_exists then
            utils.file_recover(filename)
        else
            dao.upstream_delete(data_table)
        end
    end

    -- 返回结果
    ngx.status = result.status
    ngx.print(cjsonf.encode(result))

end

local function POST()
    UPDATE()
end

-- request {"protocol": "http/https/tcp/udp"}
-- response {"status": 205, "message": "success"}
local function DELETE()
    local data_table = cjsonf.decode(data_json)

    if data_table == nil or
            data_table.protocol == nil or
            string.len(data_table.protocol) < 3 or
            string.len(data_table.protocol) > 5 or
            string.match(data_table.protocol, "%a+") == nil then
        ngx.log(ngx.ERR, string.format("Illegal parameter protocol: %s", data_json))
        ngx.status = HTTP_NOT_ALLOWED
        ngx.print(string.format("Illegal parameter protocol: %s", data_json))
        return
    end

    data_table.name = upstream_name

    local status, r = dyups.delete(upstream_name)

    -- 处理结果
    local result = {}
    result.message = r
    if status == ngx.HTTP_OK or status == 404 then
        result.status = HTTP_OK
    else
        ngx.log(ngx.ERR, result.message)
        result.status = status
    end

    -- 返回结果
    ngx.status = result.status
    ngx.print(cjsonf.encode(result))

    -- 更新持久层
    dao.upstream_delete(data_table)
end



-- 处理请求
local function main()
    local method = ngx.req.get_method()
    ngx.log(ngx.INFO, method, " /v1/upstreams/", upstream_name, " ", data_json)

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