// /my-analysis-app/frontend/js/main.js

document.addEventListener('DOMContentLoaded', () => {
    // 根据当前窗口位置连接Socket.IO服务器
    const socket = io();

    // 获取DOM元素
    const fileInput = document.getElementById('fileInput');
    const uploadButton = document.getElementById('uploadButton');
    const uploadStatus = document.getElementById('uploadStatus');
    const processingControls = document.getElementById('processingControls');
    const progressArea = document.getElementById('progressArea');
    const progressBar = document.getElementById('progressBar');
    const progressText = document.getElementById('progressText');
    const resultArea = document.getElementById('resultArea');
    const resultDisplay = document.getElementById('resultDisplay');

    // 用于存储上传成功后服务器返回的文件路径
    let serverFilepath = null;

    // --- 1. 文件上传逻辑 ---
    uploadButton.addEventListener('click', async () => {
        const file = fileInput.files[0];
        if (!file) {
            uploadStatus.textContent = '请先选择一个文件。';
            return;
        }

        const formData = new FormData();
        formData.append('file', file);
        uploadStatus.textContent = '正在上传...';
        uploadButton.disabled = true;

        try {
            const response = await fetch('/api/upload', {
                method: 'POST',
                body: formData,
            });
            const result = await response.json();

            if (response.ok) {
                uploadStatus.textContent = `上传成功: ${file.name}`;
                serverFilepath = result.filepath;
                processingControls.classList.remove('hidden');
            } else {
                throw new Error(result.error || '上传失败');
            }
        } catch (error) {
            uploadStatus.textContent = `上传出错: ${error.message}`;
        } finally {
            uploadButton.disabled = false;
        }
    });

    // --- 2. 触发分析任务 ---
    processingControls.addEventListener('click', (event) => {
        if (event.target.classList.contains('task-button') && serverFilepath) {
            const task = event.target.dataset.task;
            
            // 重置UI状态
            progressArea.classList.remove('hidden');
            resultArea.classList.add('hidden');
            resultDisplay.innerHTML = '';
            progressBar.style.width = '0%';
            progressText.textContent = '任务已开始，等待服务器响应...';
            
            // 通过WebSocket向后端发送开始处理的指令
            socket.emit('start_processing', { task: task, filepath: serverFilepath });
        }
    });

    // --- 3. 监听WebSocket事件 ---
    socket.on('connect', () => {
        console.log('Successfully connected to WebSocket server.');
    });

    socket.on('progress_update', (data) => {
        const progress = data.progress || 0;
        progressBar.style.width = `${progress}%`;
        progressText.textContent = `处理中... ${progress}%`;
    });

    socket.on('task_complete', (data) => {
        progressText.textContent = '任务完成！';
        progressArea.classList.add('hidden');
        resultArea.classList.remove('hidden');
        
        // 根据返回结果的类型显示内容
        if (typeof data.result_url === 'string' && data.result_url.endsWith('.gif')) {
            const img = document.createElement('img');
            img.src = data.result_url;
            img.alt = 'Generated Animation';
            resultDisplay.appendChild(img);
        } else if (typeof data.result_url === 'object') { // 统计分析的结果
            const report = data.result_url;
            const img = document.createElement('img');
            img.src = report.image;
            img.alt = 'Statistical Analysis Plot';
            
            const pre = document.createElement('pre');
            pre.textContent = report.report;
            
            resultDisplay.appendChild(img);
            resultDisplay.appendChild(pre);
        }
    });

    socket.on('error', (data) => {
        progressText.textContent = `发生错误!`;
        alert(`服务器错误: ${data.message}`);
    });

    socket.on('disconnect', () => {
        console.log('Disconnected from WebSocket server.');
    });
});
