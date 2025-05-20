## 删除MD5值相同的文件

通过MD5值把重复的文件移到del文件夹，表格记录。
```
import os
import hashlib
import shutil
import csv

def calculate_md5(file_path, chunk_size=4096):
    """计算单个文件的 MD5 值"""
    md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(chunk_size), b""):
            md5.update(chunk)
    return md5.hexdigest()

def dedup_and_log(src_dir, del_dir,
                  all_md5_csv, dup_md5_csv):
    """
    1. 扫描 src_dir，计算每个文件的 MD5，写入 all_md5_csv
    2. 找到出现次数 >1 的 MD5，把这一组文件全部
       记录到 dup_md5_csv，并把“第二份及以后”移到 del_dir
    """
    # 确保 del 目录存在
    os.makedirs(del_dir, exist_ok=True)

    md5_to_paths = {}        # {md5: [path1, path2, ...]}
    # ------- 第一次遍历：收集信息并写全量表 -------
    with open(all_md5_csv, "w", newline='', encoding="utf-8-sig") as f_all:
        all_writer = csv.writer(f_all)
        all_writer.writerow(["File Path", "MD5"])

        for root, _, files in os.walk(src_dir):
            for name in files:
                path = os.path.join(root, name)
                file_md5 = calculate_md5(path)
                all_writer.writerow([path, file_md5])

                md5_to_paths.setdefault(file_md5, []).append(path)

    # ------- 第二步：输出重复表 & 移动重复 -------
    with open(dup_md5_csv, "w", newline='', encoding="utf-8-sig") as f_dup:
        dup_writer = csv.writer(f_dup)
        dup_writer.writerow(["File Path", "MD5"])

        for md5, paths in md5_to_paths.items():
            if len(paths) > 1:                 # 这一组有重复
                # 把所有路径都写进重复表
                for path in paths:
                    dup_writer.writerow([path, md5])

                # 把第二份及以后移到 del 目录
                for path in paths[1:]:
                    dst = os.path.join(del_dir, os.path.basename(path))
                    # 若同名冲突，给文件名加序号
                    i = 1
                    base, ext = os.path.splitext(dst)
                    while os.path.exists(dst):
                        dst = f"{base}_{i}{ext}"
                        i += 1
                    shutil.move(path, dst)
                    print(f"Moved duplicate: {path}  ->  {dst}")

# ---------- 用法示例 ----------
source_directory      = r"f:\xz\dy"
delete_directory      = r"f:\xz\del"

all_md5_csv_path      = r"f:\xz\all_files_md5.csv"
duplicates_md5_csv    = r"f:\xz\duplicates_md5.csv"

dedup_and_log(source_directory,
              delete_directory,
              all_md5_csv_path,
              duplicates_md5_csv)
```