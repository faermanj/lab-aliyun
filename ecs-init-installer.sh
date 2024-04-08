# curl -sSL https://raw.githubusercontent.com/faermanj/lab-aliyun/main/ecs-init-installer.sh | bash
#!/bin/bash
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TMP="$DIR/tmp"

mkdir -p $TMP
curl -Lv -o -o $TMP/$RHCOS_ISO  https://github.com/faermanj/lab-aliyun/archive/refs/heads/main.zip
find .

echo done
