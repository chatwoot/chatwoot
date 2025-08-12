#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

echo "--- Starting Local Test Setup Script ---"
echo "This script will prepare the environment and run the end-to-end test."
echo "Please ensure you are running this from the root of the 'conversate-ai' repository."
echo ""

# --- 1. Rename service directories (if they haven't been already) ---
echo "--> Step 1 of 3: Checking and renaming service directories..."
if [ -d "services/csg-service" ]; then
    mv services/csg-service services/csg_service
    echo "    - Renamed csg-service -> csg_service"
fi
if [ -d "services/lor-service" ]; then
    mv services/lor-service services/lor_service
    echo "    - Renamed lor-service -> lor_service"
fi
if [ -d "services/sor-service" ]; then
    mv services/sor-service services/sor_service
    echo "    - Renamed sor-service -> sor_service"
fi
echo "    Directory structure is now Python-compatible."

# --- 2. Install Dependencies ---
echo ""
echo "--> Step 2 of 3: Installing Python dependencies via pip..."
echo "    This may take several minutes, as it will download large AI/ML packages."
pip install fastapi "uvicorn[standard]" pydantic neo4j kafka-python sqlalchemy psycopg2-binary pgvector sentence-transformers httpx openai
echo "    Dependency installation complete."


# --- 3. Run the E2E Test ---
echo ""
echo "--> Step 3 of 3: Running the end-to-end pipeline test..."
python tests/test_e2e_pipeline.py

echo ""
echo "--- Test Script Finished ---"
echo "✅ If you see this message without any errors above, the test passed successfully!"
