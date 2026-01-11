import json
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient

# Setup Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("uvicorn")

app = FastAPI()

# 1. ALLOW ALL ORIGINS (Wildcard) for debugging
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow ANYONE to connect
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    logger.info(">>> BACKEND RELOADED: CORS IS NOW OPEN TO ALL <<<")

def get_creds():
    try:
        with open("/app/secrets/mongodb-creds.json", "r") as f:
            return json.load(f)
    except FileNotFoundError:
        return None

@app.get("/data")
async def get_data():
    logger.info(">>> REQUEST RECEIVED FROM FRONTEND <<<") # Debug print
    
    creds = get_creds()
    if not creds:
        logger.error("Credentials file missing!")
        return {"error": "Credentials not found yet"}

    # Connect to DB
    try:
        uri = f"mongodb://{creds['username']}:{creds['password']}@mongodb:27017"
        client = AsyncIOMotorClient(uri)
        db = client.test_db
        doc = await db.secrets.find_one({"name": "flag"})
        logger.info(">>> DB SUCCESS: Found Data <<<")
        return {
            "status": "Secure Connection Established",
            "db_user": creds['username'],
            "secret_data": doc["value"] if doc else "No data in DB yet",
        }
    except Exception as e:
        logger.error(f"DB CONNECTION FAILED: {str(e)}")
        return {"error": str(e)}