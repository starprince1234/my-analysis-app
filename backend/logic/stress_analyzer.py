# /my-analysis-app/backend/logic/stress_analyzer.py

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image
import io

def create_stress_animation(csv_path, output_gif_path, frame_count=50, progress_callback=None):
    """
    根据CSV数据生成一个包含2D热图、3D表面图、等高线图和统计信息的多合一应力分析GIF。
    
    :param csv_path: 输入的CSV文件路径。
    :param output_gif_path: 输出的GIF文件路径。
    :param frame_count: 要生成的动画帧数。
    :param progress_callback: 用于报告进度的回调函数，例如 a(50) 表示50%。
    """
    try:
        df = pd.read_csv(csv_path)
        stress_columns = [f'MAT_{i}' for i in range(96)]
        
        # 检查必要的列是否存在
        if not all(col in df.columns for col in stress_columns):
            raise ValueError("CSV文件缺少必需的 'MAT_*' 列。")

    except Exception as e:
        raise ValueError(f"读取或验证CSV文件时出错: {e}")

    images = []
    total_frames = min(frame_count, len(df))

    for idx in range(total_frames):
        try:
            stress_matrix = df[stress_columns].iloc[idx].values.astype(float).reshape(12, 8)
            
            fig = plt.figure(figsize=(18, 10))
            gs = plt.GridSpec(2, 3, height_ratios=[3, 1])
            plt.style.use('default')

            # 1. 2D热图
            ax1 = fig.add_subplot(gs[0, 0])
            im1 = ax1.imshow(stress_matrix, cmap='viridis', aspect='equal')
            ax1.set_title('2D Stress Distribution')
            fig.colorbar(im1, ax=ax1)
            
            # 2. 3D表面图
            ax2 = fig.add_subplot(gs[0, 1], projection='3d')
            x = np.arange(stress_matrix.shape[1])
            y = np.arange(stress_matrix.shape[0])
            X, Y = np.meshgrid(x, y)
            ax2.plot_surface(X, Y, stress_matrix, cmap='viridis', linewidth=0)
            ax2.set_title('3D Surface Plot')
            
            # 3. 等高线图
            ax3 = fig.add_subplot(gs[0, 2])
            contour = ax3.contourf(X, Y, stress_matrix, levels=20, cmap='viridis')
            ax3.set_title('Contour Map')
            fig.colorbar(contour, ax=ax3)
            
            # 4. 统计信息
            ax_stats = fig.add_subplot(gs[1, :])
            ax_stats.axis('off')
            stats_text = (
                f'Time Step: {idx}\n'
                f'Max: {np.max(stress_matrix):.2f} | '
                f'Min: {np.min(stress_matrix):.2f} | '
                f'Mean: {np.mean(stress_matrix):.2f} | '
                f'Std Dev: {np.std(stress_matrix):.2f}'
            )
            ax_stats.text(0.5, 0.5, stats_text, ha='center', va='center',
                          bbox=dict(facecolor='white', alpha=0.8, edgecolor='gray'))
            
            plt.tight_layout()
            
            # 将图像帧保存到内存
            buf = io.BytesIO()
            plt.savefig(buf, format='png')
            buf.seek(0)
            images.append(Image.open(buf))
            plt.close(fig)

        except Exception as e:
            plt.close('all') # 确保关闭所有未完成的图形
            print(f"处理帧 {idx} 时发生错误: {e}") # 在服务器日志中打印错误
            continue # 跳过错误的帧

        # 报告进度
        if progress_callback:
            progress = int(((idx + 1) / total_frames) * 100)
            progress_callback(progress)

    if not images:
        raise RuntimeError("未能成功生成任何动画帧。")

    # 将所有帧合成为GIF
    images[0].save(
        output_gif_path,
        save_all=True,
        append_images=images[1:],
        duration=300,  # 每帧持续时间 (ms)
        loop=0         # 0表示无限循环
    )
