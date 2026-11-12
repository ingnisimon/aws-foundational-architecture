import os
from flask import Flask
import pymysql

app = Flask(__name__)

DB_HOST = os.environ.get('DB_HOST', 'localhost')
DB_USER = os.environ.get('DB_USER', 'admin')
DB_PASSWORD = os.environ.get('DB_PASSWORD', '')
DB_NAME = os.environ.get('DB_NAME', 'appdb')

@app.route('/')
def home():
    db_status = "Disconnected"
    try:
        conn = pymysql.connect(
            host=DB_HOST.split(':')[0],
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            connect_timeout=3
        )
        with conn.cursor() as cursor:
            cursor.execute("SELECT NOW()")
            result = cursor.fetchone()
            db_status = f"Connected successfully! RDS Server Time: {result[0]}"
        conn.close()
    except Exception as e:
        db_status = f"Connection failed: {str(e)}"

    return f"""
    <html>
        <head><title>Foundational Multi-Tier Architecture</title></head>
        <body style="font-family: Arial, sans-serif; margin: 40px; background-color: #f4f4f4;">
            <div style="background: white; padding: 30px; border-radius: 8px; box-shadow: 0px 0px 10px rgba(0,0,0,0.1);">
                <h1 style="color: #232f3e;">Phase 5: Application & RDS Integration</h1>
                <p><b>Kubernetes Pod Hostname:</b> <code>{os.environ.get('HOSTNAME', 'unknown')}</code></p>
                <p><b>Database Status:</b> <span style="color: green; font-weight: bold;">{db_status}</span></p>
                <hr style="border: 0; border-top: 1px solid #ddd;" />
                <p style="color: #666; font-size: 14px;">Running live on Amazon EKS (Kubernetes 1.31) with Karpenter & RDS MySQL.</p>
            </div>
        </body>
    </html>
    """

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
