# YXCodingAgent

一个基于 Python 的终端 AI 编程助手。它可以理解项目上下文、搜索和修改文件、执行命令，并通过权限控制、沙箱和可追踪的工具调用帮助开发者更安全地完成编程任务。

> 项目状态：持续开发中。API、配置格式和部分高级功能可能发生变化。

## 项目简介

YXCodingAgent（命令名：`yx`）面向需要在终端中使用 AI 辅助开发的个人开发者和团队。它将大语言模型与本地项目工具连接起来，让你可以用自然语言完成代码阅读、问题定位、功能实现、测试运行和项目总结。

项目不会把 API Key 写入源码或配置模板。模型服务通过环境变量配置，真实配置、会话记录和运行日志默认保存在本地并被 Git 忽略。

## 核心功能

- **终端交互**：支持交互式会话和单次提示词任务。
- **项目理解**：搜索、读取、编辑文件，查看差异，并保留会话上下文。
- **命令执行**：在项目目录中执行开发命令，并返回工具结果与错误信息。
- **权限控制**：支持 `default`、`accept-edits`、`plan` 和 `bypass` 模式。
- **多模型接入**：支持 OpenAI 兼容接口和 Anthropic Messages API，可配置多个 Provider。
- **MCP 扩展**：接入命令行或 HTTP/SSE MCP 服务，扩展外部工具能力。
- **子 Agent 与团队协作**：拆分任务、跟踪进度，并让多个 Agent 协同处理复杂任务。
- **Git worktree**：为隔离任务创建独立工作树，降低并行修改之间的影响。
- **记忆与上下文管理**：支持会话记录、上下文压缩、项目记忆和任务通知。
- **远程模式**：通过 WebSocket 服务和浏览器界面访问 Agent。
- **流式输出**：单次任务支持普通文本和 NDJSON `stream-json` 输出。

## 系统要求

- Windows、macOS 或 Linux
- Python 3.11 或更高版本
- [uv](https://docs.astral.sh/uv/)
- 至少一个兼容的模型服务 API Key

## 快速开始

### 1. 安装依赖

```powershell
uv sync
```

生产环境可以跳过开发依赖：

```powershell
uv sync --no-dev
```

### 2. 配置环境变量

复制环境变量模板：

```powershell
Copy-Item .env.example .env
```

然后在本地 `.env` 中填写 API Key。`.env` 只应保存在本机，绝对不要提交到 GitHub：

```dotenv
OPENAI_API_KEY=你的本地密钥
ANTHROPIC_API_KEY=你的本地密钥
DEFAULT_MODEL=example-model
```

也可以使用其他 Provider 的环境变量，但必须在配置文件中通过 `${ENVIRONMENT_VARIABLE}` 引用，而不是直接写入密钥。

### 3. 配置 Provider

复制配置模板：

```powershell
New-Item -ItemType Directory -Force .yx
Copy-Item .yx/config.yaml.example .yx/config.yaml
```

示例配置如下，真实密钥通过环境变量读取：

```yaml
providers:
  - name: openai-compatible
    protocol: openai-compat
    base_url: https://api.example.com/v1
    api_key: "${OPENAI_API_KEY}"
    model: example-model
    thinking: false

permission_mode: default
```

如使用 Anthropic，可在 `providers` 中增加对应配置：

```yaml
  - name: anthropic
    protocol: anthropic
    base_url: https://api.anthropic.com
    api_key: "${ANTHROPIC_API_KEY}"
    model: claude-sonnet-4-20250514
```

### 4. 启动

Windows 可以运行：

```powershell
.\start.ps1
```

也可以直接启动：

```powershell
uv run yx
```

## 使用方式

### 交互模式

```powershell
uv run yx
```

启动后输入自然语言任务，例如：

```text
请检查当前项目的测试失败原因，并给出修复方案
```

### 单次任务模式

```powershell
uv run yx -p "请检查当前项目并总结主要问题"
```

### JSON 流输出

适合脚本或其他程序消费 Agent 事件：

```powershell
uv run yx -p "检查项目" --output-format stream-json
```

### 远程模式

启动 WebSocket 服务并通过浏览器访问：

```powershell
uv run yx --remote
```

默认地址为 `http://localhost:18888`。远程模式建议只绑定在可信的本机或内网环境，并结合防火墙、反向代理和访问控制使用。

### 覆盖权限模式

```powershell
uv run yx --mode plan
```

权限模式说明：

| 模式 | 行为 |
| --- | --- |
| `default` | 敏感操作执行前请求确认 |
| `accept-edits` | 自动允许文件编辑，其他敏感操作仍需确认 |
| `plan` | 只分析和制定计划，不直接执行修改 |
| `bypass` | 跳过权限确认，仅建议在隔离环境中使用 |

## MCP 配置

在本地 `.yx/config.yaml` 的 `mcp_servers` 中配置 MCP 服务。命令行 MCP 示例：

```yaml
mcp_servers:
  - name: context7
    command: npx
    args: ["-y", "@upstash/context7-mcp"]
```

MCP 配置中的 `headers`、`env` 和命令参数同样可能包含密钥。请使用环境变量引用，并确保本地配置不会被提交。

## 安全与隐私

这是一个可以读取文件、执行命令和修改项目的本地开发工具，请在可信的项目目录中使用。

- 不要把 `OPENAI_API_KEY`、`ANTHROPIC_API_KEY`、MCP Token 或其他凭证写入源码、README、截图、Issue、日志或提交信息。
- 不要提交 `.env`、`.yx/config.yaml`、`.yx/sessions/`、`.yx/session/`、`.yx/memory/`、`.yx/file-history/`、`.yx/debug.log` 和本地历史文件。
- 使用 `git status --ignored` 和 `git check-ignore -v 文件名` 检查敏感文件是否被忽略。
- 提交前扫描公开文件和 Git 历史；如果密钥曾经进入提交历史，应立即撤销并重新生成密钥，不能只删除当前文件。
- 优先使用 `default` 或 `plan` 权限模式；使用 `bypass` 前应确认项目目录和命令风险。
- 不要把远程模式直接暴露到公网；如确有需要，应配置身份认证、HTTPS/WSS 和网络访问控制。

## 项目结构

```text
YX/
├── yx/                  # 核心源代码
│   ├── agents/           # Agent、子 Agent 和任务管理
│   ├── commands/         # 命令处理器
│   ├── context/          # 上下文管理
│   ├── mcp/              # MCP 客户端与工具包装
│   ├── memory/           # 项目记忆与会话记忆
│   ├── permissions/      # 权限规则与安全检查
│   ├── teams/            # 团队协作
│   ├── tools/            # 文件、命令和 Agent 工具
│   ├── worktree/         # Git worktree 隔离
│   ├── app.py            # 终端应用
│   └── remote.py         # 远程服务模式
├── tests/                # 自动化测试
├── .env.example          # 环境变量模板
├── .yx/config.yaml.example # Provider 配置模板
├── start.ps1             # Windows 启动脚本
├── pyproject.toml        # Python 项目配置
└── uv.lock               # 依赖锁定文件
```

## 开发与测试

```powershell
uv run yx --help
uv run python -m compileall yx
uv run pytest
```

## 常见问题

### 启动时提示缺少 API Key

确认已经创建本地 `.env`，并且 `.yx/config.yaml` 中的 `api_key` 使用了正确的环境变量名称。修改 `.env` 后重新启动程序。

### 如何切换模型或服务商？

编辑本地 `.yx/config.yaml` 的 `providers` 配置。可以同时配置多个 Provider，启动后根据界面提示选择。

### Agent 是否会自动执行危险命令？

默认权限模式会在敏感操作前请求确认。即使使用自动允许模式，也应检查命令内容和变更差异，并在隔离环境中运行高风险任务。

## 贡献

欢迎通过 Issue 报告问题、提出功能建议或提交 Pull Request。提交前请：

1. 不提交 API Key、个人配置、会话数据和日志。
2. 运行 `uv run pytest` 和 `uv run python -m compileall yx`。
3. 在 Pull Request 中说明改动目的、测试方式和可能的兼容性影响。

## GitHub 项目文案

### 推荐项目简介

```text
基于 Python 的终端 AI 编程助手，支持项目理解、文件编辑、命令执行、多 Agent 协作、MCP 扩展、Git worktree 隔离和权限控制。
```

### 推荐 Topics

```text
python, ai, coding-agent, terminal, cli, llm, mcp, developer-tools, automation, openai, anthropic
```

### 英文短简介

```text
A Python-based terminal AI coding assistant with tool use, permission controls, MCP integration, multi-agent collaboration, and Git worktree isolation.
```

## 许可证

本项目当前尚未确定正式开源许可证。在许可证文件补充前，请不要将本项目用于需要明确授权条款的生产或商业场景。

## 免责声明

AI 生成的代码、命令和解释可能存在错误或安全风险。执行命令、提交代码、修改数据或进行其他重要操作前，请人工检查内容并自行确认结果。项目维护者不对因使用本工具造成的数据丢失、服务费用、系统损坏或其他损失承担责任。
