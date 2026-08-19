#!/usr/bin/env bash
set -Eeuo pipefail

export GIT_TERMINAL_PROMPT=0
export GIT_LFS_SKIP_SMUDGE=1
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

git config --global advice.detachedHead false
git config --global http.version HTTP/1.1
git config --global core.longpaths true

DATE="2026-08-19"
ROOT_NAME="俱乐部训练监控开源项目参考包_${DATE}"
WORK_DIR="${RUNNER_TEMP}/source-bundle-work"
ROOT_DIR="${WORK_DIR}/${ROOT_NAME}"
PROJECTS_DIR="${ROOT_DIR}/projects"
OUT_DIR="${GITHUB_WORKSPACE}/dist"
SNAPSHOT_TSV="${WORK_DIR}/snapshots.tsv"

rm -rf "${WORK_DIR}" "${OUT_DIR}"
mkdir -p "${PROJECTS_DIR}" "${ROOT_DIR}/LICENSE_INDEX" "${ROOT_DIR}/metadata" "${OUT_DIR}"
: > "${SNAPSHOT_TSV}"

clone_one() {
  local order="$1"
  local slug="$2"
  local url="$3"
  local branch="$4"
  local license="$5"
  local recurse="${6:-no}"
  local target="${PROJECTS_DIR}/${order}-${slug}"
  local ok=0

  echo "::group::Cloning ${url} (${branch})"
  for attempt in 1 2 3; do
    rm -rf "${target}"
    if [[ "${recurse}" == "yes" ]]; then
      if timeout 25m git clone --depth 1 --single-branch --branch "${branch}" --filter=blob:none --recurse-submodules --shallow-submodules "${url}" "${target}"; then
        ok=1
        break
      fi
      echo "Recursive clone attempt ${attempt} failed; retrying." >&2
    else
      if timeout 25m git clone --depth 1 --single-branch --branch "${branch}" --filter=blob:none "${url}" "${target}"; then
        ok=1
        break
      fi
      echo "Clone attempt ${attempt} failed; retrying." >&2
    fi
    sleep $((attempt * 5))
  done

  if [[ "${ok}" -ne 1 && "${recurse}" == "yes" ]]; then
    echo "Recursive clone failed; falling back to the parent repository snapshot." >&2
    for attempt in 1 2 3; do
      rm -rf "${target}"
      if timeout 25m git clone --depth 1 --single-branch --branch "${branch}" --filter=blob:none "${url}" "${target}"; then
        ok=1
        printf '%s\n' "Submodule materialization failed during packaging. The parent repository source is complete; run 'git submodule update --init --recursive' from a fresh clone to retrieve submodules." > "${target}/SUBMODULE_MATERIALIZATION_NOTE.txt"
        break
      fi
      sleep $((attempt * 5))
    done
  fi

  if [[ "${ok}" -ne 1 ]]; then
    echo "Unable to clone ${url}" >&2
    exit 1
  fi

  local commit
  commit="$(git -C "${target}" rev-parse HEAD)"
  git -C "${target}" submodule status --recursive > "${target}/SOURCE_SUBMODULE_STATUS.txt" 2>/dev/null || true
  printf '%s\n' "Repository: ${url}" "Branch: ${branch}" "Commit: ${commit}" "Snapshot date: ${DATE}" "Declared license: ${license}" > "${target}/SOURCE_SNAPSHOT_INFO.txt"

  # Preserve source files but remove VCS metadata and any accidental credentials.
  find "${target}" -type d -name .git -prune -exec rm -rf {} + 2>/dev/null || true
  find "${target}" -type f -name .git -delete 2>/dev/null || true
  find "${target}" -type f \( -name '.env' -o -name '*.pem' -o -name '*.key' \) -delete 2>/dev/null || true

  local file_count byte_count
  file_count="$(find "${target}" -type f | wc -l | tr -d ' ')"
  byte_count="$(du -sb "${target}" | awk '{print $1}')"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "${order}" "${slug}" "${url}" "${branch}" "${commit}" "${license}" "${file_count}" "${byte_count}" >> "${SNAPSHOT_TSV}"

  mkdir -p "${ROOT_DIR}/LICENSE_INDEX/${order}-${slug}"
  while IFS= read -r -d '' license_file; do
    cp "${license_file}" "${ROOT_DIR}/LICENSE_INDEX/${order}-${slug}/$(basename "${license_file}")"
  done < <(find "${target}" -maxdepth 3 -type f \( -iname 'LICENSE' -o -iname 'LICENSE.*' -o -iname 'COPYING' -o -iname 'COPYING.*' -o -iname 'NOTICE' -o -iname 'NOTICE.*' \) -print0)
  echo "::endgroup::"
}

clone_one "01" "praxys" "https://github.com/praxys-run/praxys.git" "main" "MIT" "yes"
clone_one "02" "RowLab-oarbit" "https://github.com/samwduncan/RowLab.git" "master" "MIT" "no"
clone_one "03" "REGmon" "https://github.com/REGmon-project/regmon.git" "main" "MIT" "no"
clone_one "04" "OpenAthlete" "https://github.com/openathleteorg/openathlete.git" "main" "AGPL-3.0" "no"
clone_one "05" "wger" "https://github.com/wger-project/wger.git" "master" "AGPL-3.0-or-later" "no"
clone_one "06" "FitTrackee" "https://github.com/SamR1/FitTrackee.git" "main" "AGPL-3.0" "no"
clone_one "07" "Endurain" "https://github.com/endurain-project/endurain.git" "master" "AGPL-3.0" "no"
clone_one "08" "360-data-athlete" "https://github.com/airbone42/360-data-athlete.git" "main" "MIT" "no"

cat > "${ROOT_DIR}/README_FIRST.md" <<'MD'
# 俱乐部专项训练监控开源项目参考包

本包收录 8 个公开 GitHub 项目在 **2026-08-19** 获取的默认分支源码快照，并附有逐项目复用、验证、淘汰和许可证说明。

## 建议阅读顺序

1. `开源项目复用与验证指南.md`
2. `metadata/SOURCE_SNAPSHOTS.json`
3. `LICENSE_INDEX/`
4. `projects/01-praxys/`
5. `projects/02-RowLab-oarbit/`
6. 其余项目按指南中的验证矩阵阅读

## 重要说明

- 这些目录是浅层源码快照，不包含完整 Git 历史。
- 未安装 `node_modules`、Python 虚拟环境、构建产物或数据库。
- 未执行这些第三方项目的代码；在运行前应进行依赖、许可证、Secret、容器和供应链审计。
- Git LFS 大文件若存在，包内可能保留指针文件而非 LFS 二进制对象；这不影响对源码架构的审阅。
- `Praxys` 含 Git 子模块；打包器优先递归获取。具体状态见项目内 `SOURCE_SUBMODULE_STATUS.txt`。
- 本包用于技术调研和原型验证，不代表第三方项目已经达到你的生产安全、数据保护或运动科学要求。
MD

cat > "${ROOT_DIR}/开源项目复用与验证指南.md" <<'MD'
# 俱乐部专项训练监控系统：开源项目复用与验证指南

> 快照日期：2026-08-19  
> 目标系统：教练制定和调整计划、运动员执行与反馈、系统监控个体状态、教练处置异常、俱乐部查看训练过程和专项进步。  
> 明确不在范围：财务、合同、营销、会员续费、通用场馆 ERP。

---

## 1. 核心判断

GitHub 上没有一个项目能够直接覆盖以下完整闭环：

```text
训练目标与能力基线
→ 训练组基础计划
→ 运动员个体覆盖
→ 实际执行与 Session-RPE
→ 睡眠、疲劳、疼痛和训练意愿
→ 个体基线与多证据异常识别
→ 教练干预、复查和关闭
→ 标准化复测与真实进步判断
→ 教练组和俱乐部训练质量总览
```

因此，正确策略不是把 8 个仓库合并，而是：

1. 只选 **一个工程主干**；
2. 从其他项目抽取领域模型、数据合同、交互模式和验证方法；
3. 用垂直业务切片证明主干是否值得继续改造；
4. 专项训练逻辑、异常处置和进步验证仍由我们自主建设。

### 推荐主线

- **Python / FastAPI / 微信小程序路线：以 Praxys 为主干。**
- **全 TypeScript / React / Prisma 路线：以 RowLab（oarbit）为主干。**
- **REGmon 主要用于监控产品、表单和看板验证，不建议把当前 V1 作为长期工程底座。**

---

## 2. 项目总览与推荐等级

| 编号 | 项目 | 主要价值 | 最适合承担 | 不应直接承担 | 主干建议 |
|---|---|---|---|---|---|
| 01 | Praxys | 运动数据接入、恢复和负荷分析、Web、微信小程序、科学指标 | Python 工程主干、分析层、Provider 层 | 现成俱乐部多人教练域 | **首选主干** |
| 02 | RowLab / oarbit | Team—Coach—Athlete、计划分配、完成记录、实时协作 | 组织模型、计划域；或 TS 工程主干 | 通用状态监控和专项进步算法 | **次选主干** |
| 03 | REGmon | 可配置监控表单、Dashboard、运动员—教练数据采集 | 产品验证、状态问卷、监控视图 | 长期现代化主干 | 产品参考 |
| 04 | OpenAthlete | 训练负荷、耐力活动、设备接入、现代 TS 栈 | 负荷算法与集成参考 | 闭源商业主干、完整俱乐部域 | 参考 |
| 05 | wger | 动作库、训练方案、日志、自动进阶、REST API、国际化 | 动作/训练处方子域 | 专项状态监控和异常干预 | 模块参考 |
| 06 | FitTrackee | GPX/FIT 活动、地图、时间序列和活动导入 | 户外数据导入与可视化验证 | 教练多人管理 | 模块参考 |
| 07 | Endurain | 自托管活动平台、FastAPI、设备和文件导入 | Provider、导入任务和活动时间线 | 完整训练决策闭环 | 模块参考 |
| 08 | 360 Data Athlete | 多 Agent 计划、个人基线、机械/语义双重验证 | AI 决策流和计划校验器 | 生产 Web 主干 | 算法参考 |

---

## 3. 跨项目能力矩阵

符号：`◎` 强参考，`○` 可参考，`△` 仅局部，`—` 基本不适用。

| 能力 | Praxys | RowLab | REGmon | OpenAthlete | wger | FitTrackee | Endurain | 360DA |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 多用户认证与数据隔离 | ◎ | ◎ | ○ | ○ | ◎ | ○ | ○ | — |
| 俱乐部/队伍/教练/运动员 | △ | ◎ | ○ | △ | △ | — | — | — |
| 组计划与个体分配 | ○ | ◎ | △ | ○ | ○ | — | △ | △ |
| 实际执行与完成度 | ◎ | ◎ | ○ | ◎ | ◎ | ◎ | ◎ | ○ |
| 状态/恢复数据 | ◎ | △ | ◎ | ○ | △ | △ | ○ | ◎ |
| 训练负荷和趋势 | ◎ | ◎ | ○ | ◎ | △ | ○ | ◎ | ◎ |
| 个体基线 | ◎ | △ | ○ | ○ | — | △ | ○ | ◎ |
| 异常队列与教练干预 | △ | △ | ○ | △ | — | — | — | ○ |
| 测试协议和进步验证 | ○ | ◎（赛艇） | ○ | ○ | △ | △ | ○ | ○ |
| 外部设备/文件导入 | ◎ | ◎ | △ | ◎ | ○ | ◎ | ◎ | ◎ |
| 微信小程序 | ◎ | — | — | — | — | — | — | — |
| AI 计划和解释 | ◎ | ◎ | — | ○ | — | — | △ | ◎ |
| 可配置监控表单 | △ | △ | ◎ | △ | △ | — | — | ○ |
| 商业闭源许可证友好度 | ◎ | ◎ | ◎ | △ | △ | △ | △ | ◎ |

---

# 4. 逐项目复用与验证

## 4.1 Praxys

目录：`projects/01-praxys/`  
角色：**推荐的 Python 工程主干**。

### 可以复用的部分

1. `analysis/metrics.py`：将指标计算写成尽量无 I/O 的纯函数，可作为专项算法层模板。
2. `analysis/providers/` 与同步脚本：设备或平台适配器、标准化、去重、跨来源合并。
3. `api/`：FastAPI 路由、JWT、多用户、后台同步、计划投递边界。
4. `db/`：SQLAlchemy 模型、连接信息、凭据加密、迁移模式。
5. `web/`：React Dashboard、训练/恢复/目标页面。
6. `miniapp/`：Taro + React 微信小程序，可作为运动员移动端起点。
7. `data/science/`、证据注册和决策记录：适合承载训练理论、参数来源、适用边界和版本。
8. `tests/`：设备同步、科学指标、时区、认证、计划和数据库迁移的测试范式。

### 用它验证什么

- Garmin、COROS、Strava、Oura 等来源能否映射进统一 `MetricObservation`。
- 同一训练活动来自多平台时，匹配、去重和补列是否可靠。
- 纯函数分析层能否加入短跑计时、CMJ、F–V、RFD、SSC、OpenSim 派生指标。
- Web 与微信小程序是否能共享同一 API 和指标口径。
- 计划版本、投递状态和提供商冲突处理是否适合我们的训练计划版本管理。

### 必须新增

```text
Club
CoachProfile
AthleteProfile
TrainingGroup
CoachAthleteAssignment
GroupSessionPlan
AthletePlanOverride
ReadinessCheck
PainReport
Alert
CoachIntervention
FollowUp
AssessmentProtocol
AssessmentResult
```

### 不应直接照搬

- 以耐力项目 CTL/ATL/TSB 为中心的产品结构；短跑和力量项目不能被单一负荷模型统治。
- 单运动员自助使用假设。
- 尚未针对中国俱乐部验证的设备认证、数据合规和通知链路。

### 验证通过标准

Praxys 只有在以下垂直切片能自然实现时，才值得成为主干：

```text
一个俱乐部 → 一名教练 → 一个训练组 → 五名运动员
→ 下发组计划 → 一人个体覆盖
→ 运动员提交完成、RPE、疼痛
→ 触发异常 → 教练干预 → 俱乐部总览更新
```

---

## 4.2 RowLab / oarbit

目录：`projects/02-RowLab-oarbit/`  
角色：**最接近目标领域模型的项目；也是 TypeScript 路线主干候选。**

### 可以复用的部分

1. `prisma/schema.prisma` 中的 `User`、`Team`、`TeamMember`、`Athlete` 关系。
2. `Athlete.userId` 可为空的“教练先建档、运动员后绑定账号”模式。
3. 训练计划、Workout Assignment、Workout Completion、Compliance。
4. React 教练工作区、运动员列表、训练计划页面。
5. Express 服务层、Prisma/PostgreSQL、JWT/Refresh Token。
6. Socket.io 实时协作、操作历史和多教练同步思路。
7. FIT、Concept2、Strava、遥测导入和后台同步测试。

### 用它验证什么

- 一个教练管理多个训练组的查询边界和页面性能。
- 组计划分配到运动员后，个体覆盖如何保存而不复制整份计划。
- 无登录账号的运动员档案如何创建、邀请和后绑定。
- Team 级数据隔离是否能防止跨俱乐部泄漏。
- 计划完成度、训练日历和实时协作是否适合训练现场。

### 建议重点审阅路径

```text
prisma/schema.prisma
server/routes/
server/services/
src/
src-v4/
docs/
server/tests/
src/test/
```

### 必须删除或隔离成插件

- Shell、Oar、Boat、Lineup、Seat Racing、Regatta、Rigging。
- 赛艇专属排名和阵容优化。
- 与目标系统无关的 Fleet、Recruit、NCAA 合规等领域。

### 必须新增

- 睡眠、疲劳、疼痛、训练意愿、Session-RPE。
- 个体滚动基线和数据质量。
- 多证据异常、教练今日关注队列。
- 干预、复查、关闭依据。
- 测试协议一致性、典型误差和真实进步判定。
- 短跑专项指标与生物力学数据合同。

### 风险

该仓库功能面很大，不能因为 README 完整就假设生产成熟。必须实际执行：

```bash
npm ci
npm run typecheck
npm run lint
npm run test:run
npm run build
```

并对数据库迁移、权限和公开接口做单独安全审计。

---

## 4.3 REGmon

目录：`projects/03-REGmon/`  
角色：**最接近状态监控产品定义，但当前 V1 不宜直接作为长期工程主干。**

### 可以复用的部分

- 可配置数据采集表单。
- 运动员、教练和工作人员之间的数据可见关系。
- Dashboard、分析模板和个体图形反馈。
- 运动实践与研究场景共用的数据采集模型。
- Docker 化安装和样例配置。

### 用它验证什么

1. 运动员每天最少需要回答哪些字段。
2. 正常问卷和异常追问如何动态分层。
3. 教练如何创建监控模板并分配给训练组。
4. 运动员个体图表、组热图和俱乐部聚合图分别应展示什么。
5. 自定义表单如何映射为统一指标，而不是产生不可比较的自由文本孤岛。

### 不建议直接长期使用的原因

- 当前公开 V1 主要是 PHP、MySQL、jQuery、Bootstrap 3 和较旧前端组件。
- 测试自动化不足。
- 官方已经声明正在进行完整前后端重建，V2 将替换 V1。

### 正确用法

部署一个隔离实例做 **产品验证和用户访谈**，记录教练真正使用的表单、图表和筛选逻辑；验证后在主干系统内重新实现，而不是长期维护两套技术栈。

---

## 4.4 OpenAthlete

目录：`projects/04-OpenAthlete/`  
角色：现代耐力训练平台和集成参考。

### 可以复用或验证的部分

- React、NestJS、Prisma、PostgreSQL 的现代 Monorepo 组织。
- 活动、负荷、Fitness/Fatigue/Form 趋势。
- Garmin、Strava、Suunto、Polar、COROS 等接入思路。
- 自托管、数据导出、透明算法和 AI 辅助边界。
- 训练活动与长期趋势可视化。

### 不适合直接承担

- 教练多人管理和俱乐部训练质量总览。
- 短跑、力量、技术、生物力学完整模型。
- 闭源商业 SaaS 的核心代码主干。

### 许可证风险

该项目为 AGPL-3.0。网络提供修改后的服务通常会触发向服务用户提供对应源码的义务。可用于研究、对照和合规开源方案，但在复制代码进入闭源商业主干前必须完成专业许可证审查。

---

## 4.5 wger

目录：`projects/05-wger/`  
角色：成熟的动作库、训练方案、训练日志和进阶规则参考。

### 可以复用或验证的部分

- Exercise、Routine、Set、Repetition、Weight、Measurement 等训练对象。
- 训练计划、训练日志、自动负重进阶。
- REST API、Django 权限、多用户和国际化。
- 动作 Wiki、动作媒体、移动端记录流程。
- Docker、自托管、翻译和成熟开源协作方式。

### 用它验证什么

- 动作库如何支持版本、多语言、别名、器械、肌群和技术说明。
- 训练模板如何生成单次处方，实际执行如何记录差异。
- 力量训练的组、次、重量、速度、RPE/RIR 应如何建模。
- 自动进阶规则应如何与教练人工覆盖并存。

### 不应直接承担

- 专项状态监控。
- 多证据异常和教练干预。
- 速度、跳跃、F–V、生物力学和专项技术评价。

### 许可证风险

应用代码为 AGPL-3.0-or-later。闭源商业主干默认不采用其代码；可以借鉴模型并在完成独立设计后重新实现。

---

## 4.6 FitTrackee

目录：`projects/06-FitTrackee/`  
角色：户外活动数据、轨迹和时间序列参考。

### 可以复用或验证的部分

- GPX 活动导入、轨迹、地图、海拔和分段。
- Flask API 与 Vue 3 前端分离。
- 大量活动的筛选、分页、趋势图和隐私设置。
- 自托管活动数据与导入错误处理。

### 用它验证什么

- 跑步、骑行等耐力活动文件如何进入统一活动模型。
- 轨迹和逐段数据是否应该独立于训练计划事务表存储。
- 大型 FIT/GPX 文件解析应使用同步请求还是后台任务。
- 活动删除、重导入、去重和时区处理。

### 限制

- 主要是个人活动追踪，不是教练多人工作流。
- GitHub 仓库是 Codeberg 主仓库的镜像。
- AGPL 许可证不适合未经合规设计直接进入闭源主干。

---

## 4.7 Endurain

目录：`projects/07-Endurain/`  
角色：现代自托管活动平台、Provider 和文件导入参考。

### 可以复用或验证的部分

- FastAPI、SQLAlchemy、Alembic、PostgreSQL。
- Vue 3、TypeScript、Tailwind、shadcn-vue。
- Garmin、Strava 连接和活动同步。
- GPX、TCX、FIT 文件导入。
- 后台任务、容器部署、活动时间线和数据拥有权。

### 用它验证什么

- Provider 接口能否统一 OAuth、账号凭据、同步游标、重试和错误状态。
- 活动文件解析与业务事务如何隔离。
- 设备连接健康状态如何被教练或管理员看见。
- 自托管部署、备份和升级流程。

### 限制

- 仍然以个人活动追踪为中心。
- 没有完整教练异常队列、干预和俱乐部进步总览。
- AGPL 许可证需要单独评估。

---

## 4.8 360 Data Athlete

目录：`projects/08-360-data-athlete/`  
角色：**AI 训练决策和校验工作流参考，不是 Web 产品底座。**

### 可以复用的思想

- 上下文收集 → 总计划器 → 专项 Agent → 跨训练复核 → 机械校验 → 语义校验 → 人工接受 → 发布。
- HRV 与个人正常范围比较，而不是简单“越高越好”。
- 伤病锁、训练禁忌、训练量上限和动作进阶历史。
- 规则检查与 LLM 语义审查相互独立。
- 计划发布前后各执行一次确定性校验。
- 将运动员反馈写回长期上下文，形成下一次决策输入。

### 用它验证什么

1. AI 是否能从结构化状态、计划、历史和限制中生成可追溯草案。
2. 确定性规则是否能阻断明显错误计划。
3. 语义校验器是否能发现规则未覆盖的冲突。
4. 教练拒绝或修改建议后，系统如何保存采纳状态和原因。
5. 同一输入、算法版本和模型版本能否重放。

### 不能直接采用

- 它依赖 Claude Code、Intervals.icu 和文件化配置，不是完整 SaaS 服务。
- 项目明确为实验性质，不能把其医学或伤病相关输出当作生产决策。
- 多 Agent 会增加成本和不确定性，MVP 应先使用规则引擎和单一解释层。

---

# 5. 推荐的组合架构

## 5.1 代码层只保留一个主仓库

### 推荐方案 A：Praxys 主干

```text
Praxys
├── 保留：FastAPI、React、Taro、SQLAlchemy、Provider、分析层、测试
├── 新增：organization
├── 新增：coaching
├── 新增：planning
├── 新增：execution
├── 新增：monitoring
├── 新增：alerts
├── 新增：interventions
├── 新增：assessment
└── 新增：club_analytics
```

领域模型参考 RowLab；表单和 Dashboard 参考 REGmon；动作库参考 wger；活动导入参考 FitTrackee/Endurain/OpenAthlete；AI 校验参考 360 Data Athlete。

### 推荐方案 B：RowLab 主干

适用于团队决定全 TypeScript：

```text
RowLab
├── 保留：Team、TeamMember、Athlete、计划、分配、完成、Prisma、React
├── 删除/插件化：赛艇船只、阵容、座位赛、赛艇赛事
├── 新增：readiness、wellness、pain、monitoring
├── 新增：alert、intervention、follow-up
├── 新增：assessment protocol、reliability、progress
└── 新增：专项指标和数据接入
```

## 5.2 不推荐的做法

- 不要将 8 个数据库直接合并。
- 不要同时维护 FastAPI、Django、Flask、PHP、NestJS、Express 五套后端。
- 不要复制 AGPL 代码进入闭源主干后再处理许可证。
- 不要先做所有设备接入，再验证教练是否使用核心闭环。
- 不要用一个“综合状态分”掩盖维度冲突和数据缺失。

---

# 6. 第一条垂直切片验证

无论选择哪个主干，第一阶段只实现以下流程：

```text
1. 创建俱乐部
2. 创建教练
3. 创建训练组
4. 添加 5 名运动员，其中 2 名尚无登录账号
5. 教练创建一份组训练计划
6. 对 1 名运动员进行个体覆盖
7. 运动员提交实际组次、完成度、Session-RPE 和疼痛
8. 系统根据个人历史和规则产生一条异常
9. 教练查看证据，修改下一训练并记录原因
10. 设置复查日期并关闭干预
11. 俱乐部训练管理端看到组状态、未处理异常和训练完成情况
```

## 6.1 验收指标

- 教练不需要逐个打开所有运动员才能发现异常。
- 一份组计划可批量下发，个体覆盖不复制全部内容。
- 计划、实际执行和教练修改均有版本和时间线。
- 运动员正常反馈在约 30–60 秒内完成。
- 异常必须包含证据、责任人、处理动作、复查和关闭依据。
- 俱乐部总览由日常数据自动产生，不要求教练重复填报。
- 所有核心查询严格按俱乐部、训练组和教练关系隔离。

## 6.2 对候选主干的淘汰条件

出现下列任一情况时，应停止在该主干上继续堆功能：

- 为了支持 Club/Coach/Athlete 必须重写认证和全部业务表。
- 计划模型不能表达组计划与个体覆盖。
- 一个训练执行记录无法关联计划版本。
- 无法可靠区分原始测量、标准化数据和派生指标。
- 数据隔离依靠前端隐藏，而不是服务端约束。
- 新增状态监控会与现有活动模型严重耦合。
- 测试无法覆盖核心垂直切片。

---

# 7. 建议的数据边界

```text
Identity
Organization
Athlete Profile
Training Goal
Training Cycle
Session Template
Session Plan
Athlete Override
Session Execution
Readiness Check
Training Response
Metric Observation
Assessment Protocol
Assessment Result
Alert
Coach Intervention
Follow-up
Club Training Snapshot
```

统一测量合同至少包含：

```text
tenant_id
athlete_id
metric_code
value
unit
event_time
source_type
source_id
protocol_id
session_id
context
quality_flag
raw_or_derived
processing_version
created_by
```

任何外部项目的指标表若不能映射到这一合同，就只作为来源数据保留，不应直接驱动警报。

---

# 8. 许可证决策

| 项目 | 声明许可证 | 闭源商业主干建议 |
|---|---|---|
| Praxys | MIT | 推荐，保留版权和许可证声明 |
| RowLab | MIT | 推荐，保留版权和许可证声明 |
| REGmon | MIT | 法律上较宽松；工程上不建议 V1 长期主干 |
| 360 Data Athlete | MIT | 可研究和改造，仍需审计质量与第三方依赖 |
| OpenAthlete | AGPL-3.0 | 默认不并入闭源主干 |
| wger | AGPL-3.0-or-later | 默认不并入闭源主干 |
| FitTrackee | AGPL-3.0 | 默认不并入闭源主干 |
| Endurain | AGPL-3.0 | 默认不并入闭源主干 |

### 执行规则

1. 每个项目目录中的原始许可证文件必须保留。
2. 建立第三方组件清单，记录版本、提交、许可证和修改。
3. MIT 代码进入产品时保留版权和许可文本。
4. AGPL 项目优先作为阅读、对照和独立部署实验，不复制到闭源主干。
5. 第三方依赖仍可能采用不同许可证，不能只看仓库顶层 LICENSE。
6. 本说明不是法律意见，正式商业发布前应进行软件许可证合规审查。

---

# 9. 安全和工程审计清单

在运行任何项目之前：

- 检查 `.env.example`，不得使用仓库示例密钥。
- 搜描硬编码 Secret、Token、密码和私钥。
- 运行依赖锁文件和许可证扫描。
- 审查 Dockerfile、Compose、启动脚本和 CI 工作流。
- 在隔离容器和测试数据库中启动。
- 禁止直接连接真实运动员账号和生产设备。
- 运行数据库迁移回滚测试。
- 验证跨租户访问、越权修改和 IDOR。
- 验证文件上传类型、路径穿越、压缩炸弹和大文件限制。
- 验证第三方 OAuth Token 加密、刷新、撤销和日志脱敏。
- 对 AI 输入实施最小必要、去标识化和可追溯版本记录。

建议工具类别：

```text
SAST
Secret scanning
Dependency vulnerability scanning
SBOM generation
License scanning
Container scanning
DAST
Database migration tests
Tenant-isolation integration tests
```

---

# 10. 最终选型建议

## 当前最优方案

```text
工程主干：Praxys
团队与教练领域：参考 RowLab 重新实现
状态采集与看板：参考 REGmon 重新实现
动作与力量训练模型：参考 wger 独立设计
活动与设备导入：对照 OpenAthlete / FitTrackee / Endurain
AI 计划校验：参考 360 Data Athlete，但规则优先、教练最终确认
```

这条路线复用了真正昂贵的工程底层，同时避免被耐力单用户模型、赛艇领域、旧 PHP 技术栈或 AGPL 商业义务绑死。

最终产品的不可替代部分仍然是：

```text
组计划 + 个体覆盖
计划 + 实际执行
状态 + 个人基线
多证据异常 + 教练处置
干预 + 后续验证
专项评估 + 真实进步判断
教练组 + 俱乐部训练质量总览
```

---

# 11. 本包中的辅助文件

- `metadata/SOURCE_SNAPSHOTS.json`：每个仓库的分支、提交、许可证、文件数和体积。
- `metadata/SOURCE_SNAPSHOTS.tsv`：便于快速筛选和导入表格。
- `metadata/MANIFEST.txt`：包内完整文件清单。
- `metadata/SHA256SUMS.txt`：关键文档与快照信息校验值。
- `LICENSE_INDEX/`：从各仓库抽取的顶层/近顶层许可证和通知文件。
- `重新下载这些项目.sh`：在可联网 Linux/macOS 环境中重建源码快照。
MD

cat > "${ROOT_DIR}/重新下载这些项目.sh" <<'SH'
#!/usr/bin/env bash
set -Eeuo pipefail
export GIT_LFS_SKIP_SMUDGE=1
mkdir -p projects
clone() { local dir="$1" repo="$2" branch="$3"; rm -rf "projects/$dir"; git clone --depth 1 --single-branch --branch "$branch" "$repo" "projects/$dir"; }
clone 01-praxys https://github.com/praxys-run/praxys.git main
clone 02-RowLab-oarbit https://github.com/samwduncan/RowLab.git master
clone 03-REGmon https://github.com/REGmon-project/regmon.git main
clone 04-OpenAthlete https://github.com/openathleteorg/openathlete.git main
clone 05-wger https://github.com/wger-project/wger.git master
clone 06-FitTrackee https://github.com/SamR1/FitTrackee.git main
clone 07-Endurain https://github.com/endurain-project/endurain.git master
clone 08-360-data-athlete https://github.com/airbone42/360-data-athlete.git main
printf '%s\n' '下载完成。运行任何第三方代码前，请先阅读开源项目复用与验证指南.md。'
SH
chmod +x "${ROOT_DIR}/重新下载这些项目.sh"

cp "${SNAPSHOT_TSV}" "${ROOT_DIR}/metadata/SOURCE_SNAPSHOTS.tsv"

python3 - "${SNAPSHOT_TSV}" "${ROOT_DIR}/metadata/SOURCE_SNAPSHOTS.json" <<'PY'
import csv, json, sys
from pathlib import Path
src, out = map(Path, sys.argv[1:])
items = []
with src.open(encoding='utf-8') as f:
    for row in csv.reader(f, delimiter='\t'):
        order, slug, url, branch, commit, license_id, file_count, byte_count = row
        items.append({
            'order': order,
            'directory': f'{order}-{slug}',
            'repository': url.removesuffix('.git'),
            'branch': branch,
            'commit': commit,
            'declared_license': license_id,
            'file_count': int(file_count),
            'byte_count': int(byte_count),
            'snapshot_date': '2026-08-19',
            'history_included': False,
            'git_lfs_objects_included': False,
        })
out.write_text(json.dumps({'schema_version': 1, 'projects': items}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
PY

find "${ROOT_DIR}" -type f -printf '%P\n' | LC_ALL=C sort > "${ROOT_DIR}/metadata/MANIFEST.txt"
(
  cd "${ROOT_DIR}"
  sha256sum README_FIRST.md "开源项目复用与验证指南.md" metadata/SOURCE_SNAPSHOTS.json metadata/SOURCE_SNAPSHOTS.tsv > metadata/SHA256SUMS.txt
)

# Make the final user-facing ZIP. GitHub's artifact ZIP will contain this ZIP as one file.
ZIP_PATH="${OUT_DIR}/${ROOT_NAME}.zip"
(
  cd "${WORK_DIR}"
  zip -q -r -6 "${ZIP_PATH}" "${ROOT_NAME}"
)

python3 - "${ZIP_PATH}" "${ROOT_DIR}" <<'PY'
import sys, zipfile
from pathlib import Path
zip_path, root = map(Path, sys.argv[1:])
with zipfile.ZipFile(zip_path) as z:
    bad = z.testzip()
    if bad:
        raise SystemExit(f'ZIP CRC failure: {bad}')
    names = z.namelist()
    required = [
        'README_FIRST.md',
        '开源项目复用与验证指南.md',
        'metadata/SOURCE_SNAPSHOTS.json',
    ]
    prefix = root.name + '/'
    missing = [p for p in required if prefix + p not in names]
    project_dirs = {n.split('/')[1] for n in names if n.startswith(prefix + 'projects/') and len(n.split('/')) > 2}
    if missing:
        raise SystemExit(f'Missing files: {missing}')
    if len(project_dirs) != 8:
        raise SystemExit(f'Expected 8 project directories, found {len(project_dirs)}: {sorted(project_dirs)}')
print(f'ZIP verified: {zip_path} ({zip_path.stat().st_size} bytes), 8 projects')
PY

sha256sum "${ZIP_PATH}" > "${OUT_DIR}/FINAL_ZIP_SHA256.txt"
ls -lh "${ZIP_PATH}"
