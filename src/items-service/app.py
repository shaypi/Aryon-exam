from flask import Flask, request, jsonify, Response
import psycopg2
import psycopg2.extras
import os
from datetime import datetime, timezone
import uuid
import requests
import logging
import json
import sys
from prometheus_client import Counter, Summary, generate_latest, CONTENT_TYPE_LATEST

# Configure logging
class JsonFormatter(logging.Formatter):
    def format(self, record):
        log_record = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "message": record.getMessage(),
            "logger": record.name
        }
        if record.exc_info:
            log_record["exception"] = self.formatException(record.exc_info)
        return json.dumps(log_record)

handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(JsonFormatter())
logging.getLogger().addHandler(handler)
logging.getLogger().setLevel(logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

ITEMS_CREATED = Counter('items_created_total', 'Total items created')
ITEMS_RETRIEVED = Counter('items_retrieved_total', 'Total items retrieved')
REQUEST_LATENCY = Summary('request_latency_seconds', 'Request latency in seconds')
DB_QUERY_TIME = Summary('db_query_duration_seconds', 'Database query duration in seconds')

AUDIT_SERVICE_URL = os.environ.get('AUDIT_SERVICE_URL', 'http://audit-service:8081')

def get_db_connection():
    try:
        conn = psycopg2.connect(
            host=os.environ.get('DB_HOST', 'localhost'),
            port=os.environ.get('DB_PORT', '5432'),
            database=os.environ.get('DB_NAME', 'itemsdb'),
            user=os.environ.get('DB_USER', 'postgres'),
            password=os.environ.get('DB_PASSWORD', 'password')
        )
        return conn
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        raise

def log_audit(action, details):
    try:
        response = requests.post(
            f'{AUDIT_SERVICE_URL}/audit/log',
            json={
                'action': action,
                'details': details,
                'timestamp': datetime.now(timezone.utc).isoformat()
            },
            timeout=2
        )
        if response.status_code != 201:
            logger.warning(f"Audit logging returned status {response.status_code}")
    except requests.exceptions.Timeout:
        logger.warning(f"Audit logging timed out for action: {action}")
    except requests.exceptions.RequestException as e:
        logger.warning(f"Audit logging failed for action {action}: {e}")
    except Exception as e:
        logger.error(f"Unexpected error in audit logging: {e}")

@app.route('/', methods=['GET'])
def root():
    return jsonify({
        'service': 'Items Service',
        'version': '1.0.0',
        'endpoints': {
            'create': 'POST /items',
            'list': 'GET /items',
            'health': 'GET /health',
            'metrics': 'GET /metrics'
        }
    })

@app.route('/metrics')
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

@app.route('/items', methods=['POST'])
@REQUEST_LATENCY.time()
def create_item():
    try:
        data = request.get_json()
        
        if not data or 'name' not in data:
            return jsonify({'error': 'Name is required'}), 400
        
        item_id = str(uuid.uuid4())
        name = data.get('name')
        description = data.get('description', '')
        created_at = datetime.now(timezone.utc)
        
        with DB_QUERY_TIME.time():
            conn = get_db_connection()
            cur = conn.cursor()
            
            cur.execute(
                'INSERT INTO items (id, name, description, created_at) VALUES (%s, %s, %s, %s)',
                (item_id, name, description, created_at)
            )
            
            conn.commit()
            cur.close()
            conn.close()
        
        ITEMS_CREATED.inc()
        
        log_audit('CREATE_ITEM', {
            'item_id': item_id,
            'name': name
        })
        
        logger.info(f"Created item: {item_id}")
        
        return jsonify({
            'id': item_id,
            'name': name,
            'description': description,
            'created_at': created_at.isoformat()
        }), 201
        
    except Exception as e:
        logger.error(f"Error creating item: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/items', methods=['GET'])
@REQUEST_LATENCY.time()
def list_items():
    try:
        with DB_QUERY_TIME.time():
            conn = get_db_connection()
            cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
            
            cur.execute('SELECT * FROM items ORDER BY created_at DESC')
            items = cur.fetchall()
            
            cur.close()
            conn.close()
        
        ITEMS_RETRIEVED.inc(len(items))
        
        for item in items:
            item['id'] = str(item['id'])
            item['created_at'] = item['created_at'].isoformat()
        
        log_audit('LIST_ITEMS', {
            'count': len(items)
        })
        
        logger.info(f"Listed {len(items)} items")
        
        return jsonify(items)
        
    except Exception as e:
        logger.error(f"Error listing items: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/health', methods=['GET'])
def health():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT 1')
        cur.close()
        conn.close()
        
        return jsonify({
            'status': 'healthy',
            'service': 'items-service',
            'database': 'connected'
        }), 200
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({
            'status': 'unhealthy',
            'service': 'items-service',
            'database': 'disconnected',
            'error': str(e)
        }), 503

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
