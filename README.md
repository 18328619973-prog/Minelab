# MineLab

MineLab 是一个离线优先的 Flutter Android 湿实验工作流原型。它以实验日历为执行中心，将模板、实际实验、步骤时间依赖和记录连接起来。

## Phase 0.1.1

- 默认打开日历日视图，支持日、周、月切换
- 按日期展示实验步骤、项目颜色、当前时间与完成状态
- 空日历不会自动创建演示实验
- 模板库分为生物实验、动物实验和我的模板
- 内置 CCK-8、细胞培养、细胞传代、PCR/qPCR、Western Blot、RNA 提取、免疫荧光等生物实验模板
- 内置动物项目、给药计划、连续观察、采样/取材等可编辑记录框架
- 从模板生成独立实验实例，支持完成步骤、编辑时间和递归顺延依赖步骤
- 使用 SharedPreferences 保存本地 JSON；后续阶段迁移至 SQLite/Drift

动物模板仅用于排期和记录结构，不构成实验方案、安全规范或伦理建议。实际操作应以获批方案、实验室 SOP 与专业人员指导为准。

## 验证

```text
dart analyze lib test
flutter test --no-pub
flutter build apk --debug --no-pub
```
