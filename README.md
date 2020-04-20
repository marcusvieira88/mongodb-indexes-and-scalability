# Introduction
Project used to study MongoDB indexes and scalability.

## MondoDB Indexes

### Default _id Index
MongoDB creates a unique index on the _id field during the creation of a collection. The _id index prevents clients from inserting two documents with the same value for the _id field. You cannot drop this index on the _id field.

### Index Names
The default name for an index is the concatenation of the indexed keys and each key’s direction in the index ( i.e. 1 or -1) using underscores as a separator. For example, an index created on { item : 1, quantity: -1 } has the name item_1_quantity_-1.

### Index Types

#### Single Field
```
db.products.createIndex({ quantity: -1 })
```

#### Compound Index
```
db.products.createIndex({ userid: 1, quantity: -1 })
```

#### Multikey Index
Phone field in this case is a array field:
```
db.products.createIndex({ phones: 1 })
```

#### Geospatial Index

To support efficient queries of geospatial coordinate data, MongoDB provides two special indexes: 2d indexes that uses planar geometry when returning results and 2dsphere indexes that use spherical geometry to return results.

See 2d Index Internals for a high level introduction to geospatial indexes.
```
db.places.createIndex( { "location": "2d" } )
```

#### Text Indexes

MongoDB provides a text index type that supports searching for string content in a collection. These text indexes do not store language-specific stop words (e.g. “the”, “a”, “or”) and stem the words in a collection to only store root words.

```
db.products.createIndex( { comments: "text" } )
```

#### Hashed Indexes

To support hash based sharding, MongoDB provides a hashed index type, which indexes the hash of the value of a field. These indexes have a more random distribution of values along their range, but only support equality matches and cannot support range-based queries.

### Indexes Properties 

#### Unique Indexes
The unique property for an index causes MongoDB to reject duplicate values for the indexed field. Other than the unique constraint, unique indexes are functionally interchangeable with other MongoDB indexes.

#### Partial Indexes

Partial indexes only index the documents in a collection that meet a specified filter expression. By indexing a subset of the documents in a collection, partial indexes have lower storage requirements and reduced performance costs for index creation and maintenance.
```
db.restaurants.createIndex(
   { cuisine: 1, name: 1 },
   { partialFilterExpression: { rating: { $gt: 5 } } }
)
```

#### Sparse Indexes
The sparse property of an index ensures that the index only contain entries for documents that have the indexed field. The index skips documents that do not have the indexed field.

You can combine the sparse index option with the unique index option to prevent inserting documents that have duplicate values for the indexed field(s) and skip indexing documents that lack the indexed field(s).

*** If you are using MongoDB 3.2 or later, partial indexes should be preferred over sparse indexes ***

#### TTL Indexes
TTL indexes are special indexes that MongoDB can use to automatically remove documents from a collection after a certain amount of time. This is ideal for certain types of information like machine generated event data, logs, and session information that only need to persist in a database for a finite amount of time.
```
db.log_events.createIndex( { "createdAt": 1 }, { expireAfterSeconds: 3600 } )
```

### MongoDB Scan Stages

- COLLSCAN for a collection scan
- IXSCAN for scanning index keys
- FETCH for retrieving documents
- SHARD_MERGE for merging results from shards
- SHARDING_FILTER for filtering out orphan documents from shards

## Scaling MongoDB

Vertical Scaling involves increasing the capacity of a single server, such as using a more powerful CPU, adding more RAM, or increasing the amount of storage space. Limitations in available technology may restrict a single machine from being sufficiently powerful for a given workload. Additionally, Cloud-based providers have hard ceilings based on available hardware configurations. As a result, there is a practical maximum for vertical scaling.

Horizontal Scaling involves dividing the system dataset and load over multiple servers, adding additional servers to increase capacity as required. While the overall speed or capacity of a single machine may not be high, each machine handles a subset of the overall workload, potentially providing better efficiency than a single high-speed high-capacity server. Expanding the capacity of the deployment only requires adding additional servers as needed, which can be a lower overall cost than high-end hardware for a single machine. The trade off is increased complexity in infrastructure and maintenance for the deployment.

MongoDB supports horizontal scaling through sharding.

### Replica Sets

A replica set in MongoDB is a group of mongod processes that maintain the same data set. Replica sets provide redundancy and high availability, and are the basis for all production deployments. 

![MongoDb ReplicaSet Architecture](mongodb-replica-set-architecture.svg)

Replica Set Election (High Availability):

![MongoDb ReplicaSet Election](mongodb-replica-set-election.svg)

MongoDB allows you configure read preference (Primary, Secondary or the replica with least network latency) 
```
db.collection.find({}).readPref( "secondary",  [ { "region": "South" } ] )
```
![MongoDb ReplicaSet Read Preference](mongodb-replica-set-read-preference.svg)

### Sharding

Sharding is a method for distributing data across multiple machines. MongoDB uses sharding to support deployments with very large data sets and high throughput operations.

![MongoDb Sharded Cluster Architecture](mongodb-sharding-architecture.svg)

Example how to Connect to a sharded cluster:
```
client = MongoClient('mongodb://host1,host2,host3')
```

- shard: Each shard contains a subset of the sharded data. Each shard can be deployed as a replica set.
- mongos: The mongos acts as a query router, providing an interface between client applications and the sharded cluster.
- config servers: Config servers store metadata and configuration settings for the cluster. As of MongoDB 3.4, config servers must be deployed as a replica set (CSRS).
- shard keys: MongoDB uses the shard key to distribute the collection’s documents across shards. The shard key consists of a field or fields that exist in every document in the target collection.
- chunk: A contiguous range of shard key values within a particular shard. Chunk ranges are inclusive of the lower boundary and exclusive of the upper boundary. MongoDB splits chunks when they grow beyond the configured chunk size, which by default is 64 megabytes. MongoDB migrates chunks when a shard contains too many chunks of a collection relative to other shards. See Data Partitioning with Chunks and Sharded Cluster Balancer.

![MongoDb Sharded Cluster Access](mongodb-sharding-data-access.svg)


## Run

Start MongoDB database:
```
docker-compose up
```

Run python code:
```
python load-data-and-indexes.py
```

## Test Indexes

After execute the script you will have a collection with 1 million items:

There is on compound index and unique index on collection-test:
- field_a (ASCENDING)
- field_b (ASCENDING)
- field_c (ASCENDING)

Below some queries and the explain of them:

It executes a IXSCAN scan:
```
{field_a: 99999}
```

It executes a COLLSCAN scan:
```
{field_b: 'Field B description'}
```

It executes a COLLSCAN scan:
```
{field_c: 100}
```

It executes a IXSCAN scan:
```
{field_a: 99999, field_b: 'Field B description'}
```

It executes a IXSCAN scan:
```
{field_a: 99999, field_c: 100}
```

It executes a COLLSCAN scan:
```
{field_b: 'Field B description', field_c: 100}
```

It executes a IXSCAN scan:
```
{field_a: 99999, field_b: 'Field B description', field_c: 100, date: ISODate('2020-04-19T06:00:00.000+00:00')}
```

It executes a COLLSCAN scan:
```
{field_b: 'Field B description', field_c: 100, date: ISODate('2020-04-19T06:00:00.000+00:00')}
```

It executes a COLLSCAN scan:
```
{date: ISODate('2020-04-19T13:12:27.577+00:00')}
```

## References 

* [MongoDB Indexes](https://docs.mongodb.com/manual/indexes/)
* [Partial and Sparse Indexes](https://www.percona.com/blog/2018/12/19/using-partial-and-sparse-indexes-in-mongodb/)
* [MongoDB Replication](https://docs.mongodb.com/manual/replication/)