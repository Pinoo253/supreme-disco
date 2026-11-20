"""ADB Creative Team - Flask static server and health endpoint."""
import os
from flask import Flask, jsonify, send_from_directory
from dotenv import load_dotenv

load_dotenv()
ROOT = os.path.dirname(os.path.abspath(__file__))
app = Flask(__name__, static_folder=ROOT, static_url_path="")

@app.get("/")
def home():
    return send_from_directory(ROOT, "index.html")

@app.get("/health")
def health():
    return jsonify({"status": "ok", "service": "adb-creative-team", "supabase_configured": bool(os.getenv("SUPABASE_URL") and os.getenv("SUPABASE_ANON_KEY"))})

@app.get("/<path:path>")
def static_files(path):
    return send_from_directory(ROOT, path)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")), debug=os.getenv("FLASK_DEBUG") == "1")
