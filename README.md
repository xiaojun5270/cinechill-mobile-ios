# CineChill iOS 原生客户端

这是根据本目录中的 `CineChill_openapi.json`（CineChill UI v1.0.0.43）与 `CineChill_移动端_API接口文档.md` 开发的 iOS 原生应用，目标是把 Web 后台（`CineChill Admin.html`）的能力完整搬到手机上，使用系统原生控件与交互，不引入任何第三方依赖。

## 交付内容

`CineChill.xcodeproj` 是可直接打开的 Xcode 工程，`CineChill/` 是全部 SwiftUI 源码（95 个 Swift 文件，约 22030 行），`Info.plist` 位于仓库根目录并通过 `INFOPLIST_FILE` 引用。工程采用 Xcode 16 的「同步文件夹」（`PBXFileSystemSynchronizedRootGroup`，`objectVersion = 77`）组织源码，因此新增或删除 `CineChill/` 下的文件不需要改动工程文件，但**必须用 Xcode 16 或更新版本打开**；更旧的 Xcode 无法识别这种工程格式。

在 Mac 上打开 `CineChill.xcodeproj` 后，选中 `CineChill` target，在 Signing & Capabilities 里换成你自己的开发团队（Bundle ID 默认是 `com.cinechill.mobile`，可自行修改），然后选真机或模拟器运行即可。部署目标是 iOS 17.0，Swift 语言版本 5，iPhone 与 iPad 通用。App 图标是脚本生成的纯色渐变胶片图形，`AppIcon.appiconset` 里放了 1024×1024 的浅色、深色与 tinted 三套单尺寸图（iOS 17 的单一尺寸规范），启动屏用 `Info.plist` 的 `UILaunchScreen` 配合 `LaunchBackground` 颜色与 `LaunchLogo` 图片，不需要 storyboard。想换成自己的图，替换 `Assets.xcassets` 里的同名文件即可。

需要特别说明的是，本机是 Windows + Linux 容器环境，没有 Swift 工具链，所以代码是靠约束写法加脚本静态校验写出来的：所有 API 调用点、模型初始化参数标签、复用组件签名都用脚本逐一比对过生成代码，检查项包括括号配平、重复类型声明、`api.<分组>.<方法>` 是否存在、99 个请求模型的参数标签是否匹配、`session.` 与 `Fmt.` 成员是否存在、是否有声明了却没被引用的视图、ViewBuilder 单块子视图是否超过 10 个上限、功能索引里 82 个条目的 id 唯一性与目标视图是否真实存在，以及每个索引入口是否真的能无参构造。真正的编译验证交给 GitHub Actions；工作流会强制检查 Xcode 与 iPhoneOS SDK 26 以上，避免用旧 SDK 产出没有系统 Liquid Glass 的 IPA。

## 架构

网络层在 `CineChill/Core/APIClient.swift`：统一的 `send(method:path:query:body:)`、Cookie Session 与 Token 双兼容（登录后若响应里带 token 就走 Bearer，否则依赖 `HTTPCookieStorage`）、`URLCredential` 处理自签证书、以及 SSE 用的 `streamRequest`。`APIError` 把 401 单独标成 `isAuthFailure`，各界面据此触发重新登录。

`CineChill/API/` 是从 OpenAPI 生成的客户端：27 个分组文件、300 个方法，覆盖规格里全部 303 个操作中的 300 个——剩下 3 个是 Web 后台自己的静态页面（`/`、`/index.html`、`/login.html`），原生客户端不需要。`Models1/2/3.swift` 是 99 个请求模型，字段名与 snake_case 的 JSON 键通过 `CodingKeys` 映射。

因为规格里 303 个操作的 200 响应**全部没有声明 schema**，响应侧没有生成模型，而是统一用 `Core/JSONValue.swift` 承载。它提供 `first(of:)`、`deepFirst(of:)`、`list(_:)`、`displayString` 等防御式取值方法，界面按「多个可能的键名」依次尝试，服务端字段命名有出入时不会崩，只会显示为空。每个页面都放了「原始数据」入口，可以直接看接口返回的完整 JSON，字段对不上时便于当场核对。

`CineChill/UI/` 是共用组件：`RemoteList` / `RemoteScroll` 负责加载态、失败重试与下拉刷新；`ActionRunner` + `.actionFeedback` 负责写操作的进行中状态与结果提示；`SSEStreamView` 负责所有 SSE 长连接页面；`JSONObjectEditor`、`JSONConfigScreen` 把「服务端返回什么就编辑什么」的配置类接口做成通用表单，未知字段也能改；`KeyValueRow`、`StatusBadge`、`MetricTile`、`PosterCard`、`ModuleRow`、`RemoteImage` 等负责统一视觉。

`CineChill/Features/` 按 Tab 分子目录：`Automation/` 16 个文件、`Library/` 10 个、`Settings/` 10 个、`Discover/` 5 个、`System/` 2 个，共 141 个视图结构体。`App/` 4 个文件（入口、根视图、Tab / 侧边栏容器、功能索引），`Core/` 9 个（网络、错误、会话、服务器档案、SSE、JSON、格式化、应用锁、任务通知），`API/` 4 + 27 个，`UI/` 7 个。

## 界面组织

底部五个 Tab。首页是仪表盘，聚合服务器状态、设备指标、115 账号、任务进度与整理统计。发现页是海报网格加分页，左上角进入「浏览发现」（数据源与类型筛选、TMDb Discover、豆瓣→TMDb 匹配、批量海报、删除 Emby 条目），右上角是搜索。媒体库页汇总 Emby 总览与用户、Emby 任务中心、Emby 搜索、媒体整理与整理记录、二级分类规则、转存历史、缺集统计。自动化页覆盖 RSS、订阅、115 上传与清理、秒传转存、STRM、Webhook / 飞牛签到、爱影转发、Docker 管理。设置页包含服务器管理、302 配置、通知、AI 助手、资源与主题、系统健康、任务中心与系统日志、升级与关于。

按 API 分组看，Discover(40)、RSS(22)、Notify(21)、Drive115Upload(21)、DockerManager(20)、AIEpisodeResolver(17)、Resources(16)、media_organize(14)、Server(13)、Tasks(13)、ForwardAiying(13)、config_302(11)、OrganizeHistory(10)、EmbyUsers(10)、MoviePilot(7)、Drive115Cleanup(7)、Subscriptions(7)、strm(6)、SystemHealth(5)、EmbyTasks(5)、FnosSign(5)、Auth(4)、Webhook(4)、Transfer(3)、Upgrade(3)、public(2) 均有对应界面入口。300 个方法中 297 个在界面里被实际调用，剩下 3 个是设计上不该由手机端调用的：`wechatCallbackVerify` 与 `wechatCallbackMessage` 是企业微信回调服务端的被动接口；`embyCoverProxyURL` 需要服务端用 HMAC 算出的 `ts` 与 `sig`，接口文档里明确写的是「供企业微信等外部服务抓取」，客户端无法也不应自己签名。

三个 SSE 长连接接口都已接上：系统日志页有「实时日志」（`/api/system_logs/stream`，自动滚动、最多保留 1000 行），浏览发现页有「实时事件」（`/api/discover/events`），资源搜索页有「流式搜索」（`/api/forward/search_resources/stream`，各资源站边搜边推）。它们共用 `Core/EventStream.swift` 的 SSE 解析与 `UI/SSEStreamView.swift`，进页面即连接、退出即断开。

## 手机端专属能力

Web 后台没有、但手机上很需要的几件事，都做在了 `App/ModuleIndex.swift` 与 `Core/` 里。

**全局功能搜索与收藏。**82 个二级页面登记在 `ModuleIndex` 里，每条记录带标题、所属分组、所属 Tab、图标、以及包含接口路径的关键词（例如搜 `/api/rss` 或搜「秒传」都能命中）。仪表盘右上角的放大镜、设置页「这台设备 → 全部功能」都进得去，搜索框支持空格分词的 AND 匹配。列表里左滑或长按任意页面即可收藏，收藏与最近访问（最多 8 条）会出现在仪表盘顶部的「常用」卡片和 iPad 侧边栏里，存在 `UserDefaults` 的 `modules.favorites` / `modules.recents`。

**iPad 分栏布局。**`MainTabView` 按 `horizontalSizeClass` 分流：紧凑宽度走原来的五个 Tab，regular 宽度（iPad 全屏、以及 iPad 分屏较宽的一侧）走 `NavigationSplitView`，左栏是五个模块加收藏页，右栏是独立的 `NavigationStack`。切换左栏条目时用 `.id(selection)` 重建右栏导航栈，避免上一个模块的详情页留在右侧。

**Face ID 应用锁。**`Core/AppLock.swift` + `UI/AppLockGate.swift`。开启后每次回到前台都要通过 Face ID / Touch ID（或系统密码兜底），`LAContext` 不可用的设备会直接说明原因而不是留一个开不了的开关；开关只在验证成功后才真正打开，不会把自己锁在外面。它挡的是本机界面，服务端接口本身仍然依赖账号密码鉴权。

**任务完成通知。**`Core/TaskNotifier.swift` 每 45 秒在前台拉一次 `/api/progress`，把上一轮「在跑」而这一轮已完成或已消失的任务算作完成并发本地通知，失败的单独发一条「任务未完成」。首次开启只建立基线、不发通知，避免一次性弹一堆。开了「后台检查」后会注册 `BGAppRefreshTaskRequest`（标识 `com.cinechill.mobile.taskrefresh`，最短间隔 15 分钟），后台唤醒时用 `ServerStore` + 钥匙串里的信息自己建客户端，先试 Cookie、过期才静默登录一次，两者都不成立就安静放弃。**iOS 的后台刷新是「有机会才跑」**，实际间隔可能从十几分钟到数小时，要准时就在前台手动点「立即检查一次」。

**液态玻璃导航栏。**`UI/GlassChrome.swift`。真正的 Liquid Glass 是 iOS 26 + Xcode 26 SDK 的系统行为，只要用新 SDK 重新编译，标准导航栏 / 标签栏 / 工具栏就自动是玻璃材质。iPhone 底部始终只渲染一个系统 `TabView` 标签栏：检测到「用 iOS 26 SDK 编译」且「跑在 iOS 26 及以上」时（`#if compiler(>=6.2)` 加运行时 `isOperatingSystemAtLeast(26)`），完全不干预，让系统自己画；否则在同一个系统栏上通过 `UINavigationBarAppearance` / `UITabBarAppearance` / `UIToolbarAppearance` 使用 `.systemUltraThinMaterial` 近似，不再额外叠加自定义底栏。

## 服务器连接与登录

首次启动进入服务器配置页，填写形如 `http://192.168.1.10:5256` 的地址与用户名密码。支持保存多个服务器并随时切换；`ServerProfile` 里只存地址、用户名等非敏感信息（`UserDefaults`），**密码存 Keychain**（`Core/ServerProfile.swift` 里的 `SecItemAdd` / `SecItemCopyMatching` / `SecItemDelete`）。界面里所有密钥、Cookie、Token 类字段都是只写的：用 `SecureField` 输入，保存成功后清空，不会从服务端响应回填，也不会写进 `UserDefaults` 或 `@AppStorage`。

## GitHub Actions 打包无证书 IPA

`.github/workflows/ios-unsigned-ipa.yml` 在 GitHub 的 macOS runner 上编译并打出无证书 IPA。push 到 `main` 会自动跑一次，也可以在仓库的 Actions 页面点 Run workflow 手动触发；推 `v1.0.0` 这类 tag 时会额外创建 Release 并把 IPA 附上去。产物在对应 run 的 Artifacts 里，`CineChill-unsigned-ipa` 保留 30 天，`build-log` 保留 14 天。

打包用的是 `xcodebuild build` 加上 `CODE_SIGNING_ALLOWED=NO`，产物 `.app` 塞进 `Payload/` 后压成 `.ipa`，并删掉可能残留的 `_CodeSignature`。这样得到的包**不能直接装到 iPhone 上**，必须自己签：AltStore 或 Sideloadly 用 Apple ID 自签（免费账号 7 天有效期），或者用付费开发者证书、企业证书重签。想省掉这一步就得在工作流里塞证书与描述文件，那需要把 p12 和 profile 放进仓库 Secrets——目前没有这么做。

工作流使用 Release + 全模块优化构建。编译失败时会把 `build.log` 里所有 `error:` 行打印到日志末尾，并把同一份摘要写进 Job Summary，也就是 Actions 页面里 run 概览直接能看到的那块，不用下载 artifact。

工作流固定 `runs-on: macos-15`，并在开跑前检查 Xcode 与 iPhoneOS SDK 主版本是否 ≥ 26；版本不够会寻找 runner 上安装的 Xcode 26+ 并切换，找不到就直接报错，防止生成只能显示旧式标签栏的 IPA。

## 需要注意的安全取舍

第一，`Info.plist` 里开了 ATS 例外 `NSAllowsArbitraryLoads`。CineChill 通常部署在局域网、走明文 HTTP，不开这个例外连不上；代价是 App 内所有网络请求都不再强制 HTTPS。如果你的服务器有可信证书，建议把这一项删掉。

第二，服务器配置里有「允许不受信任的证书」开关（`allowInsecureTLS`），打开后对该服务器跳过证书校验，用于自签证书场景。这会让该连接失去中间人攻击防护，只在你确认网络环境可信时打开，并且它是按服务器逐个生效的，不是全局开关。

第三，`NSLocalNetworkUsageDescription` 已填写，首次访问局域网地址时系统会弹权限提示，拒绝后无法连接自建服务器。

第四，后台任务检查会在会话 Cookie 过期时读取钥匙串里的密码静默登录一次。这是「勾选记住密码」的既有代价，不是新增的存储；如果不希望密码在后台被使用，关掉「任务通知 → 后台检查」，或者在服务器配置里不勾记住密码（那样每次启动都要手输）。

第五，`Info.plist` 里为这些能力声明了 `NSFaceIDUsageDescription`、`UIBackgroundModes = fetch` 与 `BGTaskSchedulerPermittedIdentifiers`。通知权限是首次开启开关时才申请的，拒绝后开关不会打开，界面会给一个跳系统设置的入口。

## 已知限制

响应结构未知是最大的不确定性来源：所有列表页都做了多键名兜底，但如果服务端某个接口返回的字段名不在候选里，页面会显示为空而不是报错，此时请点开「原始数据」查看真实字段，再调整对应 `first(of:)` 的候选键。

少数接口在 OpenAPI 里请求体是自由对象（`additionalProperties: true`），Web 后台的调用代码又没在快照里，只能按常见命名推测：批量海报（`/api/discover/tmdb_artwork/batch`）同时提交 `items` 与 `tmdb_ids`，删除 Emby 条目（`/api/discover/emby/items/delete`）同时提交 `item_ids` 与 `ids`，重做整理记录提交 `history_ids` / `reason` / `recognition_identity`，二级分类保存直接回传编辑后的对象。这几个页面都把实际提交的请求体展示在「调试」区，跟服务端日志比对后按需调整键名即可。

实时推送已接入 SSE，但界面上的任务进度、Docker 更新任务等仍以下拉刷新为主，服务端没有为这些场景提供推送通道。计划任务编辑器里的「预设文件」列表取自主题套装接口，若你的服务端预设不在其中，可以直接手填文件名；目标媒体库从 Emby 封面接口读取，读不到时支持手动填写媒体库 ID。图片一律走服务端代理（TMDb / 豆瓣 / Bilibili / Bangumi / RSS 图片代理、Telegram 头像、封面预览 key），因此手机不需要能直连外网图源，但服务端必须能。
