// lib/features/me/pages/privacy_page.dart
//
// 隐私政策（上架必需的静态页，同时是产品承诺）。
//
// 写作原则：**每一句都能被用户独立验证**。
//   · 说"不联网" → manifest 里真的没有 INTERNET 权限，用户能在系统设置里核对；
//   · 说"仅本机" → 库是 SQLCipher 加密，密钥在 Keystore；
//   · 说"可删除" → 应用内能逐条删、卸载即全删。
// 空头承诺是最容易被应用商店与用户同时抓住的地方，所以这里不做泛泛表述。
//
// 页面是纯静态文本，不读任何 Provider，也不采集任何信息。

import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('隐私政策'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.pagePadding,
          vertical: AppTokens.spaceM,
        ),
        children: [
          Text(
            '生效日期：2026 年 11 月 22 日',
            style: AppTokens.caption.copyWith(
              color: scheme.onSurface.withAlpha(140),
            ),
          ),
          const SizedBox(height: AppTokens.spaceL),

          const _Section(
            title: '一、我们收集什么',
            body: '本应用不需要注册，不收集任何可识别个人身份的信息 ——'
                '没有姓名、手机号、邮箱、设备标识，也不读取位置。\n\n'
                '你在应用内记录的经期、体重、饮食、运动数据，全部只保存在这台设备上。',
          ),
          const _Section(
            title: '二、数据存在哪里',
            body: '· 位置：应用私有目录，其他应用无法读取\n'
                '· 形式：SQLCipher 加密的本地数据库，密钥由 Android Keystore 保护\n'
                '· 备份：数据库升级前会在同一目录自动留一份备份',
          ),
          const _Section(
            title: '三、我们不做什么',
            body: '· 不上传：本应用未申请联网权限，运行期没有任何网络请求\n'
                '· 不统计：未集成任何第三方统计、广告或崩溃上报 SDK\n'
                '· 不共享：不存在把数据提供给第三方的通道',
          ),
          const _Section(
            title: '四、权限用途',
            body: '· 通知：发送每日提醒，可随时在应用内或系统设置里关闭\n'
                '· 精确闹钟、开机自启：让提醒按时触发，并在重启后自动恢复\n'
                '· 振动：提醒时的触感反馈',
          ),
          const _Section(
            title: '五、你的权利',
            body: '· 查看与修改：所有记录在应用内可见、可改\n'
                '· 删除：可逐条删除或删除整段经期；卸载应用即删除全部数据\n'
                '· 导出：可导出 CSV 到本机文档目录，文件去向完全由你决定',
          ),
          const _Section(
            title: '六、儿童',
            body: '本应用不面向 14 岁以下儿童，也不会主动收集儿童信息。',
          ),
          const _Section(
            title: '七、医学免责',
            body: '经期与排卵预测基于历史记录做统计估计（中位数 + 容差过滤），'
                '仅供参考，不构成医疗建议、避孕依据或诊断结论。'
                '身体异常请及时就医。',
          ),
          const _Section(
            title: '八、政策变更',
            body: '政策如有更新，会随应用版本一同发布，并更新本页顶部的生效日期。',
          ),

          const SizedBox(height: AppTokens.cardGap),
          Text(
            '一句话总结：你的数据只在这台手机里，我们不联网、不统计、不上传，'
            '随时可以自己导出或删除。',
            style: AppTokens.body.copyWith(color: scheme.onSurface.withAlpha(170)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTokens.title.copyWith(color: scheme.onSurface)),
          const SizedBox(height: AppTokens.spaceS),
          Text(
            body,
            style: AppTokens.body.copyWith(
              color: scheme.onSurface.withAlpha(200),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
