--[[实现对server的操作，并写入配置文件，server对应上层的一条规则]]

ngx.req.read_body()
local data_json = ngx.req.get_body_data()
local server_name = ngx.var.src_name

-- request {"protocol": "http/https/tcp/udp"}
-- response {"protocol": "udp", "items": ["s1", "s2"]}
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

    -- 获取server列表
    local lines = utils.exec(string.format("ls %s 2>/dev/null|grep -e '%s.conf$'|xargs -I CC basename CC .%s.conf", dynamic_servers_dir, protocol, protocol))
    local items = utils.split(lines, "\n")

    -- 返回结果
    local result = {}
    result.protocol = protocol
    result.items = items

    ngx.status = HTTP_OK
    ngx.print(cjsonf.encode(result))
end

-- request {"name": "voa1i9kc_gr9e98de_8088.Rule", "domain": "myapp.sycki.com", "port": 8085, "path": "/", "protocol": "https", "toHTTPS": "false", "cert": "thiscert", "key": "thiskey", "options": {}, "upstream": "5000.grb5060d.vzrd9po6"}
-- response {"status": 205, "message": "success"}
local function UPDATE()
    local data_table = cjsonf.decode(data_json)

    -- 参数验证
    if data_table == nil then
        ngx.status = HTTP_NOT_ALLOWED
        ngx.print(string.format("Illegal parameter body: %s", data_json))
        return
    end

    -- upstream字段是一个不带后缀的域名，在这里需要根据环境变量中的值拼接为一个完整域名才能找到对应upstream
    data_table.upstream = data_table.upstream .. "." .. http_suffix_url .. "-upstream"

    -- 保存证书
    if data_table.protocol == "https" then
        dao.certs_save(data_table.name, data_table.cert, data_table.key)
        if not dao.certs_is_exists(data_table.name) then
            local msg = "failed save cert or key file for server "..server_name
            ngx.log(ngx.ERR, msg)

            ngx.status = 517
            ngx.print(msg)
            return
        end
    end

    -- 根据协议名称获取文件全名
    local filename = dao.get_server_file(data_table)

    -- 如果文件存在则备份
    local is_exists = utils.file_is_exists(filename)
    if is_exists then
        utils.file_backup(filename)
    end

    -- 更新持久层
    dao.server_save(data_table)

    -- 热加载配置
    local err = utils.shell(utils.cmd_restart_nginx, "0")

    local result = {}

    -- 处理结果
    if err ~= nil then
        -- 合并日志信息
        result.status = HTTP_NOT_ALLOWED
        result.message = err

        ngx.log(ngx.ERR, result.message)
        -- 如果配置文件错误则恢复到之前的状态
        if is_exists then
            utils.file_recover(filename)
        else
            dao.server_delete(data_table)
        end
    else
        result.status = HTTP_OK
        result.message = "success"

        -- 如果配置文件正常加载则清除备份文件
        utils.file_clean_bak(filename)
    end

    ngx.status = result.status
    ngx.print(cjsonf.encode(result))

end

-- 创建指定server
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

    local protocol = data_table.protocol

    data_table.name = server_name

    -- 删除证书
    if protocol == "https" then
        dao.certs_del(data_table.name)
    end

    -- 更新持久层
    dao.server_delete(data_table)

    -- 热加载配置
    utils.shell(utils.cmd_restart_nginx, "0")

    -- 处理结果
    local result = {}
    result.status = HTTP_OK
    result.message = "success"

    ngx.status = result.status
    ngx.print(cjsonf.encode(result))
end


-- 处理请求
local function main()
    local method = ngx.req.get_method()
    ngx.log(ngx.INFO, method, " /v1/servers/", server_name, " ", data_json)

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
