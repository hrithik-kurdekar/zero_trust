import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock, AsyncMock
from main import app

client = TestClient(app)

# --- SCENARIO 1: Credentials File is Missing ---
# We mock 'main.get_creds' to return None, simulating a missing file.
@patch("main.get_creds")
def test_read_data_no_creds(mock_get_creds):
    mock_get_creds.return_value = None
    
    response = client.get("/data")
    
    assert response.status_code == 200
    assert response.json() == {"error": "Credentials not found yet"}

# --- SCENARIO 2: Success (Happy Path) ---
# We mock the Creds AND the Async Database Connection
@patch("main.get_creds")
@patch("main.AsyncIOMotorClient")
def test_read_data_success(mock_mongo_client, mock_get_creds):
    # 1. Mock the Credentials
    mock_get_creds.return_value = {"username": "test_user", "password": "test_pass"}
    
    # 2. Mock the Async Database Call
    # We have to build a chain of mocks: client -> db -> collection -> find_one
    mock_db_instance = MagicMock()
    mock_collection = MagicMock()
    
    # 'find_one' is an async function (await), so we use AsyncMock
    mock_collection.find_one = AsyncMock(return_value={"value": "Mocked Secret Data"})
    
    mock_db_instance.test_db.secrets = mock_collection
    mock_mongo_client.return_value = mock_db_instance

    # 3. Run the Request
    response = client.get("/data")
    
    # 4. Assertions
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["status"] == "Secure Connection Established"
    assert json_data["db_user"] == "test_user"
    assert json_data["secret_data"] == "Mocked Secret Data"

# --- SCENARIO 3: Database Connection Fails ---
@patch("main.get_creds")
@patch("main.AsyncIOMotorClient")
def test_db_failure(mock_mongo_client, mock_get_creds):
    # 1. Mock Creds
    mock_get_creds.return_value = {"username": "user", "password": "pass"}
    
    # 2. Mock DB to raise an exception
    mock_mongo_client.side_effect = Exception("Connection Timed Out")

    # 3. Run Request
    response = client.get("/data")
    
    # 4. Assertions (Our code catches the error and returns it as JSON)
    assert response.status_code == 200
    assert "Connection Timed Out" in response.json()["error"]