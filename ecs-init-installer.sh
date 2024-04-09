# curl -sSL https://raw.githubusercontent.com/faermanj/lab-aliyun/main/ecs-init-installer.sh | bash
#!/bin/bash
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TMP="/tmp/labay"

mkdir -p $TMP
curl -Lv -O $TMP  https://github.com/faermanj/lab-aliyun/archive/refs/heads/main.zip
cd $TMP
unzip main.zip

echo "=== OpenShift LabAY Install Script ==="
echo "pwd: $(pwd)"
echo "whoami: $(whoami)"
echo "find:"
find .

echo "=== OpenShift LabAY Install Script Done ==="
