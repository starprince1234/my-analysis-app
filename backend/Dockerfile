# /my-analysis-app/backend/Dockerfile

# 使用官方的 Python 3.12 slim 版本作为基础镜像
FROM python:3.12-slim

# 设置工作目录
WORKDIR /app

# 复制依赖文件
COPY requirements.txt .

# 安装 Python 依赖，--no-cache-dir 减小镜像体积
RUN pip install --no-cache-dir -r requirements.txt

# 将当前目录下的所有文件复制到工作目录
COPY . .

# （启动命令已移至 docker-compose.yml 以获得更大灵活性）
