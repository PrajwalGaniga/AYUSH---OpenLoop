import asyncio
from config.settings import settings
from motor.motor_asyncio import AsyncIOMotorClient

async def check():
    client = AsyncIOMotorClient(settings.mongodb_url)
    db = client[settings.mongodb_db_name]
    user = await db['users'].find_one({})
    if user:
        print("nadiHistory exists:", 'nadiHistory' in user)
        print(user.get('nadiHistory'))
    else:
        print("No user found")

asyncio.run(check())
