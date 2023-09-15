CREATE TABLE IF NOT EXISTS replica.user_film_timestamp (
    email String Codec(LZ4),
    film_id String Codec(LZ4),
    time DateTime Codec(DoubleDelta, LZ4),
    date ALIAS toDate(time),
    timestamp Int32 Codec(DoubleDelta, LZ4)
) Engine = ReplicatedMergeTree('/clickhouse/tables/shard1/user_film_timestamp', 'replica_2')
PARTITION BY toYYYYMM(time)
ORDER BY (email, time);