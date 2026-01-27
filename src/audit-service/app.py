from flask import Flask, request, jsonify, Response
import psycopg2
import psycopg2.extras
import os
from datetime import datetime, timezone
import logging
import json
import sys
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST

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

AUDIT_LOGS = Counter('audit_logs_processed_total', 'Total audit logs processed', ['action'])

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

@app.route('/', methods=['GET'])
def root():
    return jsonify({
        'service': 'Audit Service',
        'version': '1.0.0',
        'endpoints': {
            'log': 'POST /audit/log',
            'list': 'GET /audit/logs',
            'health': 'GET /health',
            'metrics': 'GET /metrics'
        }
    })

@app.route('/metrics')
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

@app.route('/audit/log', methods=['POST'])
def log_event():
    try:
        data = request.get_json()
        
        if not data or 'action' not in data:
            return jsonify({'error': 'Action is required'}), 400
        
        action = data.get('action')
        details = data.get('details', {})
        timestamp = data.get('timestamp', datetime.now(timezone.utc).isoformat())
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        cur.execute(
            'INSERT INTO audit_logs (action, details, timestamp) VALUES (%s, %s, %s)',
            (action, json.dumps(details), timestamp)
        )
        
        conn.commit()
        cur.close()
        conn.close()
        
        AUDIT_LOGS.labels(action=action).inc()
        
        logger.info(f"Logged audit event: {action}")
        
        return jsonify({
            'status': 'logged',
            'action': action,
            'timestamp': timestamp
        }), 201
        
    except Exception as e:
        logger.error(f"Error logging audit event: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/audit/logs', methods=['GET'])
def list_logs():
    try:
        limit = request.args.get('limit', 100, type=int)
        action = request.args.get('action', None)
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        
        if action:
            cur.execute(
                'SELECT * FROM audit_logs WHERE action = %s ORDER BY created_at DESC LIMIT %s',
                (action, limit)
            )
        else:
            cur.execute(
                'SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT %s',
                (limit,)
            )
        
        logs = cur.fetchall()
        
        cur.close()
        conn.close()
        
        for log in logs:
            log['created_at'] = log['created_at'].isoformat()
            if isinstance(log['details'], str):
                try:
                    log['details'] = json.loads(log['details'])
                except:
                    pass
        
        logger.info(f"Retrieved {len(logs)} audit logs")
        
        return jsonify(logs)
        
    except Exception as e:
        logger.error(f"Error retrieving audit logs: {e}")
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
            'service': 'audit-service',
            'database': 'connected'
        }), 200
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({
            'status': 'unhealthy',
            'service': 'audit-service',
            'database': 'disconnected',
            'error': str(e)
        }), 503

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8081)
