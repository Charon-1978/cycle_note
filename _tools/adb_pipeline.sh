#!/usr/bin/env bash
# 真机流水线：等待设备就绪 → 安装 debug APK → 冷启动 → 截图
#
# 为什么必须做成一个脚本、且在**单条 shell 命令**里调用：
#   本环境下 adb server 会在每条命令结束后被回收，跨命令必然重新握手，
#   而设备的 USB 会话经常在握手后几秒内断开。把全部步骤压进一个进程，
#   才能利用唯一的在线窗口。
#
# 用法：
#   bash /d/yueji/_tools/adb_pipeline.sh
# 可覆盖的环境变量：
#   ADB_SERIAL    设备序列号（默认 50dea2c7）
#   APK_PATH      APK 路径
#   WAIT_SECONDS  等待在线秒数（默认 180）
#   SHOT_PATH     截图输出路径

set -u
export PATH="/usr/bin:/bin:/c/Windows/System32:/c/Windows:/d/Android/SDK/platform-tools:$PATH"

SERIAL="${ADB_SERIAL:-50dea2c7}"
APK="${APK_PATH:-D:/yueji/build/app/outputs/flutter-apk/app-debug.apk}"
WAIT="${WAIT_SECONDS:-180}"
SHOT="${SHOT_PATH:-D:/yueji/_shot.png}"

echo "APK: $APK"
[ -f "$APK" ] || { echo "FAIL: APK 不存在"; exit 1; }

adb kill-server >/dev/null 2>&1
adb start-server >/dev/null 2>&1

state() { adb devices | grep "$SERIAL" | awk '{print $2}' | head -1; }

ok=0
for i in $(seq 1 "$WAIT"); do
  s=$(state)
  if [ "$s" = "device" ]; then echo "ONLINE after ${i}s"; ok=1; break; fi
  if [ $((i % 20)) -eq 0 ]; then
    echo "[${i}s] state=${s:-none}"
    adb reconnect offline >/dev/null 2>&1
  fi
  sleep 1
done
if [ "$ok" != "1" ]; then
  echo "FAIL: 设备未就绪（state=$(state)）"
  adb devices -l
  exit 2
fi

echo "=== install ==="
adb -s "$SERIAL" install -r -t "$APK" 2>&1 | cat
echo "=== launch ==="
adb -s "$SERIAL" shell am start -n com.example.cycle_note/.MainActivity 2>&1 | tail -2
sleep 8
echo "=== focus ==="
adb -s "$SERIAL" shell "dumpsys window | grep -E 'mCurrentFocus' | head -2" 2>&1
echo "=== screenshot ==="
adb -s "$SERIAL" shell screencap -p /sdcard/_yueji.png 2>&1
adb -s "$SERIAL" pull /sdcard/_yueji.png "$SHOT" 2>&1 | tail -1
adb -s "$SERIAL" shell rm -f /sdcard/_yueji.png
echo "DONE shot=$SHOT"
