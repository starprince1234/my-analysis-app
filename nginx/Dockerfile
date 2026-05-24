# ./nginx/Dockerfile

# 使用官方的 Nginx Alpine 版本作为基础镜像
FROM nginx:alpine

# 移除默认的 Nginx 配置文件
RUN rm /etc/nginx/conf.d/default.conf

# 因为上下文是项目根目录，所以需要指定 nginx.conf 的完整路径
COPY ./nginx/nginx.conf /etc/nginx/conf.d/
# 这条指令现在可以正确工作了，因为它会在项目根目录找到 frontend 文件夹
COPY ./frontend /usr/share/nginx/html/
