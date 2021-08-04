.PHONY: $(MAKECMDGOALS)

setup:

server:
	docker-compose up --build

# WARNING: this is a destructive operation as it will remove the persistent volume, which loses slugs
clean:
	docker-compose down --rmi local || true
	docker volume rm -f shurly_redis-data || true

# WARNING: this is a destructive operation as it will remove the persistent volume, which loses slugs
test:
	# Cleaning up...
	docker-compose down --rmi local || true
	docker volume rm -f shurly_redis-data || true
	# Starting containers...
	docker-compose up --build --detach
	# Waiting for app to start...
	sleep 10
	# Running endpoint tests
	curl -si -X GET http://127.0.0.1:8080/ | egrep -q '^HTTP.* 200 ' 
	curl -si -X GET http://127.0.0.1:8080/v1/url | egrep -q '^HTTP.* 200 ' 
	curl -si -X GET http://127.0.0.1:8080/KhtAJ | egrep -q '^HTTP.* 404 ' 
	curl -si -X GET http://127.0.0.1:8080/v1/url/KhtAJ | egrep -q '^HTTP.* 404 '
	curl -si -X PUT -H "content-type: application/json" http://127.0.0.1:8080/v1/url -d '{ "url": "http://example.com/" }' | egrep -q '^HTTP.* 200 '
	curl -si -X GET http://127.0.0.1:8080/KhtAJ | egrep -q '^HTTP.* 302 ' 
	curl -si -X GET http://127.0.0.1:8080/v1/url/KhtAJ | egrep -q '^HTTP.* 200 '
	# Cleaning up...
	docker-compose down --rmi local || true
	docker volume rm -f shurly_redis-data || true
