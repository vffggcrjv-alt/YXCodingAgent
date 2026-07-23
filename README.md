# YXCodingAgent

一个用 Python 编写的终端 AI 编程助手，也是一个用来理解 Agent 架构的学习型项目。

YXCodingAgent 的重点不是做一个可以替代成熟产品的生产级工具，而是把一个 Coding Agent 的关键环节拆开、实现并串起来：模型如何驱动工具，工具如何修改真实项目，权限如何介入执行过程，以及多 Agent 如何协作完成任务。

> **项目定位**
>
> YXCodingAgent 和 Claude Code 的差距，主要不在 Agent 架构层面，而在大量细节打磨：交互体验、可靠性、边界处理、性能、兼容性和工程化成熟度。本项目适合阅读、实验和二次开发，不应默认用于重要生产环境。

## 项目亮点

- **MCP 工具延迟加载优化**：实现工具定义按需加载，注册阶段仅传递工具名称；百级工具场景下，工具描述**Token 占用降低 85%**，有效缓解上下文窗口挤占问题。
- **统一多 LLM 流式协议层**：封装 OpenAI、Anthropic 异构流式接口，对外提供标准化事件接口，**新增模型厂商仅需少量适配**，提升框架扩展性。
- **双层渐进式上下文压缩**：兼顾 Function Calling 调用约束，实现会话上下文动态精简，**支撑数小时不间断长时序编程任务**。
- **五层递进式安全权限拦截**：构建命令拦截、路径沙箱、规则引擎、权限模式、人工确认五级防护链路，任一环节拦截即可终止操作，保障**Agent 全自动执行安全可控**。
- **多 Agent 并行协作架构**：复杂任务拆分多智能体并行处理；基于 GitWorktree 实现文件级隔离，规避代码编辑冲突；由协调 Agent 负责任务调度与结果汇总，**突破单智能体上下文上限**，大型任务处理效率显著提升。
  
## 能做什么

- 在终端中进行交互式对话，或使用 `-p` 执行一次性任务
- 读取、搜索、编辑项目文件，查看差异并执行开发命令
- 通过多轮模型调用和工具调用完成连续任务
- 使用 `default`、`accept-edits`、`plan`、`bypass` 权限模式控制敏感操作
- 接入 OpenAI-compatible 和 Anthropic Messages API
- 通过命令行 MCP 服务扩展工具能力
- 加载 Skills、Hooks、项目记忆和会话记录
- 创建子 Agent，并通过任务、消息和团队机制协作
- 使用 Git worktree 隔离并行任务
- 自动处理上下文预算、工具结果持久化和会话压缩
- 以终端 UI、远程 WebSocket 服务或 `stream-json` 输出运行

## 架构概览

一次典型任务大致经过下面的循环：

```text
用户输入
   │
   ▼
ConversationManager ── 项目指令 / 记忆 / 会话历史
   │
   ▼
Agent Loop ── 模型流式响应
   │                 │
   │                 ├─ 文本 / 思考事件
   │                 └─ Tool Use
   ▼
PermissionChecker ── 规则、危险命令、路径沙箱、权限模式
   │
   ▼
Tool Registry ── 文件 / Shell / Git / Agent / Team / MCP
   │
   ▼
工具结果 ── 上下文预算 / 持久化 / 压缩 ── 回到 Agent Loop
```

核心实现集中在 `YX__package_tmp/`（Python 包名为 `yx`）。其中：

| 目录 | 作用 |
| --- | --- |
| `agent.py` | Agent 主循环、流式事件、工具调用和停止条件 |
| `client.py` | 模型 Provider 客户端与上下文窗口解析 |
| `tools/` | 文件、命令、Agent、Team 等工具 |
| `permissions/` | 权限模式、规则引擎、危险命令检测和路径沙箱 |
| `context/`、`conversation.py` | 上下文预算、工具结果持久化和会话压缩 |
| `agents/` | 子 Agent 加载、任务管理和执行追踪 |
| `teams/` | 多 Agent 团队、任务和消息协作 |
| `mcp/` | MCP 客户端和工具适配 |
| `memory/`、`skills/`、`hooks/` | 记忆、技能加载和生命周期钩子 |
| `worktree/` | Git worktree 创建、隔离和清理 |
| `app.py`、`remote.py` | 终端 UI 和远程服务入口 |

## 快速开始

### 环境要求

- Python 3.11+
- [uv](https://docs.astral.sh/uv/)
- 一个兼容的模型服务 API Key
- Windows、macOS 或 Linux

### 安装和配置

```powershell
uv sync
Copy-Item .env.example .env
New-Item -ItemType Directory -Force .yx
Copy-Item .yx/config.yaml.example .yx/config.yaml
```

在 `.env` 中填写本地密钥，在 `.yx/config.yaml` 中选择 Provider。密钥应通过环境变量引用：

```yaml
providers:
  - name: openai-compatible
    protocol: openai-compat
    base_url: https://api.example.com/v1
    api_key: "${OPENAI_API_KEY}"
    model: example-model
    thinking: false
```

也可以直接使用 Anthropic 配置模板中的 `protocol: anthropic`。`.env`、`.yx/config.yaml`、会话、记忆和日志都属于本地运行数据，请勿提交真实密钥或敏感内容。

### 启动

```powershell
# 交互式终端
uv run yx

# Windows 启动脚本
.\start.ps1

# 一次性任务
uv run yx -p "检查当前项目的测试失败原因，并给出修复建议"

# 规划模式
uv run yx --mode plan

# NDJSON 事件流
uv run yx -p "检查项目" --output-format stream-json

# 远程 WebSocket 服务，默认监听 localhost:18888
uv run yx --remote
```

`-p` 模式会自动处理权限请求，适合脚本化调用；涉及真实文件或命令时，仍应审阅模型输出和变更结果。

## 权限模式

| 模式 | 行为 |
| --- | --- |
| `default` | 敏感操作执行前请求确认 |
| `accept-edits` | 自动允许文件编辑，其他敏感操作仍需确认 |
| `plan` | 只分析和制定计划，不直接修改项目 |
| `bypass` | 跳过权限确认，仅建议在隔离环境中使用 |

权限检查由规则引擎、危险命令检测器和路径沙箱共同参与。权限控制是安全边界的一部分，但不是对任意代码执行风险的保证；请在可信项目目录中运行，并人工确认高风险操作。

## MCP、Skills 与 Hooks

在 `.yx/config.yaml` 中配置 MCP 服务，例如：

```yaml
mcp_servers:
  - name: context7
    command: npx
    args: ["-y", "@upstash/context7-mcp"]
```

项目级 Skills 位于 `.yx/skills/`，Hooks 可在配置中声明，用于在 Agent 生命周期或工具调用前后接入额外逻辑。相关配置中的 Token、Header 和环境变量同样不要提交到仓库。

## 测试与开发

测试覆盖 Agent 循环、工具调用、权限、上下文压缩、会话、记忆、MCP、Hooks、子 Agent、团队和 worktree 等模块。

```powershell
uv run pytest
uv run python -m compileall YX__package_tmp
uv run yx --help
```

## 项目结构

```text
YX/
├── YX__package_tmp/      # 当前 Python 实现包（包名 yx）
├── tests/                 # 自动化测试
├── .yx/                   # 本地配置、会话、记忆、Skills 和日志
├── pyproject.toml         # 项目元数据、依赖和 yx 命令入口
├── uv.lock                # 依赖锁定
└── start.ps1              # Windows 启动脚本
```

## 学习路线

推荐按以下顺序阅读源码：

1. 从 `__main__.py` 了解命令行入口和运行模式
2. 阅读 `agent.py`，理解模型响应、工具调用和 Agent Loop
3. 阅读 `tools/`，理解模型如何影响真实项目
4. 阅读 `permissions/`，理解执行前的安全检查
5. 阅读 `context/` 和 `conversation.py`，理解长会话管理
6. 最后阅读 `agents/`、`teams/`、`mcp/` 和 `worktree/`，理解能力扩展与协作

## 贡献

欢迎通过 Issue 讨论架构、实现细节和实验结果，或提交 Pull Request。提交前请运行测试，并确认没有包含 `.env`、API Key、会话数据、记忆文件、日志或其他本地敏感信息。

## 免责声明

这是学习型项目。模型可能生成错误的解释、代码或命令；执行前请人工检查，重要数据请提前备份。作者不对因使用本项目造成的数据丢失、费用、系统损坏或其他损失负责。
