# lb-openresty
It is an openresty implementation of the [Rainbond](https://github.com/goodrain/rainbond) platform load balancer, and exists as a plug-in for the Rainbond Entrance.

But it is universal, any place that uses Nginx as load balancing may use it instead, you can dynamically modify its configuration through the Restful API.

Currently supported operations include: post, update, get and delete of upstreams, server and stream servers. This means that it supports both L7 and L4 load balancing.

## Documents
* [中文文档](https://github.com/goodrain/lb-openresty/blob/master/README-ZH.md)
* [English Doc](https://github.com/goodrain/lb-openresty/blob/master/README.md)

## Install
Clone it first to your local.

If you need to access this nginx by domain name, modify the `HTTP_SUFFIX_URL` environment variable in the Dockerfile.

### Build image and run container
```
./build.sh
```

### Check status
```
curl 127.0.0.1:9091/health
```

### Run unit test
```
test/unit-tester.sh
```

## Usage

### Create or update a upstream
```
json='{"name": "app1", "servers": [{"addr":"127.0.0.1:8088", "weight": 5}, {"addr":"127.0.0.1:8089", "weight": 5}]}'
curl 127.0.0.1:9091/v1/upstreams/app1 -X POST -d "$json"
```

### Create or update a server and Point to upstream above
```
json='{"name": "app1", "domain": "myapp.sycki.com", "port": 8085, "path": "/", "protocol": "http", "toHTTPS": "false", "cert": "this_cert_content...", "key": "this_key_content...", "options": {}, "upstream": "app1"}'
curl 127.0.0.1:9091/v1/servers/app1 -X POST -d "$json"
```

### Delete a server
```
curl 127.0.0.1:9091/v1/servers/app1 -X DELETE -d '{"protocol": "http"}'
```

### Delete a upstream
```
curl 127.0.0.1:9091/v1/upstreams/app1 -X DELETE
```

## Reference
* More usage View unit test file [unit test script](https://github.com/goodrain/lb-openresty/blob/master/test/unit-tester.sh)
* [OpenResty project](https://github.com/openresty)
