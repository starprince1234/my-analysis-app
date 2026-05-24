# /my-analysis-app/backend/logic/nodule_detector.py

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.mixture import GaussianMixture
from skimage.measure import regionprops
from skimage.morphology import closing, disk
from PIL import Image
import io

def create_nodule_evolution_gif(csv_path, output_gif_path, frame_count=30, progress_callback=None):
    """
    根据CSV数据创建结节检测演化的动态可视化GIF。
    
    :param csv_path: 输入的CSV文件路径。
    :param output_gif_path: 输出的GIF文件路径。
    :param frame_count: 要生成的动画帧数。
    :param progress_callback: 用于报告进度的回调函数。
    """
    try:
        df = pd.read_csv(csv_path)
        stress_columns = [f'MAT_{i}' for i in range(96)]
        
        if not all(col in df.columns for col in stress_columns):
            raise ValueError("CSV文件缺少必需的 'MAT_*' 列。")
        if 'SN' not in df.columns:
            raise ValueError("CSV文件缺少必需的 'SN' 时间序列列。")
            
        stress_data = df[stress_columns].values
        time_points = df['SN'].values
        # 处理可能的NaN值
        if np.isnan(stress_data).any():
            col_means = np.nanmean(stress_data, axis=0)
            nan_indices = np.where(np.isnan(stress_data))
            stress_data[nan_indices] = np.take(col_means, nan_indices[1])

    except Exception as e:
        raise ValueError(f"读取或预处理CSV文件时出错: {e}")

    images = []
    total_frames = min(frame_count, len(df))
    nodule_features = {'area': [], 'circularity': [], 'intensity': []}

    for idx in range(total_frames):
        try:
            fig = plt.figure(figsize=(18, 10))
            gs = plt.GridSpec(2, 3, height_ratios=[3, 1])
            plt.style.use('seaborn-v0_8-darkgrid')
            
            # 1. 原始应力分布
            ax_orig = plt.subplot(gs[0, 0])
            stress_grid = stress_data[idx, :].reshape(12, 8)
            min_val, max_val = np.min(stress_grid), np.max(stress_grid)
            stress_normalized = (stress_grid - min_val) / (max_val - min_val) if max_val > min_val else np.zeros_like(stress_grid)
            
            im_orig = ax_orig.imshow(stress_normalized, cmap='viridis', origin='lower')
            ax_orig.set_title('Original Stress Distribution')
            fig.colorbar(im_orig, ax=ax_orig, label='Normalized Stress')

            # 2. 结节检测
            ax_detect = plt.subplot(gs[0, 1])
            gmm = GaussianMixture(n_components=2, random_state=42)
            labels = gmm.fit_predict(stress_normalized.reshape(-1, 1))
            abnormal_class = np.argmax(gmm.means_.flatten())
            nodule_mask = (labels.reshape(12, 8) == abnormal_class)
            nodule_mask = closing(nodule_mask, disk(2))
            
            ax_detect.imshow(stress_normalized, cmap='gray', origin='lower')
            ax_detect.imshow(nodule_mask, cmap='Reds', alpha=0.5, origin='lower')
            ax_detect.set_title('Nodule Detection Result')

            # 3. 特征趋势
            ax_trend = plt.subplot(gs[0, 2])
            props = regionprops(nodule_mask.astype(int))
            if props:
                largest_nodule = max(props, key=lambda p: p.area)
                area = largest_nodule.area
                perimeter = largest_nodule.perimeter
                circularity = 4 * np.pi * area / (perimeter**2) if perimeter > 0 else 0
                intensity = np.mean(stress_normalized[nodule_mask])
                nodule_features['area'].append(area)
                nodule_features['circularity'].append(circularity)
                nodule_features['intensity'].append(intensity)
            
            if len(nodule_features['area']) > 1:
                ax_trend.plot(nodule_features['area'], label='Area', color='blue')
                ax_trend.set_ylabel('Area', color='blue')
                ax_trend2 = ax_trend.twinx()
                ax_trend2.plot(nodule_features['circularity'], label='Circularity', color='red')
                ax_trend2.set_ylabel('Circularity', color='red')
                ax_trend.set_title('Feature Trends')

            plt.suptitle(f'Nodule Analysis - Time: {time_points[idx]}', fontsize=16)
            plt.tight_layout(rect=[0, 0, 1, 0.96])

            buf = io.BytesIO()
            plt.savefig(buf, format='png')
            buf.seek(0)
            images.append(Image.open(buf))
            plt.close(fig)

        except Exception as e:
            plt.close('all')
            print(f"处理帧 {idx} 时发生错误: {e}")
            continue

        if progress_callback:
            progress_callback(int(((idx + 1) / total_frames) * 100))

    if not images:
        raise RuntimeError("未能成功生成任何动画帧。")

    images[0].save(
        output_gif_path,
        save_all=True,
        append_images=images[1:],
        duration=300,
        loop=0
    )
