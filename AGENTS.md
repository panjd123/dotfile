# AGENTS

这个文件面向开发者和 AI agent，记录仓库的设计、源码组织和修改规则。

## Goal

仓库的最终交付物始终是根目录单文件：

- `bashrc_common.sh`

为了可维护性，实际开发在多文件源码上进行，再自动构造出最终产物。

## Source Of Truth

源码真相源在：

- `src/bashrc_common.dev.sh`
- `src/modules/**/*.sh`

不要直接手改生成产物 `bashrc_common.sh`。如果确实编辑了，也必须以 `src/` 中的改动为准重新生成覆盖。

## Repository Layout

```text
.
├── bashrc_common.sh
├── src/
│   ├── bashrc_common.dev.sh
│   └── modules/
│       ├── core/
│       ├── shell/
│       ├── network/
│       ├── filesystem/
│       ├── gpu/
│       ├── python/
│       ├── profiles/
│       ├── system/
│       ├── docker/
│       ├── sync/
│       └── ...
├── scripts/
│   └── build_bashrc_common.sh
└── .githooks/
    └── pre-commit
```

模块职责：

- `modules/core/`: dotfile 常量、地域探测、安装流程、CLI、更新入口
- `modules/shell/`: 通用 shell 导航能力
- `modules/network/`: 网络检查、代理环境、代理诊断
- `modules/filesystem/`: 压缩、解压、备份恢复
- `modules/gpu/`: GPU 监控快捷命令
- `modules/python/`: Python 环境、Hugging Face 下载、vLLM bench
- `modules/profiles/`: Claude/Codex profile 切换
- `modules/system/`: systemd、PATH、下载预设、进程观察
- `modules/docker/`: 容器 shell、容器快捷别名、Docker 镜像传输
- `modules/sync/`: 跨机器同步基础设施及具体同步命令

## Build

生成单文件产物：

```bash
scripts/build_bashrc_common.sh
```

这个脚本会：

- 从 `src/bashrc_common.dev.sh` 开始
- 展开其中的 `source "$DOTFILE_DEV_ROOT/..."` 行
- 保留其余 bash 代码
- 生成根目录 `bashrc_common.sh`

## Git Hook

仓库内置 `pre-commit`：

```bash
git config core.hooksPath .githooks
```

hook 在提交前会：

- 重建 `bashrc_common.sh`
- 对 `src/**/*.sh` 做 `bash -n`
- 对生成产物 `bashrc_common.sh` 做 `bash -n`
- 自动把重建后的 `bashrc_common.sh` 加入暂存区

## Edit Rules

修改仓库时遵循这些规则：

- 默认只改 `src/`，不要直接改 `bashrc_common.sh`
- 新增命令时，把用户使用方法写到 `README.md`
- 新增架构规则、构造流程或维护约束时，更新 `AGENTS.md`
- 非显然逻辑要直接写在代码注释里，不把关键设计藏在文档里
- 注释要短，只解释“为什么这样做”或“不明显的行为”
- 保持最终产物仍然可被 `source`，也可被 `bash .../bashrc_common.sh <subcommand>` 执行

## Comment Policy

代码应该尽量自注释，但以下情况必须在代码里写注释：

- 生成流程或 dispatch 这种不直观的控制流
- 依赖 shell 细节的兼容性判断
- 有状态文件或运行时副作用的逻辑
- 看起来像重复代码、但实际上是为了保证交付产物独立可用

不要把仅面向开发者的重要解释只写在 README；应优先写进源码，再在这里补充约束。

## Verification

改动后至少执行：

```bash
scripts/build_bashrc_common.sh
bash -n bashrc_common.sh
find src -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
```

如果改了 CLI，额外执行：

```bash
bash bashrc_common.sh help
bash -s -- help < bashrc_common.sh
```

## Runtime Files

运行时状态文件：

- `~/.dotfile/.network_region`

它不是源码文件，不应手工维护。它由安装流程或 `refresh-region` 自动刷新，用于决定是否启用中国大陆镜像配置。

## Release Rule

每次提交源码改动时，提交里必须同时包含：

- 对应的 `src/` 改动
- 同步生成后的 `bashrc_common.sh`

不接受“源码更新了，但产物没更新”的提交。
