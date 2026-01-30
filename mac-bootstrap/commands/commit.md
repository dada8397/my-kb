---
description: Generate commit message and commit
---

請執行以下步驟：

1. 執行 `git status` 和 `git diff` 查看變更
2. 分析變更內容，生成符合 Conventional Commits 規範的 commit message
3. 格式：`type(scope): description`
   - type: feat/fix/refactor/docs/test
   - 描述要清楚說明「做了什麼」和「為什麼」
4. 不要包含 co-author 資訊
5. 一律使用英文，簡單述說變更內容，不要包含太多細節
6. 在 commit 完之後，詢問我要不要 push
7. 如果選擇 push，先確保工作目錄乾淨 (先 git stash)，然後 pull 當前 branch，再 push，如果有 stash 再還原 (git stash pop)
