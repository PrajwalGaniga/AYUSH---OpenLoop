import asyncio
from config.settings import settings
from motor.motor_asyncio import AsyncIOMotorClient
from bson import json_util
import json

async def generate_report():
    client = AsyncIOMotorClient(settings.mongodb_url)
    db = client[settings.mongodb_db_name]
    
    user_id_str = "5cf7d3fa-d479-43c3-850e-75e6485bb870"
    
    collections = await db.list_collection_names()
    
    report = {}
    
    for coll_name in collections:
        coll = db[coll_name]
        
        # Check different common fields for user identification
        docs = []
        cursor1 = coll.find({"userId": user_id_str})
        async for doc in cursor1: docs.append(doc)
            
        cursor2 = coll.find({"user_id": user_id_str})
        async for doc in cursor2: docs.append(doc)
            
        cursor3 = coll.find({"author_id": user_id_str})
        async for doc in cursor3: docs.append(doc)
        
        if docs:
            # deduplicate by _id
            unique_docs = {str(d['_id']): d for d in docs}.values()
            report[coll_name] = list(unique_docs)
            
    with open('db_report_dump.json', 'w') as f:
        f.write(json.dumps(report, default=json_util.default, indent=2))
        
    print(f"Report generated with collections: {list(report.keys())}")

if __name__ == "__main__":
    asyncio.run(generate_report())
