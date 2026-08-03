#!/usr/bin/env bash
#
# qx-hybrid 一键发版脚本
# 用法:  ./publish.sh <版本号>           例如  ./publish.sh 0.1.9
#        ./publish.sh <版本号> -f        覆盖已发布过的版本(危险,慎用)
#
# 流程:本地构建发布 -> git 提交 -> push 到 GitHub
# 完成后其他团队即可用坐标:com.energy.sdk:qx-hybrid:<版本号>

set -euo pipefail

# ---- 可按需覆盖的路径(也可用环境变量) ----
ANDROID_PROJECT_DIR="${ANDROID_PROJECT_DIR:-/Users/guqianxiang/Desktop/chery/App/chery_android}"
MAVEN_REPO_DIR="${MAVEN_REPO_DIR:-$HOME/qx-hybrid-maven}"
GIT_REMOTE_URL="https://github.com/gu0315/qx-hybrid-maven.git"
GROUP_PATH="com/energy/sdk/qx-hybrid"

# ---- 参数 ----
VERSION="${1:-}"
FORCE="${2:-}"
if [ -z "$VERSION" ]; then
  echo "用法: ./publish.sh <版本号>        例如: ./publish.sh 0.1.9"
  echo "      ./publish.sh <版本号> -f     覆盖已发布版本(慎用)"
  exit 1
fi

# ---- 防误覆盖:该版本若已 push 过则拦截 ----
cd "$MAVEN_REPO_DIR"
if git ls-files --error-unmatch "$GROUP_PATH/$VERSION" >/dev/null 2>&1 && [ "$FORCE" != "-f" ]; then
  echo "⚠️  版本 $VERSION 已经发布过(git 已追踪)。"
  echo "    覆盖已发布版本会影响已集成的团队;确认要覆盖请加 -f:"
  echo "    ./publish.sh $VERSION -f"
  exit 1
fi

# ---- 1/3 构建并发布到本地仓库目录 ----
echo "==> 1/3 构建并发布 qx-hybrid $VERSION"
cd "$ANDROID_PROJECT_DIR"
./gradlew :qx_hybrid:publishReleasePublicationToRemoteMavenRepository \
  -PMAVEN_REPOSITORY_URL="file://$MAVEN_REPO_DIR" \
  -PQX_HYBRID_VERSION="$VERSION" \
  --console=plain

# ---- 2/3 git 提交 ----
echo "==> 2/3 提交到 git"
cd "$MAVEN_REPO_DIR"
if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin "$GIT_REMOTE_URL"
fi
git branch -M main 2>/dev/null || true
git add .
if git diff --cached --quiet; then
  echo "    没有文件变更,跳过提交。"
else
  git commit -m "release qx-hybrid $VERSION"
fi

# ---- 3/3 push ----
echo "==> 3/3 推送到 GitHub"
git push -u origin main

echo ""
echo "✅ 完成!其他团队可用坐标: com.energy.sdk:qx-hybrid:$VERSION"
echo "   验证 pom: https://raw.githubusercontent.com/gu0315/qx-hybrid-maven/main/$GROUP_PATH/$VERSION/qx-hybrid-$VERSION.pom"
