# QX Hybrid Android SDK — Maven 仓库

本仓库是一个 **Maven 仓库目录**(由 Gradle `maven-publish` 生成),用于把 `qx_hybrid` SDK 分发给其他团队。
直接引用本仓库的 raw 地址即可集成,无需公司内网 Maven 服务。

- **依赖坐标(GAV):** `com.energy.sdk:qx-hybrid:0.1.11`
- **产物:** release AAR + sources jar + pom(含完整传递依赖)

---

## 一、接入方(其他团队)怎么用

### 1. 添加仓库

在使用方工程的 `settings.gradle`(推荐,Gradle 7+ 集中管理仓库)里加:

```groovy
dependencyResolutionManagement {
    repositories {
        // ① 本 SDK 仓库(把下面地址换成本仓库的 raw 根地址)
        maven { url 'https://raw.githubusercontent.com/gu0315/qx-hybrid-maven/main' }

        // ② SDK 的传递依赖来源 —— 必须有，否则部分依赖拉不到
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }        // Android-BLE(com.github.aicareles)在这里
        // 国内网络可加阿里云镜像加速：
        // maven { url 'https://maven.aliyun.com/repository/public' }
    }
}
```

> 若你的项目仍在用旧式 `allprojects { repositories { ... } }`，把上面 `repositories { ... }` 内容照搬进去即可。

### 2. 添加依赖

在 app/模块的 `build.gradle`:

```groovy
dependencies {
    implementation 'com.energy.sdk:qx-hybrid:0.1.11'
}
```

同步即可。以下传递依赖会被自动带入,无需手动声明:
`androidx.appcompat`、`com.google.android.material`、`androidx.core:core-ktx`、
`androidx.webkit:webkit`、`androidx.exifinterface`、`com.google.zxing:core`、
`com.journeyapps:zxing-android-embedded`、`com.github.aicareles:Android-BLE`、
`com.google.code.gson:gson`、`kotlin-stdlib`。

---

## 二、发布方(我)怎么发新版本

用本仓库根目录的一键脚本(构建 → commit → push 全包):

```bash
cd ~/qx-hybrid-maven
./publish.sh 0.1.12
```

使用方把依赖坐标的版本号改成 `0.1.12` 即可升级。

### 覆盖已发布的版本

脚本默认会拦截已发布过的版本号,确认要覆盖时加 `-f`:

```bash
./publish.sh 0.1.11 -f
```

两个注意点:

1. **多个版本一起发时,最高版本要放最后发** —— 否则 `maven-metadata.xml` 的 `<latest>`/`<release>` 会被写成低版本。
2. **必须通知使用方清缓存** —— 版本号没变时 Gradle 不会重新下载,他们构建时用的还是旧 aar。让他们跑 `./gradlew --refresh-dependencies`,或删掉 `~/.gradle/caches/modules-2/files-2.1/com.energy.sdk`。

> 覆盖发布是在跟 Maven「版本不可变」的核心假设对抗,能升版本号就尽量升。
> 联调阶段想让对方自动拿到最新,用 `-SNAPSHOT` 版本(Gradle 会自动当作 changing module),
> 稳定版仍用不可变的数字版本。

---

## 三、说明

- 本仓库由 Gradle 自动生成,**目录结构请勿手动改动**。
- 每个版本独立成目录(`com/energy/sdk/qx-hybrid/<版本号>/`),旧版本保留,可多版本共存。
- `maven-metadata.xml` 由 Gradle 维护,记录可用版本列表。
