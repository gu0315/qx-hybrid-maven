#!/usr/bin/env bash
#
# 在【公司电脑】(内网、能访问 GitLab)运行,把自己电脑构建好、拷过来的产物
# 上传到 GitLab Package Registry。无需 Android SDK / gradle,只要 curl。
#
# 首次使用前设置认证:
#   export GITLAB_TOKEN='<deploy-token 或 personal access token>'
#   # 若用的是 Personal Access Token,请改用 Private-Token 头:
#   #   export GITLAB_TOKEN_HEADER='Private-Token'
#   export GITLAB_PROJECT_ID='<android-sdk-maven 项目的 ID>'   # 见该项目 Settings→General
#
# 用法(在本目录下):
#   ./upload-to-gitlab.sh 0.1.8

set -euo pipefail

GITLAB_BASE="https://paas-gitlab.mychery.com"
PROJECT_ID="${GITLAB_PROJECT_ID:-11998}"   # android-sdk-maven 项目 ID
GROUP_PATH="com/energy/sdk/qx-hybrid"
TOKEN_HEADER="${GITLAB_TOKEN_HEADER:-Deploy-Token}"

VERSION="${1:-}"
REPO_ROOT="${2:-$(cd "$(dirname "$0")" && pwd)}"
if [ -z "$VERSION" ]; then
  echo "用法: ./upload-to-gitlab.sh <版本号>   例如: ./upload-to-gitlab.sh 0.1.8"
  exit 1
fi
: "${GITLAB_TOKEN:?请先 export GITLAB_TOKEN=<deploy-token 或 PAT>}"

BASE_API="$GITLAB_BASE/api/v4/projects/$PROJECT_ID/packages/maven"
VDIR="$REPO_ROOT/$GROUP_PATH/$VERSION"

put() {
  local localfile="$1" remotepath="$2"
  if [ ! -f "$localfile" ]; then
    echo "  跳过(不存在): $localfile"; return
  fi
  printf 'PUT %s ... ' "$remotepath"
  curl -sf --header "$TOKEN_HEADER: $GITLAB_TOKEN" \
       --upload-file "$localfile" \
       "$BASE_API/$remotepath" \
       -o /dev/null -w "HTTP %{http_code}\n"
}

echo "==> 上传 qx-hybrid $VERSION 到 GitLab 项目 #$PROJECT_ID"
put "$VDIR/qx-hybrid-$VERSION.aar"              "$GROUP_PATH/$VERSION/qx-hybrid-$VERSION.aar"
put "$VDIR/qx-hybrid-$VERSION.pom"              "$GROUP_PATH/$VERSION/qx-hybrid-$VERSION.pom"
put "$VDIR/qx-hybrid-$VERSION-sources.jar"      "$GROUP_PATH/$VERSION/qx-hybrid-$VERSION-sources.jar"
put "$VDIR/qx-hybrid-$VERSION.module"           "$GROUP_PATH/$VERSION/qx-hybrid-$VERSION.module"
put "$REPO_ROOT/$GROUP_PATH/maven-metadata.xml" "$GROUP_PATH/maven-metadata.xml"

echo ""
echo "✅ 上传完成: com.energy.sdk:qx-hybrid:$VERSION"
echo "   到 GitLab 项目 Deploy → Package Registry 可看到该包"
