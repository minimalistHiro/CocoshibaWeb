import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget sectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return ListView(
      children: [
        Text(
          'プライバシーポリシー',
          style:
              theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'プライバシーポリシー（Antenna Books & Cafe ココシバ ポイントアプリ）',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        const Text('制定日：2025年12月22日'),
        const SizedBox(height: 4),
        const Text('運営者：h.kaneko.baseball@icloud.com（以下「当店」）'),
        const SizedBox(height: 4),
        const Text('所在地：埼玉県川口市芝5-5-13'),
        const SizedBox(height: 4),
        const Text('連絡先：h.kaneko.baseball@icloud.com（原則メール対応）'),
        const SizedBox(height: 16),
        const Text(
          '当店は、当店が提供する'
          '「Antenna Books & Cafe ココシバ ポイントアプリ」（以下「本アプリ」）'
          'および関連サービス（以下総称して「本サービス」）における、'
          'ユーザーの情報（個人情報を含みます）の取扱いについて、以下のとおり'
          'プライバシーポリシー（以下「本ポリシー」）を定めます。',
        ),
        sectionTitle('1. 適用範囲'),
        const Text(
          '本ポリシーは、本サービスの利用に関して当店が取得・利用・保存・第三者提供等を行う'
          'ユーザー情報の取扱いに適用されます。',
        ),
        sectionTitle('2. 取得する情報'),
        const Text(
          '当店は、本サービスの提供にあたり、以下の情報を取得・利用する場合があります。\n'
          '(1) アカウント情報\n'
          '- メールアドレス\n'
          '- 認証に必要な情報（パスワード等）\n'
          '※パスワード等の認証情報は、外部の認証基盤（Firebase Authentication 等）を通じて'
          '処理され、当店が平文で保有・管理することはありません。\n\n'
          '(2) 端末・利用環境情報\n'
          '- 端末種別、OS バージョン、アプリバージョン等\n'
          '- 言語設定、タイムゾーン等（端末・OS が提供する範囲）\n'
          '- 通知配信用の識別子（例：プッシュ通知トークン/FCM 登録トークン）\n\n'
          '(3) 通知関連情報\n'
          '- 通知許可の状態\n'
          '- 通知配信のためのトークン情報（例：FCM トークン）\n'
          '- 通知の配信結果に関する情報（到達可否等、外部サービスが提供する範囲）\n\n'
          '(4) お問い合わせ情報\n'
          '- お問い合わせ時にユーザーが入力した氏名（任意）、メールアドレス、問い合わせ内容等\n\n'
          '(5) 店舗利用・ポイント等（本サービスが実装・提供する範囲）\n'
          '- ポイント残高、付与・利用履歴、会員ステータス等\n'
          '※本アプリの機能拡張により、将来取得項目が追加される場合があります。',
        ),
        sectionTitle('3. 利用目的'),
        const Text(
          '当店は、取得した情報を以下の目的で利用します。\n'
          '(1) 本サービスの提供（ログイン認証、アカウント管理、ポイント表示等）\n'
          '(2) お知らせ・重要連絡の配信（プッシュ通知を含む）\n'
          '(3) 本サービスの運用・保守、障害対応、不正利用の防止\n'
          '(4) お問い合わせ対応、本人確認（必要な場合）\n'
          '(5) 規約違反への対応、紛争対応',
        ),
        sectionTitle('4. 外部サービス（第三者）による情報処理'),
        const Text(
          '本サービスは、機能提供のために以下の外部サービスを利用する場合があります。'
          '当該外部サービス事業者が、同社の規約・ポリシーに基づき情報を取り扱うことがあります。\n'
          '- Firebase Authentication（認証）\n'
          '- Cloud Firestore（データ保存）\n'
          '- Firebase Cloud Messaging（プッシュ通知）\n'
          '- Cloud Functions for Firebase（通知送信等のサーバ処理）\n'
          '当店は、外部サービスの仕様変更・停止等により、'
          '本サービスの全部または一部が利用できなくなる場合があることをご了承ください。',
        ),
        sectionTitle('5. 第三者提供'),
        const Text(
          '当店は、次の場合を除き、ユーザーの個人情報を第三者に提供しません。\n'
          '(1) ユーザーの同意がある場合\n'
          '(2) 法令に基づく場合\n'
          '(3) 人の生命・身体・財産の保護のために必要があり、同意取得が困難な場合\n'
          '(4) 公衆衛生の向上・児童の健全育成のために必要があり、同意取得が困難な場合\n'
          '(5) 国の機関等への協力が必要で、同意取得により支障を及ぼすおそれがある場合\n'
          '(6) 利用目的の達成に必要な範囲で、外部サービス事業者等に取扱いを委託する場合（例：Firebase 等）',
        ),
        sectionTitle('6. 海外での情報処理（外国にある第三者）'),
        const Text(
          '当店が利用する外部サービス（例：Firebase）は、国外（例：米国等）に所在する'
          '事業者のサーバで情報が処理・保管される場合があります。'
          'ユーザーは本サービスの利用により、これらの国外での情報処理に同意したものとします。',
        ),
        sectionTitle('7. 安全管理措置'),
        const Text(
          '当店は、取得した情報の漏えい、滅失、毀損、不正アクセス等を防止するため、'
          '合理的な安全管理措置を講じます。\n'
          '- 認証基盤・アクセス制御の利用\n'
          '- 権限管理（最小権限）\n'
          '- ログの取得・監視（必要な範囲）\n'
          '- 外部サービス（Firebase 等）のセキュリティ機能の活用\n'
          '※完全な安全を保証するものではありません。',
        ),
        sectionTitle('8. 保存期間'),
        const Text(
          '当店は、利用目的の達成に必要な期間、ユーザー情報を保存します。'
          '退会・削除要請があった場合でも、法令遵守・不正対策・紛争対応等のために'
          '必要な範囲で一定期間保存する場合があります。',
        ),
        sectionTitle('9. ユーザーの権利（開示・訂正・削除等）'),
        const Text(
          'ユーザーは、当店所定の手続により、自己の個人情報について、開示、訂正、追加、削除、'
          '利用停止等を請求できます。\n'
          '請求方法：本ポリシー末尾の連絡先へご連絡ください。\n'
          '※本人確認をお願いする場合があります。\n'
          '※外部サービス（Firebase 等）側で管理される情報については、当店で対応できる範囲に限り対応します。',
        ),
        sectionTitle('10. 通知のオプトアウト'),
        const Text(
          'ユーザーは、端末のOS設定等によりプッシュ通知を停止できます。'
          'ただし、停止した場合、本サービス上の重要なお知らせが受領できないことがあります。',
        ),
        sectionTitle('11. 未成年者の利用'),
        const Text(
          '未成年者が本サービスを利用する場合、法定代理人の同意を得たうえで利用するものとします。',
        ),
        sectionTitle('12. 本ポリシーの変更'),
        const Text(
          '当店は、法令に反しない範囲で本ポリシーを変更することがあります。'
          '重要な変更がある場合は、本アプリ上の掲示その他当店が適切と判断する方法で周知します。'
          '変更後にユーザーが本サービスを利用した場合、変更に同意したものとみなします。',
        ),
        sectionTitle('13. お問い合わせ窓口'),
        const Text(
          '本ポリシーに関するお問い合わせは、以下へご連絡ください。\n'
          '運営者：Antenna Books & Cafe ココシバ\n'
          'メール：h.kaneko.baseball@icloud.com\n'
          '受付時間：水〜日11:00〜18:00（休：月、火）',
        ),
      ],
    );
  }
}
