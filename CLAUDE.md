# ShadowRepo

> Claude Code Skill Suite — 扫描代码仓库，构建结构化语义知识图（feature 树 + spec 图），让人和 AI 都能感知代码背后的 why。
>
> 历经两次 pivot：15k LOC pipeline → MCP server（ADR-024）→ Skill Suite（ADR-026）。

## 产品形态

一组 Claude Code Skills + HTML Dashboard。Skills 从代码提取语义知识写入 `.shadowrepo/` JSON，Dashboard 读 JSON 渲染给非工程师。

## 铁律

**先读 Spec，再写代码。** 详细 spec 在 `spec/` 目录。从 `spec/Meta.md` 开始导航。

## 开始工作

1. 读 `spec/Meta.md`（项目全貌路由）
2. 读 `spec/Core/Regulation.md`（开发硬约束）
3. 读 `spec/Progress/LATEST.md`（最近进展）
4. 读 `spec/Todo.md`（当前工作计划）
5. 按 Meta.md 的 Context Injection Guide 加载任务相关上下文

## 快速参考

| 路径 | 内容 |
|------|------|
| spec/Meta.md | 项目全貌路由 |
| spec/Core/Product.md | 产品定义 + 五个 skill 场景 |
| spec/Core/Technical.md | 技术栈 + 项目结构 |
| spec/Core/Regulation.md | 开发硬约束 |
| spec/Decisions/ADR-026.md | 当前架构决策（Skill Suite Pivot） |
| spec/Todo.md | 工作计划 + 延期任务 |
| spec/Progress/LATEST.md | 最近进展 |
| skills/ | Skill .md 文件 |
| dashboard/ | HTML 只读可视化 |
| context/ | Parent ShadowRepo（submodule，纯参考） |

## Parent Repo 参考

`context/` 目录是 ShadowRepo 的 git submodule，包含原始 spec、实验代码和历史 ADR。开发时可读取作为上下文，但不 import 任何代码。
