#!/bin/sh
docker-compose down
docker rm -f $(docker ps -aq )
sudo rm -r ./mongo/mongodb*
docker-compose up -d --build

echo "Create clickhouse claster"

echo "init clickhouse_node1"
cat clickhouse_node1_sql/create_shard.sql | docker-compose exec -T clickhouse-node1 clickhouse-client
cat clickhouse_node1_sql/create_replica.sql | docker-compose exec -T clickhouse-node1 clickhouse-client
cat clickhouse_node1_sql/create_shard_readings.sql | docker-compose exec -T clickhouse-node1 clickhouse-client
cat clickhouse_node1_sql/create_replica_readings.sql | docker-compose exec -T clickhouse-node1 clickhouse-client
cat clickhouse_node1_sql/create_default_readings.sql | docker-compose exec -T clickhouse-node1 clickhouse-client
cat clickhouse_node1_sql/show_databases.sql | docker-compose exec -T clickhouse-node1 clickhouse-client

echo "init clickhouse_node2"
cat clickhouse_node2_sql/create_shard.sql | docker-compose exec -T clickhouse-node2 clickhouse-client
cat clickhouse_node2_sql/create_replica.sql | docker-compose exec -T clickhouse-node2 clickhouse-client
cat clickhouse_node2_sql/create_shard_readings.sql | docker-compose exec -T clickhouse-node2 clickhouse-client
cat clickhouse_node2_sql/create_replica_readings.sql | docker-compose exec -T clickhouse-node2 clickhouse-client
cat clickhouse_node2_sql/create_default_readings.sql | docker-compose exec -T clickhouse-node2 clickhouse-client
cat clickhouse_node2_sql/show_databases.sql | docker-compose exec -T clickhouse-node2 clickhouse-client

change() {
  IS_MONGO_ALIVE=$(echo 'db.stats().ok' | docker-compose exec -T router01 mongosh --port 27017  2>&1 | tee -a check_connection.temp | grep "No such service" | wc -l)
}
change
echo $IS_MONGO_ALIVE

while [ $IS_MONGO_ALIVE -ge 1 ]
do
  echo "Waiting for mongo is ready"
  sleep 1
done

echo "Create mongo claster"

echo "Initialize the replica sets (config servers and shards)"
cat mongo/scripts/init-configserver.js | docker-compose exec -T configsvr01 mongosh
cat mongo/scripts/init-shard01.js | docker-compose exec -T shard01-a mongosh
cat mongo/scripts/init-shard02.js | docker-compose exec -T shard02-a mongosh
cat mongo/scripts/init-shard03.js | docker-compose exec -T shard03-a mongosh

echo "waiting when shards are initialized"
sleep 5
echo "Initializing the router"
cat mongo/scripts/init-router.js | docker-compose exec -T router01 mongosh

echo "Enable sharding and setup sharding-key"

echo 'sh.enableSharding("UserGeneratedContent")' |   docker-compose exec -T router01 mongosh --port 27017
echo 'db.adminCommand( { shardCollection: "UserGeneratedContent.UsersContent", key: { film_id: "hashed", email: 1, zipCode: 1, supplierId: 1 } } )' |   docker-compose exec -T router01 mongosh --port 27017




