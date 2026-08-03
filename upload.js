// 用 Node 把 qx-hybrid 产物上传到公司 GitLab Package Registry(零依赖,无需 npm install)。
// 在【公司电脑】(内网、能访问 GitLab)运行,和产物目录放一起。
//
// 用法(在本目录下):
//   1) 设置认证(Windows cmd):     set GITLAB_TOKEN=<deploy-token>
//      或 PowerShell:              $env:GITLAB_TOKEN='<deploy-token>'
//   2) 运行:                       node upload.js 0.1.8
//
// 可选环境变量:
//   GITLAB_PROJECT_ID   默认 11998(android-sdk-maven)
//   GITLAB_TOKEN_HEADER 默认 Deploy-Token(用 Personal Access Token 时设为 Private-Token)
//   INSECURE=1          内网自签证书导致报错时,跳过证书校验

const fs = require('fs');
const path = require('path');
const https = require('https');
const { URL } = require('url');

const version = process.argv[2];
if (!version) {
  console.error('用法: node upload.js <版本号>   例如: node upload.js 0.1.8');
  process.exit(1);
}
const token = process.env.GITLAB_TOKEN;
if (!token) {
  console.error('请先设置认证:  set GITLAB_TOKEN=<deploy-token>   (PowerShell 用 $env:GITLAB_TOKEN=...)');
  process.exit(1);
}

const base = 'https://paas-gitlab.mychery.com';
const projectId = process.env.GITLAB_PROJECT_ID || '11998';
const groupPath = 'com/energy/sdk/qx-hybrid';
const tokenHeader = process.env.GITLAB_TOKEN_HEADER || 'Deploy-Token';
const insecure = process.env.INSECURE === '1';

const repoRoot = __dirname;
const groupDir = path.join(repoRoot, ...groupPath.split('/'));
const vdir = path.join(groupDir, version);

const files = [
  [path.join(vdir, `qx-hybrid-${version}.aar`),         `${groupPath}/${version}/qx-hybrid-${version}.aar`],
  [path.join(vdir, `qx-hybrid-${version}.pom`),         `${groupPath}/${version}/qx-hybrid-${version}.pom`],
  [path.join(vdir, `qx-hybrid-${version}-sources.jar`), `${groupPath}/${version}/qx-hybrid-${version}-sources.jar`],
  [path.join(vdir, `qx-hybrid-${version}.module`),      `${groupPath}/${version}/qx-hybrid-${version}.module`],
  [path.join(groupDir, 'maven-metadata.xml'),           `${groupPath}/maven-metadata.xml`],
];

function put(localFile, remotePath) {
  return new Promise((resolve, reject) => {
    if (!fs.existsSync(localFile)) {
      console.log(`  跳过(不存在): ${localFile}`);
      return resolve();
    }
    const url = new URL(`${base}/api/v4/projects/${projectId}/packages/maven/${remotePath}`);
    const data = fs.readFileSync(localFile);
    const req = https.request({
      method: 'PUT',
      hostname: url.hostname,
      port: url.port || 443,
      path: url.pathname,
      headers: {
        [tokenHeader]: token,
        'Content-Type': 'application/octet-stream',
        'Content-Length': data.length,
      },
      rejectUnauthorized: !insecure,
    }, (res) => {
      let body = '';
      res.on('data', (c) => (body += c));
      res.on('end', () => {
        console.log(`PUT ${remotePath} -> HTTP ${res.statusCode}`);
        if (res.statusCode >= 200 && res.statusCode < 300) resolve();
        else reject(new Error(`失败 HTTP ${res.statusCode}: ${body.slice(0, 300)}`));
      });
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

(async () => {
  console.log(`==> 上传 qx-hybrid ${version} 到 GitLab 项目 #${projectId}`);
  try {
    for (const [local, remote] of files) await put(local, remote);
    console.log(`\n✅ 上传完成: com.energy.sdk:qx-hybrid:${version}`);
    console.log('   到 android-sdk-maven 项目 Deploy -> Package Registry 查看');
  } catch (e) {
    console.error(`\n❌ ${e.message}`);
    process.exit(1);
  }
})();
