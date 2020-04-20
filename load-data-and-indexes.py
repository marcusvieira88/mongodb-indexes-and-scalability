import datetime
import pymongo
from pymongo import MongoClient

client = MongoClient('mongodb://localhost:27017/test')
db = client['test']
collection_test = db['test-collection']
collection_test.create_index([('field_a', pymongo.ASCENDING), ('field_b', pymongo.ASCENDING), ('field_c', pymongo.ASCENDING)], unique=True)

index = 0
while index < 1_000_000:
    item = {"field_a": index,
            "field_b": "Field B description",
            "field_c": 100,
            "field_d": "Test"+str(index),
            "field_e": ["A", "B", "C"],
            "date": datetime.datetime(2020, 4, 19, 6, 0, 0)}
    index += 1
    collection_test.insert_one(item)
    print('Inserted item='+ str(index))
    