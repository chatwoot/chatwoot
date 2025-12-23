# pg

* home :: https://github.com/ged/ruby-pg
* docs :: http://deveiate.org/code/pg (English) ,
          https://deveiate.org/code/pg/README_ja_md.html (Japanese)
* clog :: link:/History.md

[![https://gitter.im/ged/ruby-pg
でチャットに参加](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ged/ruby-pg?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


## 説明

Pgは[PostgreSQL
RDBMS](http://www.postgresql.org/)へのRubyのインターフェースです。[PostgreSQL
9.3以降](http://www.postgresql.org/support/versioning/)で動作します。

簡単な使用例は次の通りです。
```ruby
  #!/usr/bin/env ruby

  require 'pg'

  # データベースへの現在の接続を表に出力します
  conn = PG.connect( dbname: 'sales' )
  conn.exec( "SELECT * FROM pg_stat_activity" ) do |result|
    puts "     PID | User             | Query"
    result.each do |row|
      puts " %7d | %-16s | %s " %
        row.values_at('pid', 'usename', 'query')
    end
  end
```

## ビルド状況

[![Github
Actionsのビルド状況](https://github.com/ged/ruby-pg/actions/workflows/source-gem.yml/badge.svg?branch=master)](https://github.com/ged/ruby-pg/actions/workflows/source-gem.yml)
[![バイナリgem](https://github.com/ged/ruby-pg/actions/workflows/binary-gems.yml/badge.svg?branch=master)](https://github.com/ged/ruby-pg/actions/workflows/binary-gems.yml)
[![Appveyorのビルド状況](https://ci.appveyor.com/api/projects/status/gjx5axouf3b1wicp?svg=true)](https://ci.appveyor.com/project/ged/ruby-pg-9j8l3)


## 要件

* Ruby 2.5かそれより新しいバージョン
* PostgreSQL 9.3.xかそれ以降のバージョン（ヘッダー付属のもの、例えば-devの名前のパッケージ）。

それより前のバージョンのRubyやPostgreSQLでも通常は同様に動作しますが、定期的なテストはされていません。


## バージョン管理

[セマンティックバージョニング](http://semver.org/)の原則にしたがってgemをタグ付けしてリリースしています。

この方針の結果として、2つの数字を指定する[悲観的バージョン制約](http://guides.rubygems.org/patterns/#pessimistic-version-constraint)を使ってこのgemへの依存関係を指定することができます（またそうすべきです）。

例えば次の通りです。

```ruby
  spec.add_dependency 'pg', '~> 1.0'
```

## インストール方法

RubyGemsを経由してインストールするには以下とします。

    gem install pg

Postgresと一緒にインストールされた'pg_config'プログラムへのパスを指定する必要があるかもしれません。

    gem install pg -- --with-pg-config=<path to pg_config>

Bundlerを介してインストールした場合は次のようにコンパイルのためのヒントを与えられます。

    bundle config build.pg --with-pg-config=<path to pg_config>

MacOS Xへインストールする詳しい情報については README-OS_X.rdoc を、Windows用のビルドやインストールの説明については
README-Windows.rdoc を参照してください。

詰まったときやただ何か喋りたいときのために[Google+グループ](http://goo.gl/TFy1U)と[メーリングリスト](http://groups.google.com/group/ruby-pg)もあります。

署名されたgemとしてインストールしたい場合は、リポジトリの[`certs`ディレクトリ](https://github.com/ged/ruby-pg/tree/master/certs)にgemの署名をする公開証明書があります。


## 型変換

PgにはおまけとしてRubyとネイティブCコードにある結果の値やクエリ引数の型変換ができます。
こうすることでデータベースとのデータの往来を加速させられますが、それは文字列のアロケーションが減り、（より遅い）Rubyのコードでの変換部分が除かれるからです。

とても基本的な型変換は次のようにできます。
```ruby
    conn.type_map_for_results = PG::BasicTypeMapForResults.new conn
    # ……これは結果の値の対応付けに作用します。
    conn.exec("select 1, now(), '{2,3}'::int[]").values
        # => [[1, 2014-09-21 20:51:56 +0200, [2, 3]]]

    conn.type_map_for_queries = PG::BasicTypeMapForQueries.new conn
    # ……そしてこれは引数値の対応付けのためのものです。
    conn.exec_params("SELECT $1::text, $2::text, $3::text", [1, 1.23, [2,3]]).values
        # => [["1", "1.2300000000000000E+00", "{2,3}"]]
```

しかしPgの型変換はかなり調整が効きます。2層に分かれているのがその理由です。

### エンコーダーとデコーダー (ext/pg_*coder.c, lib/pg/*coder.rb)

こちらはより低層で、DBMSへ転送するためにRubyのオブジェクトを変換するエンコーディングクラスと取得してきたデータをRubyのオブジェクトに変換し戻すデコーディングクラスが含まれています。クラスはそれぞれの形式によって名前空間PG::TextEncoder、PG::TextDecoder、PG::BinaryEncoder、そしてPG::BinaryDecoderに分かれています。

エンコーダーないしデコーダーオブジェクトにOIDデータ型や形式コード（テキストないしバイナリ）や任意で名前を割り当てることができます。要素のエンコーダーないしデコーダーを割り当てることによって複合型を構築することもできます。PG::CoderオブジェクトはPG::TypeMapをセットアップしたりその代わりに単一の値と文字列表現とを相互に変換したりするのに使えます。

ruby-pgでは以下のPostgreSQLカラム型に対応しています（TE = Text Encoder、TD = Text Decoder、BE =
Binary Encoder、BD = Binary Decoder）。

* Integer:
  [TE](rdoc-ref:PG::TextEncoder::Integer)、[TD](rdoc-ref:PG::TextDecoder::Integer)、[BD](rdoc-ref:PG::BinaryDecoder::Integer)
  💡
  リンクがないでしょうか。[こちら](https://deveiate.org/code/pg/README_ja_md.html#label-E5-9E-8B-E5-A4-89-E6-8F-9B)を代わりに見てください
  💡
    * BE:
      [Int2](rdoc-ref:PG::BinaryEncoder::Int2)、[Int4](rdoc-ref:PG::BinaryEncoder::Int4)、[Int8](rdoc-ref:PG::BinaryEncoder::Int8)
* Float:
  [TE](rdoc-ref:PG::TextEncoder::Float)、[TD](rdoc-ref:PG::TextDecoder::Float)、[BD](rdoc-ref:PG::BinaryDecoder::Float)
    * BE: [Float4](rdoc-ref:PG::BinaryEncoder::Float4),
      [Float8](rdoc-ref:PG::BinaryEncoder::Float8)
* Numeric:
  [TE](rdoc-ref:PG::TextEncoder::Numeric)、[TD](rdoc-ref:PG::TextDecoder::Numeric)
* Boolean:
  [TE](rdoc-ref:PG::TextEncoder::Boolean)、[TD](rdoc-ref:PG::TextDecoder::Boolean)、[BE](rdoc-ref:PG::BinaryEncoder::Boolean)、[BD](rdoc-ref:PG::BinaryDecoder::Boolean)
* String:
  [TE](rdoc-ref:PG::TextEncoder::String)、[TD](rdoc-ref:PG::TextDecoder::String)、[BE](rdoc-ref:PG::BinaryEncoder::String)、[BD](rdoc-ref:PG::BinaryDecoder::String)
* Bytea:
  [TE](rdoc-ref:PG::TextEncoder::Bytea)、[TD](rdoc-ref:PG::TextDecoder::Bytea)、[BE](rdoc-ref:PG::BinaryEncoder::Bytea)、[BD](rdoc-ref:PG::BinaryDecoder::Bytea)
* Base64:
  [TE](rdoc-ref:PG::TextEncoder::ToBase64)、[TD](rdoc-ref:PG::TextDecoder::FromBase64)、[BE](rdoc-ref:PG::BinaryEncoder::FromBase64)、[BD](rdoc-ref:PG::BinaryDecoder::ToBase64)
* Timestamp:
    * TE:
      [現地時間](rdoc-ref:PG::TextEncoder::TimestampWithoutTimeZone)、[UTC](rdoc-ref:PG::TextEncoder::TimestampUtc)、[タイムゾーン付き](rdoc-ref:PG::TextEncoder::TimestampWithTimeZone)
    * TD:
      [現地時間](rdoc-ref:PG::TextDecoder::TimestampLocal)、[UTC](rdoc-ref:PG::TextDecoder::TimestampUtc)、[UTCから現地時間へ](rdoc-ref:PG::TextDecoder::TimestampUtcToLocal)
    * BE: [local](rdoc-ref:PG::BinaryEncoder::TimestampLocal),
      [UTC](rdoc-ref:PG::BinaryEncoder::TimestampUtc)
    * BD:
      [現地時間](rdoc-ref:PG::BinaryDecoder::TimestampLocal)、[UTC](rdoc-ref:PG::BinaryDecoder::TimestampUtc)、[UTCから現地時間へ](rdoc-ref:PG::BinaryDecoder::TimestampUtcToLocal)
* Date: [TE](rdoc-ref:PG::TextEncoder::Date),
  [TD](rdoc-ref:PG::TextDecoder::Date),
  [BE](rdoc-ref:PG::BinaryEncoder::Date),
  [BD](rdoc-ref:PG::BinaryDecoder::Date)
* JSONとJSONB:
  [TE](rdoc-ref:PG::TextEncoder::JSON)、[TD](rdoc-ref:PG::TextDecoder::JSON)
* Inet:
  [TE](rdoc-ref:PG::TextEncoder::Inet)、[TD](rdoc-ref:PG::TextDecoder::Inet)
* Array:
  [TE](rdoc-ref:PG::TextEncoder::Array)、[TD](rdoc-ref:PG::TextDecoder::Array)
* 複合型（「行」や「レコード」などとも言います）：[TE](rdoc-ref:PG::TextEncoder::Record)、[TD](rdoc-ref:PG::TextDecoder::Record)

The following text and binary formats can also be encoded although they are
not used as column type:

* COPYの入出力データ：[TE](rdoc-ref:PG::TextEncoder::CopyRow)、[TD](rdoc-ref:PG::TextDecoder::CopyRow),
  [BE](rdoc-ref:PG::BinaryEncoder::CopyRow),
  [BD](rdoc-ref:PG::BinaryDecoder::CopyRow)
* SQL文字列に挿入するリテラル：[TE](rdoc-ref:PG::TextEncoder::QuotedLiteral)
* SQLの識別子:
  [TE](rdoc-ref:PG::TextEncoder::Identifier)、[TD](rdoc-ref:PG::TextDecoder::Identifier)

### PG::TypeMapとその派生 (ext/pg_type_map*.c, lib/pg/type_map*.rb)

TypeMapはエンコーダーまたはデコーダーのどちらによってどの値を変換するかを定義します。様々な型の対応付け戦略があるので、このクラスにはいくつかの派生が実装されています。型変換の特有の需要に合わせてそれらの派生から選んで調整を加えることができます。既定の型の対応付けはPG::TypeMapAllStringsです。

型の対応付けは、結果の集合それぞれに対し、接続毎ないしクエリ毎に割り当てることができます。型の対応付けはCOPYの入出力データストリーミングでも使うことができます。PG::Connection#copy_dataを参照してください。

以下の基底となる型の対応付けが使えます。

* PG::TypeMapAllStrings - 全ての値と文字列について相互にエンコードとデコードを行います（既定）
* PG::TypeMapByClass - 送信する値のクラスに基づいてエンコーダーを選択します
* PG::TypeMapByColumn - カラムの順番によってエンコーダーとデコーダーを選択します
* PG::TypeMapByOid - PostgreSQLのOIDデータ型によってデコーダーを選択します
* PG::TypeMapInRuby - Rubyで独自の型の対応付けを定義します

以下の型の対応付けはPG::BasicTypeRegistry由来の型の対応付けが入った状態になっています。

* PG::BasicTypeMapForResults -
  PG::TypeMapByOidによくあるPostgreSQLカラム型用にデコーダーが入った状態になっています
* PG::BasicTypeMapBasedOnResult -
  PG::TypeMapByOidによくあるPostgreSQLカラム型用のエンコーダーが入った状態になっています
* PG::BasicTypeMapForQueries -
  PG::TypeMapByClassによくあるRubyの値クラス用にエンコーダーが入った状態になっています


## スレッド対応

PGには個々のスレッドが別々のPG::Connectionオブジェクトを同時に使えるという点でスレッド安全性があります。しかし1つ以上のスレッドから同時にPgのオブジェクトにアクセスすると安全ではありません。そのため必ず、毎回新しいスレッドを作るときに新しいデータベースサーバー接続を開くか、スレッド安全性のある方法で接続を管理するActiveRecordのようなラッパーライブラリを使うようにしてください。

以下のようなメッセージが標準エラー出力に表示された場合、恐らく複数のスレッドが1つの接続を使っています。

    message type 0x31 arrived from server while idle
    message type 0x32 arrived from server while idle
    message type 0x54 arrived from server while idle
    message type 0x43 arrived from server while idle
    message type 0x5a arrived from server while idle


## Fiber IOスケジューラー対応

PgはRuby-3.0で導入された`Fiber.scheduler`に完全に対応しています。`Fiber.scheduler`のWindows対応についてはRuby-3.1以降で使えます。`Fiber.scheduler`が走らせているスレッドに登録されている場合、起こりうる全てのブロッキングIO操作はそのスケジューラーを経由します。同期的であったりブロックしたりするメソッド呼び出しについてもpgが内部的に非同期のlibpqインターフェースを使っているのはそれが理由です。またlibpqの組み込み関数に代えてRubyのDNS解決を使っています。

内部的にPgは常にlibpqのノンブロッキング接続モードを使います。それからブロッキングモードで走っているように振舞いますが、もし`Fiber.scheduler`が登録されていれば全てのブロッキングIOはそのスケジューラーを通じてRubyで制御されます。`PG::Connection.setnonblocking(true)`が呼ばれたらノンブロッキング状態が有効になったままになりますが、それ以降のブロッキング状態の制御が無効になるので、呼び出しているプログラムはブロッキング状態を自力で制御しなければなりません。

この規則の1つの例外には、`PG::Connection#lo_create`や外部ライブラリを使う認証メソッド（GSSAPI認証など）のような、大きめのオブジェクト用のメソッドがあります。これらは`Fiber.scheduler`と互換性がないため、ブロッキング状態は登録されたIOスケジューラに渡されません。つまり操作は適切に実行されますが、IO待ち状態に別のIOを扱うFiberから使用を切り替えてくることができなくなります。


## 貢献

バグを報告したり機能を提案したりGitでソースをチェックアウトしたりするには[プロジェクトページをご確認ください](https://github.com/ged/ruby-pg)。

ソースをチェックアウトしたあとは全ての依存関係をインストールします。

    $ bundle install

拡張ファイル、パッケージファイル、テストデータベースを一掃するには、このコマンドを走らせてください。PostgreSQLのバージョンも切り替わります。

    $ rake clean

拡張をコンパイルするには次のようにします。

    $ rake compile

`pg_config --bindir`が指すPostgreSQLのバージョンでテストやスペックを走らせるには次のようにします。

    $ rake test

あるいは特定のPostgreSQLのバージョンで、ファイル中の行番号を使って特定のテストを走らせるには次のようにします。

    $ PATH=/usr/lib/postgresql/14/bin:$PATH rspec -Ilib -fd spec/pg/connection_spec.rb:455

APIドキュメントを生成するには次のようにします。

    $ rake docs

必ず全てのバグと新機能についてテストを使って検証してください。

現在のメンテナはMichael Granger <ged@FaerieMUD.org>とLars Kanis
<lars@greiz-reinsdorf.de>です。


## 著作権

Copyright (c) 1997-2022 by the authors.

* Jeff Davis <ruby-pg@j-davis.com>
* Guy Decoux (ts) <decoux@moulon.inra.fr>
* Michael Granger <ged@FaerieMUD.org>
* Lars Kanis <lars@greiz-reinsdorf.de>
* Dave Lee
* Eiji Matsumoto <usagi@ruby.club.or.jp>
* Yukihiro Matsumoto <matz@ruby-lang.org>
* Noboru Saitou <noborus@netlab.jp>

You may redistribute this software under the same terms as Ruby itself; see
https://www.ruby-lang.org/en/about/license.txt or the BSDL file in the
source for details.
（参考訳：このソフトウェアはRuby自体と同じ条件の元で再配布することができます。詳細については
https://www.ruby-lang.org/en/about/license.txt やソース中のBSDLファイルを参照してください）

Portions of the code are from the PostgreSQL project, and are distributed "
"under the terms of the PostgreSQL license, included in the file POSTGRES.
（参考訳：コードの一部はPostgreSQLプロジェクトから来ており、PostgreSQLの使用許諾の条件の元で配布されます。ファイルPOSTGRESに含まれています）

Portions copyright LAIKA, Inc.


## 謝辞

長年にわたって貢献してくださった方々についてはContributors.rdocを参照してください。

ruby-listとruby-devメーリングリストの方々に感謝します。またPostgreSQLを開発された方々へも謝意を表します。
