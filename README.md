---
id: kb-readme
scope: shared
project: null
type: playbook
tags: [knowledge-base, ai-agent, workflow, git]
status: stable
updated: 2026-01-05
---

# my-kb — 個人 AI Agent 知識庫（Git First）

這個 repo 是我的個人知識庫（KB），設計目標是能在 Claude Code 裡用 AI Agent 工作流運作：

- **Git 是唯一真相來源（Source of Truth）**：可版本化、可 diff、可回溯、可整理。
- **Agent 不是只回答**：它要能讀 repo、檢索、整合、並把有價值的內容「寫回」成 KB 文件（產生可 review 的變更）。
- **明確分層**：`shared/`（共用知識） vs `projects/`（專案知識），避免混在一起造成檢索誤判與維護成本。

---

## Goals（目標）

1. **快速收集**：先寫再說，不因為格式而拖延（用 `inbox/` 當入口）。
2. **可靠檢索**：Agent 能用 metadata + 檔名 + 內容快速找到正確資料，降低瞎掰機率。
3. **預設沉澱**：每次互動後的有價值產出，都要回寫成 KB 文件。
4. **分層清楚**：專案知識不污染共用知識；共用知識能被多專案引用。
5. **可維護**：可去重、可合併、可標記 deprecated、可建立連結網路。

---

## Non-Goals（不追求）

- 一開始就做到完美治理或企業級搜尋平台。
- 一開始就上向量索引/大型基礎建設（先用 grep + metadata 起飛）。

---

## Language Policy（語言政策）

- **文件內容（段落、敘述、說明）**：中文（預設）
- **frontmatter keys**：只用英文（固定結構，利於機器處理）
- **tags**：只用英文（利於搜尋、過濾、未來工具串接）
- **檔名 / 資料夾**：只用英文（CLI、連結、grep 更穩）
- **程式碼 / 指令 / 設定檔**：英文（原生語境）
- **我對 Agent 下指令、Agent 回覆**：中文（但要保留固定結構章節與 repo path）

---

## Repository Structure（資料夾結構）

- `shared/`
  - `concepts/`  — 原則、概念、方法論、心智模型
  - `playbooks/` — 可重複套用的流程與清單
  - `snippets/`  — 可直接複製貼上的 code/command
  - `templates/` — 文件模板（ADR、runbook、note）
- `projects/`
  - `_index.md`  — 專案列表與導覽
  - `<project>/`
    - `notes/`
    - `runbooks/`
    - `decisions/` — ADR（決策記錄）
    - `logs/`      —（可選）週記/日記/變更紀錄
- `inbox/` — 快速收集入口，定期整理成正式文件
- `glossary/` — 共用名詞表
- `prompts/` — Claude Code prompts（router/worker/reviewer）
- `agents/` — agent 角色規範與工具使用約束
- `indexes/` — 產物（向量索引/快取），不進版控（gitignored）
- `attachments/` — 圖片/匯出檔（可選；大檔可另處理）

---

## Knowledge Classification Rules（共用 vs 專案）

### 什麼該寫到 `shared/`
符合任一條就偏向寫到 `shared/`：
- 跨專案可復用（方法、原則、模板、通用坑）
- 不依賴特定 repo 路徑、環境參數、系統細節
- 更像「抽象版本」或「通用流程」

### 什麼該寫到 `projects/<name>/`
符合任一條就寫到 `projects/<name>/`：
- 依賴特定代碼、特定設定、特定環境（staging/prod）
- 是該專案的部署、排障、操作手冊（runbook）
- 記錄該專案的決策（ADR）、取捨、演進原因

### 如果兩邊都需要
- `shared/` 放抽象作法
- `projects/` 放落地細節（含指令、設定、路徑）
- 兩份文件互相連結（See also / Based on）

---

## Document Metadata（Frontmatter）

所有 KB 文件都要有 YAML frontmatter。

必填欄位：
- `id`: 穩定且唯一的 id（建議 `kb-<topic>` 或 `adr-0001-...`）
- `scope`: `shared` 或 `project`
- `project`: 專案名稱或 `null`
- `type`: `concept|playbook|snippet|note|decision|runbook|glossary`
- `tags`: 英文 tags
- `status`: `draft|stable|deprecated`
- `updated`: `YYYY-MM-DD`

可選欄位：
- `source`: 來源連結或 repo path
- `related`: 關聯 KB ids
- `sensitivity`: `personal|work|private`

---

## Agent Standard Output Format（固定回覆格式）

Agent 回覆一律用以下章節（中文內容、引用 repo path）：

1. **Answer（答案）**
2. **Citations（引用）**：列出使用到的 repo 檔案路徑 + 章節標題
3. **Gaps（缺口）**：KB 目前缺哪些資料導致不確定
4. **Write-back plan（回寫計畫）**：要新增/更新哪些檔案、做什麼變更

---

## Default Workflow（預設工作流）

### Capture（收集）
- 任何想法、草稿先丟到 `inbox/YYYY-MM-DD.md`

### Ask / Draft / Update / Refactor
我對 Agent 下指令會用以下動詞（中文描述內容）：
- `ask:` 只讀問答，必須引用 KB
- `draft:` 產出新文件（新增檔案）
- `update:` 更新既有文件（修改檔案）
- `refactor-kb:` 去重、合併、拆分、補 metadata、提升可讀性

### Write-back（沉澱）
每次有價值的對話結束後：
- 至少新增或更新 1 份 KB 文件
- 補齊 frontmatter
- 產生可 review 的 diff
- commit（訊息簡短、英文即可）

---

## Quality Bar（品質門檻）

- `tags` 不可為空。
- 文件盡量小而聚焦，避免超大型雜燴文件。
- 每份 runbook 必須包含「驗證步驟」。
- deprecated 文件必須連到替代文件。
- 回答必須引用 KB；不允許「看起來合理但 KB 沒有」的內容。

---

## Getting Started（初始化清單）

1. 建立資料夾結構 + `.gitignore`
2. 產生 templates（ADR / runbook / note）
3. 產生 prompts（router / worker / reviewer）
4. 建立 `projects/_index.md`
5. 建立第一份 `inbox/` 並讓 Agent 進行第一次整理
6. 檢查 diff 後 commit
