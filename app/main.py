from flask import Flask, jsonify, request
import psycopg2
import os
import time
from prometheus_flask_exporter import PrometheusMetrics
import logging
import json
from pythonjsonlogger import jsonlogger

app = Flask(__name__)

# Setup JSON logging for centralized logging
logger = logging.getLogger()
logHandler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter()
logHandler.setFormatter(formatter)
logger.addHandler(logHandler)
logger.setLevel(logging.INFO)

# Prometheus metrics
metrics = PrometheusMetrics(app)


# Database connection
def get_db_connection():
    return psycopg2.connect(
        host=os.environ.get('DB_HOST', 'postgres'),
        database=os.environ.get('DB_NAME', 'appdb'),
        user=os.environ.get('DB_USER', 'user'),
        password=os.environ.get('DB_PASSWORD', 'password')
    )


@app.route('/')
def health():
    logger.info("Health check endpoint called")
    return jsonify({"status": "healthy", "service": "my-app"}), 200


@app.route('/api/data', methods=['GET', 'POST'])
def handle_data():
    if request.method == 'POST':
        data = request.json
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            'INSERT INTO items (name, value) VALUES (%s, %s)',
            (data['name'], data['value'])
        )
        conn.commit()
        cur.close()
        conn.close()
        logger.info(f"Data inserted: {data}")
        return jsonify({"message": "Data inserted"}), 201

    # GET request
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT name, value FROM items')
    items = cur.fetchall()
    cur.close()
    conn.close()
    logger.info(f"Retrieved {len(items)} items")
    return jsonify({"items": items}), 200


@app.route('/api/metrics')
def metrics_endpoint():
    return metrics.get_metrics()


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)