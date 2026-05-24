# /my-analysis-app/backend/app.py

import os
import uuid
from flask import Flask, request, jsonify
from flask_socketio import SocketIO
from werkzeug.utils import secure_filename

# 导入重构后的核心逻辑模块
from logic.stress_analyzer import create_stress_animation
from logic.nodule_detector import create_nodule_evolution_gif
from logic.stats_processor import run_statistical_analysis

app = Flask(__name__)

def get_secret_key():
    """Return the Flask secret key from the environment."""
    secret_key = os.environ.get('SECRET_KEY')
    if secret_key:
        return secret_key
    if os.environ.get('FLASK_ENV') == 'production':
        raise RuntimeError('SECRET_KEY must be configured in production.')
    return 'dev-only-change-me'


def get_cors_allowed_origins():
    origins = os.environ.get('CORS_ALLOWED_ORIGINS', '*')
    if origins == '*':
        return '*'
    return [origin.strip() for origin in origins.split(',') if origin.strip()]


app.config['SECRET_KEY'] = get_secret_key()
app.config['MAX_CONTENT_LENGTH'] = int(os.environ.get('MAX_CONTENT_LENGTH_MB', '50')) * 1024 * 1024

# 允许所有来源的跨域请求，这主要对WebSocket连接生效。生产环境建议通过环境变量收窄来源。
socketio = SocketIO(app, cors_allowed_origins=get_cors_allowed_origins())

# 配置文件夹路径
UPLOAD_FOLDER = os.environ.get('UPLOAD_FOLDER', 'uploads')
RESULT_FOLDER = os.environ.get('RESULT_FOLDER', 'results')
# 确保静态文件夹存在，以便Flask可以提供服务
STATIC_FOLDER = 'results' 
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(RESULT_FOLDER, exist_ok=True)

# 告诉Flask 'results' 文件夹是一个可以公开访问的静态文件夹
app.static_folder = RESULT_FOLDER
# (可选，但推荐) 明确指定静态URL路径
# 如果不指定，默认为 /results/<filename>
# app.static_url_path = '/results'

ALLOWED_EXTENSIONS = {'.csv'}


def is_allowed_file(filename):
    return os.path.splitext(filename)[1].lower() in ALLOWED_EXTENSIONS


@app.route('/api/upload', methods=['POST'])
def upload_file():
    """处理文件上传的API端点"""
    if 'file' not in request.files:
        return jsonify({"error": "No file part in the request"}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No file selected"}), 400
    if file:
        filename = secure_filename(file.filename)
        if not is_allowed_file(filename):
            return jsonify({"error": "Only CSV files are supported"}), 400
        # 使用UUID确保文件名唯一，避免覆盖
        unique_filename = f"{uuid.uuid4().hex}_{filename}"
        filepath = os.path.join(UPLOAD_FOLDER, unique_filename)
        file.save(filepath)
        # 返回保存在服务器上的相对路径
        return jsonify({"message": "File uploaded successfully", "filepath": filepath})
    return jsonify({"error": "Unknown error"}), 500

@socketio.on('start_processing')
def handle_processing_event(data):
    """处理从前端发来的开始处理任务的WebSocket事件"""
    task_type = data.get('task')
    filepath = data.get('filepath')
    
    if not filepath or not os.path.exists(filepath):
        socketio.emit('error', {'message': f'File not found on server: {filepath}'})
        return

    # 定义一个回调函数，用于在子进程中报告进度
    def progress_callback(progress):
        socketio.emit('progress_update', {'progress': progress})
        socketio.sleep(0) # 允许其他事件处理

    try:
        result_url = None
        if task_type == 'stress':
            output_filename = f"{uuid.uuid4().hex}_stress.gif"
            output_path = os.path.join(RESULT_FOLDER, output_filename)
            create_stress_animation(filepath, output_path, progress_callback=progress_callback)
            # 返回可以直接访问的静态文件URL
            result_url = f"/results/{output_filename}"
        
        elif task_type == 'nodule':
            output_filename = f"{uuid.uuid4().hex}_nodule.gif"
            output_path = os.path.join(RESULT_FOLDER, output_filename)
            create_nodule_evolution_gif(filepath, output_path, progress_callback=progress_callback)
            result_url = f"/results/{output_filename}"

        elif task_type == 'stats':
            output_filename_img = f"{uuid.uuid4().hex}_stats.png"
            output_path_img = os.path.join(RESULT_FOLDER, output_filename_img)
            report = run_statistical_analysis(filepath, output_path_img, progress_callback=progress_callback)
            result_url = {
                "image": f"/results/{output_filename_img}",
                "report": report
            }
        else:
            socketio.emit('error', {'message': 'Unknown task type'})
            return

        socketio.emit('task_complete', {'result_url': result_url})

    except Exception as e:
        socketio.emit('error', {'message': f"An error occurred: {str(e)}"})

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
