--[[实现对server的操作，并写入配置文件，server对应上层的一条规则]]

local server_name = ngx.var.stream_server_name

local function GET()
    -- 反序列化配置文件
    local tab = dao.stream_server_read(server_name)
    local json = cjsonf.encode(tab)

    -- 返回结果
    ngx.print(json)
    ngx.log(ngx.INFO, json)
end

-- 创建指定server
local function UPDATE()
    -- 获取请求体，数据格式如下：
    -- {"name": "3360.service.ns.kube.local.", "port": 3360, "options": {"root": "html"}, "upstream": "app1"}
    ngx.req.read_body()
    local data_str = ngx.req.get_body_data()

    -- 转为map形式
    local data_table = cjsonf.decode(data_str)
    data_table.name = server_name

    -- 更新持久层
    dao.stream_server_save(data_table)

    -- 热加载配置
    local err = utils.shell(utils.cmd_restart_nginx, "0")

    -- 处理结果
    if err ~= nil then
        -- 回退
        ngx.print(err)
        ngx.log(ngx.ERR, "rollback for: "..err)
        dao.http_server_delete(server_name)
    else
        ngx.print("success")
    end

end

-- 更新指定server
local function POST()
    -- 获取请求体，数据格式如下：
    -- {"name": "3360.service.ns.kube.local.", "port": 3360, "options": {"root": "html"}, "upstream": "app1"}
    ngx.req.read_body()
    local data_str = ngx.req.get_body_data()

    -- 转为map形式
    local data_table = cjsonf.decode(data_str)
    data_table.name = server_name

    -- 本次提交的server是否已经存在
    local server_file = dao.get_stream_server_file(server_name)
    local r = utils.exec(string.format("ls %s | wc -l ", server_file))
    if r ~= "0" then
        local msg = "config file already exists of stream server: "..server_file
        ngx.log(ngx.ERR, msg)

        ngx.status = 519
        ngx.print(msg)
        return
    end

    UPDATE()
end

local function DELETE()
    -- 更新持久层
    dao.stream_server_delete(server_name)

    -- 热加载配置
    utils.shell(utils.cmd_restart_nginx, "0")

    ngx.print("success")
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