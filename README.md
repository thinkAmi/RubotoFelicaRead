RubotoFelicaRead
========

nfc-felicaライブラリを使い、Suica・Edy・Kururuの履歴を読むRubotoアプリです。
(Kururuは長野市バス共通ICカードになります)



開発環境
----------

* OS: Windows7 x64
* JDK: 1.7.0_45
* ant: 1.9.1
* Ruby: RubyInstaller 1.9.3-p448
* Ruboto: 0.15.0
* jruby-jars: 1.7.6
* Device: Nexus7 2012
* API Level: android-17


セットアップ
----------

`git clone`後、`rake install`でビルド・端末へのインストールを行います。
あとは、アプリを起動してSuica・Edyをかざせば、それらの履歴が表示されます。
なお、カード内のデータを利用しているため、履歴を表示する最大件数は、Suica20件・Edy6件、Kururuはたぶん9件になります(Kururuは履歴を全部埋めていないため、正確には分かりません)。


クレジット
----------
### Ruboto ###
[公式ページ：Ruboto](http://ruboto.org/index.html)

AndroidアプリをRuby(JRuby)で書くために使用しています。


### nfc-felica ###
[公式ページ：nfc-felica](http://code.google.com/p/nfc-felica/)

このおかげでFeliCaのデータを読むのが非常に容易でした。ありがとうございました。

このアプリの中では一部改変しており、Apache License 2.0に記載の条件に従って使用しています。
[Apache License](http://www.apache.org/licenses/LICENSE-2.0)


ライセンス
----------
MIT