# openrestry-plugin
This rainbond-entrance plugin for openresty.

## build and run
Clone it first to your local.

If you need to access this nginx by domain name, modify the `HTTP_SUFFIX_URL` environment variable in the Dockerfile.

Build image and run container.
`./build.sh`

Check status.
`curl 127.0.0.1:9091/health`

## Run unit test
`./test/unit-tester.sh`

## Restful API

Create or update a upstream.
```
json='{"name": "app1", "servers": [{"addr":"127.0.0.1:8088", "weight": 5}, {"addr":"127.0.0.1:8089", "weight": 5}]}'
curl 127.0.0.1:9091/v1/upstreams/app1 -X POST -d "$json"
```

Create or update a server.
```
json='{"name": "app1", "domain": "myapp.sycki.com", "port": 8085, "path": "/", "protocol": "http", "cert": "this_cert_content...", "key": "this_key_content...", "options": {}, "upstream": "app1"}'
curl 127.0.0.1:9091/v1/servers/app1 -X POST -d "$json"
```

Delete a server.
```
curl 127.0.0.1:9091/v1/servers/app1?protocol=http -X DELETE
```

Delete a upstream.
```
curl 127.0.0.1:9091/v1/upstreams/app1 -X DELETE
```

More usage View unit test file `test/unit-tester.sh`.
