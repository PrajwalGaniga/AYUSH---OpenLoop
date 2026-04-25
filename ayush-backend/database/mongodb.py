from motor.motor_asyncio import AsyncIOMotorClient
from config.settings import settings

client: AsyncIOMotorClient = None


async def connect_db():
    global client
    client = AsyncIOMotorClient(settings.mongodb_url)
    # Verify connection
    await client.admin.command("ping")
    print(f"[MongoDB] Connected to {settings.mongodb_url} -> db: {settings.mongodb_db_name}")


async def close_db():
    global client
    if client:
        client.close()
        print("[MongoDB] Connection closed")


def get_db():
    return client[settings.mongodb_db_name]
