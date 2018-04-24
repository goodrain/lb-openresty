# lb-openresty
它是[云帮平台](https://github.com/goodrain/rainbond)负载均衡器的openresty实现，作为云帮Entrance项目插件的形式而存在。

但它是通用的，任何用Nginx作为负载均衡的地方都可能用它来代替，你可以很方便地通过Restful API来动态修改它的配置。

目前支持的操作有：upstream的增删改查、server的增删改醒、stream类型server的增删改查，也就是说它同时支持L7和L4的负载均衡。

## 文档
* [中文文档](https://github.com/goodrain/lb-openresty/blob/master/README-ZH.md)
* [English Doc](https://github.com/goodrain/lb-openresty/blob/master/README.md)

## 安装
首先克隆它到你的本地，然后进入项目目录。

### 编译
如果你打算通过你的域名来访问它，那么你可能需要修改容器中的环境变量`HTTP_SUFFIX_URL`，它被定义在Dockerfile文件中。

```
./build.sh
```

### 运行
```
./run.sh
```

### 检查它是否已经运行
```
curl 127.0.0.1:10002/health
```

### 运行测试脚本
```
test/unit-tester.sh
```

## 使用

### 创建或更新一个upstream
```
json='{"name": "app1", "servers": [{"addr":"127.0.0.1:8088", "weight": 5}, {"addr":"127.0.0.1:8089", "weight": 5}]}'
curl 127.0.0.1:10002/v1/upstreams/app1 -X POST -d "$json"
```

### 创建或更新一个server并指向上面的upstream
```
json='{"name": "app1", "domain": "myapp.sycki.com", "port": 8085, "path": "/", "protocol": "http", "toHTTPS": "false", "cert": "this_cert_content...", "key": "this_key_content...", "options": {}, "upstream": "app1"}'
curl 127.0.0.1:10002/v1/servers/app1 -X POST -d "$json"
```

### 删除一个server
```
curl 127.0.0.1:10002/v1/servers/app1 -X DELETE -d '{"protocol": "http"}'
```

### 删除一个upstream
```
curl 127.0.0.1:10002/v1/upstreams/app1 -X DELETE
```

## 参考
* 更多Restful API用法请参考测[单元测试脚本](https://github.com/goodrain/lb-openresty/blob/master/test/unit-tester.sh)
* [OpenResty项目](https://github.com/openresty)
