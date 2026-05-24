# /my-analysis-app/backend/logic/stats_processor.py

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.fftpack import fft
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
import json

def run_statistical_analysis(csv_path, output_image_path, progress_callback=None):
    """
    对单个CSV文件执行统计特征分析（FFT + K-Means聚类）。
    生成一张聚类结果图和一个包含统计信息的JSON报告。

    :param csv_path: 输入的CSV文件路径。
    :param output_image_path: 生成的聚类图表的保存路径。
    :param progress_callback: 用于报告进度的回调函数。
    :return: 包含分析结果的JSON格式字符串。
    """
    try:
        df = pd.read_csv(csv_path)
        mat_columns = [f'MAT_{i}' for i in range(96)]
        
        if not all(col in df.columns for col in mat_columns):
            raise ValueError("CSV文件缺少必需的 'MAT_*' 列。")

        mat_data = df[mat_columns].values
        if progress_callback: progress_callback(10)
    except Exception as e:
        raise ValueError(f"读取或验证CSV文件时出错: {e}")

    # 1. 提取特征：使用FFT获取每个传感器信号的主频分量
    n_samples = mat_data.shape[0]
    fft_data = np.abs(np.apply_along_axis(fft, 0, mat_data))
    # 取前一半的频率分量（因为FFT是对称的），并排除直流分量[0]
    features = np.mean(fft_data[1:n_samples//2, :], axis=0)
    
    if progress_callback: progress_callback(40)

    # 2. 特征缩放
    scaler = StandardScaler()
    scaled_features = scaler.fit_transform(features.reshape(-1, 1))
    if progress_callback: progress_callback(60)

    # 3. K-Means聚类
    n_clusters = 3 # 可根据需求调整
    kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init='auto')
    clusters = kmeans.fit_predict(scaled_features)
    if progress_callback: progress_callback(80)

    # 4. 生成可视化图表并保存
    plt.figure(figsize=(14, 7))
    plt.style.use('seaborn-v0_8-whitegrid')
    scatter = plt.scatter(range(len(features)), features, c=clusters, cmap='viridis', s=80, alpha=0.8)
    plt.title('Feature Clustering of Sensors (based on Frequency Domain)', fontsize=16)
    plt.xlabel('Sensor Index (MAT_0 to MAT_95)', fontsize=12)
    plt.ylabel('Average Frequency Magnitude (Feature)', fontsize=12)
    plt.xticks(np.arange(0, 97, 8))
    plt.grid(True, which='both', linestyle='--', linewidth=0.5)
    
    cluster_labels = [f'Cluster {i}' for i in range(n_clusters)]
    plt.legend(handles=scatter.legend_elements()[0], labels=cluster_labels, title="Clusters")
    
    plt.tight_layout()
    plt.savefig(output_image_path, dpi=150)
    plt.close()
    if progress_callback: progress_callback(95)

    # 5. 生成JSON格式的报告
    report = {
        'analysis_summary': {
            'total_sensors': len(features),
            'n_clusters': n_clusters,
            'feature_type': 'Average Frequency Magnitude'
        },
        'cluster_assignments': {}
    }
    for i in range(n_clusters):
        sensor_indices = np.where(clusters == i)[0]
        report['cluster_assignments'][f'cluster_{i}'] = {
            'sensor_count': len(sensor_indices),
            'sensor_indices': sensor_indices.tolist(),
            'avg_feature_value': np.mean(features[sensor_indices])
        }
    
    if progress_callback: progress_callback(100)
    return json.dumps(report, indent=4)

