.PHONY: $(MAKECMDGOALS)

setup:

server:
	docker-compose up

# WARNING: this is a destructive operation as it will remove the persistant volume, which loses slugs
clean:
	docker-compose down || true
	docker volume rm -f shurly_redis-data || true

# WARNING: this is a destructive operation as it will remove the persistant volume, which loses slugs
test:
	echo Cleaning up...
	docker-compose down || true
	docker volume rm -f shurly_redis-data || true
	echo Starting containers...
	docker-compose up -d
	echo -n "Waiting for app to start..." && sleep 10
	echo
	echo Running endpoint tests
	curl -si -X GET http://127.0.0.1:8080/ | egrep -q '^HTTP.* 200 ' 
	curl -si -X GET http://127.0.0.1:8080/v1/url | egrep -q '^HTTP.* 200 ' 
	curl -si -X GET http://127.0.0.1:8080/KhtAJ | egrep -q '^HTTP.* 404 ' 
	curl -si -X GET http://127.0.0.1:8080/v1/url/KhtAJ | egrep -q '^HTTP.* 404 '
	curl -si -X PUT -H "content-type: application/json" http://127.0.0.1:8080/v1/url -d '{ "url": "http://example.com/" }' | egrep -q '^HTTP.* 200 '
	curl -si -X GET http://127.0.0.1:8080/KhtAJ | egrep -q '^HTTP.* 302 ' 
	curl -si -X GET http://127.0.0.1:8080/v1/url/KhtAJ | egrep -q '^HTTP.* 200 '
	echo Cleaning up...
	docker-compose down || true
	docker volume rm -f shurly_redis-data || true
