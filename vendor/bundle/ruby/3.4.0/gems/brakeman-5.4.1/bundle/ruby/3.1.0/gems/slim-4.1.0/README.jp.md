# Slim

[![Gem Version](https://img.shields.io/gem/v/slim.svg)](http://rubygems.org/gems/slim) [![Build Status](https://img.shields.io/travis/slim-template/slim.svg?branch=master)](http://travis-ci.org/slim-template/slim) [![Code Climate](https://codeclimate.com/github/slim-template/slim/badges/gpa.svg)](https://codeclimate.com/github/slim-template/slim) [![Test Coverage](https://codeclimate.com/github/slim-template/slim/badges/coverage.svg)](https://codeclimate.com/github/slim-template/slim/coverage)
[![Flattr donate button](https://raw.github.com/balupton/flattr-buttons/master/badge-89x18.gif)](https://flattr.com/submit/auto?user_id=min4d&url=http%3A%2F%2Fslim-lang.org%2F "Donate monthly to this project using Flattr")

Slim は 不可解にならない程度に view の構文を本質的な部品まで減らすことを目指したテンプレート言語です。標準的な HTML テンプレートからどれだけのものを減らせるか、検証するところから始まりました。(<, >, 閉じタグなど) 多くの人が Slim に興味を持ったことで, 機能的で柔軟な構文に成長しました。

簡単な特徴

* すっきりした構文
    * 閉じタグの無い短い構文 (代わりにインデントを用いる)
    * 閉じタグを用いた HTML 形式の構文
    * 設定可能なショートカットタグ (デフォルトでは `#` は `<div id="...">` に, `.` は `<div class="...">` に)
* 安全性
    * デフォルトで自動 HTML エスケープ
    * Rails の `html_safe?` に対応
* 柔軟な設定
* プラグインを用いた拡張性:
    * Mustache と同様のロジックレスモード
    * インクルード
    * 多言語化/I18n
* 高性能
    * ERB/Erubis に匹敵するスピード
    * Rails のストリーミングに対応
* 全てのメジャーフレームワークが対応 (Rails, Sinatra, ...)
* タグや属性の Unicode に完全対応
* Markdown や Textile のような埋め込みエンジン

## リンク

* ホームページ: <http://slim-lang.com>
* ソース: <http://github.com/slim-template/slim>
* バグ:   <http://github.com/slim-template/slim/issues>
* リスト:   <http://groups.google.com/group/slim-template>
* API ドキュメント:
    * 最新の Gem: <http://rubydoc.info/gems/slim/frames> <https://www.omniref.com/ruby/gems/slim>
    * GitHub master: <http://rubydoc.info/github/slim-template/slim/master/frames> <https://www.omniref.com/github/slim-template/slim>

## イントロダクション

### Slim とは?

Slim は __Rails3 以降__ に対応した高速, 軽量なテンプレートエンジンです。主要な Ruby の実装全てでしっかりテストされています。
私たちは継続的インテグレーションを採用しています。(travis-ci)

Slim の核となる構文は1つの考えによって導かれています: "この動作を行うために最低限必要なものは何か。"

多くの人々の Slim への貢献によって, 彼らが使う [Haml](https://github.com/haml/haml) や [Jade](https://github.com/visionmedia/jade) の影響を受け構文の追加が行われています。 Slim の開発チームは美は見る人の目の中にあることを分っているので、こういった追加にオープンです。

Slim は 構文解析/コンパイルに [Temple](https://github.com/judofyr/temple) を使い [Tilt](https://github.com/rtomayko/tilt) に組み込まれます。これにより [Sinatra](https://github.com/sinatra/sinatra) やプレーンな [Rack](https://github.com/rack/rack) とも一緒に使えます。

Temple のアーキテクチャはとても柔軟で, モンキーパッチなしで構文解析とコンパイルのプロセスの拡張が可能です。これはロジックレスのプラグインや I18n が提供する翻訳プラグインに
使用されます。ロジックレスモードでは HTML をビルドするために Slim の構文を使いたいが, テンプレートの中で Ruby を書きたくない場合にも Slim を使うことができます。

### なぜ Slim を使うのか?

* Slim によって メンテナンスが容易な限りなく最小限のテンプレートを作成でき, 正しい文法の HTML や XML が書けることを保証します。
* Slim の構文は美しく, テンプレートを書くのがより楽しくなります。Slim は主要なフレームワークで互換性があるので, 簡単に始めることができます。
* Slim のアーキテクチャは非常に柔軟なので, 構文の拡張やプラグインを書くことができます。

___そう, Slim は速い!___ Slim は開発当初からパフォーマンスに注意して開発されてきました。
ベンチマークはコミット毎に <http://travis-ci.org/slim-template/slim> で取られています。
この数字が信じられませんか? それは仕方ないことです。是非 rake タスクを使って自分でベンチマークを取ってみてください!

私たちの考えでは, あなたは Slim の機能と構文を使うべきです。Slim はあなたのアプリケーションのパフォーマンスに悪影響を与えないことを保証します。

### どうやって使い始めるの?

Slim を gem としてインストール:

~~~
gem install slim
~~~

あなたの Gemfile に `gem 'slim'` と書いてインクルードするか, ファイルに `require 'slim'` と書く必要があります。これだけです! 後は拡張子に .slim を使うだけで準備完了です。

### 構文例

Slim テンプレートがどのようなものか簡単な例を示します:

~~~ slim
doctype html
html
  head
    title Slim のファイル例
    meta name="keywords" content="template language"
    meta name="author" content=author
    link rel="icon" type="image/png" href=file_path("favicon.png")
    javascript:
      alert('Slim は javascript の埋め込みに対応しています!')

  body
    h1 マークアップ例

    #content
      p このマークアップ例は Slim の典型的なファイルがどのようなものか示します。

    == yield

    - if items.any?
      table#items
        - for item in items
          tr
            td.name = item.name
            td.price = item.price
    - else
      p アイテムが見つかりませんでした。いくつか目録を追加してください。
        ありがとう!

    div id="footer"
      == render 'footer'
      | Copyright &copy; #{@year} #{@author}
~~~

インデントについて, インデントの深さはあなたの好みで選択できます。もしあなたが最初のインデントをスペース2つ, その次に5スペースを使いたい場合, それも自由です。マークアップを入れ子にするには最低1つのスペースによるインデントが必要なだけです。

## ラインインジケータ

### テキスト `|`

パイプを使うと, Slim はパイプよりも深くインデントされた全ての行をコピーします。行中の処理は基本的にどのようなものでもエスケープされます。

~~~ slim
body
  p
    |
      これはテキストブロックのテストです。
~~~

  構文解析結果は以下:

~~~ html
<body><p>これはテキストブロックのテストです。</p></body>
~~~

  ブロックの左端はパイプ +1 スペースのインデントに設定されています。
  追加のスペースはコピーされます。

~~~ slim
body
  p
    | この行は左端になります。
       この行はスペース 1 つを持つことになります。
         この行はスペース 2 つを持つことになります。
           以下同様に...
~~~

テキスト行に HTML を埋め込むこともできます。

~~~ slim
- articles.each do |a|
  | <tr><td>#{a.name}</td><td>#{a.description}</td></tr>
~~~

### 末尾スペース付きのテキスト `'`

シングルクォートは `|` と同様に行をコピーしますが, 末尾にスペースが1つ追加されます。

### インライン html `<` (HTML 形式)

HTML タグを直接 Slim の中に書くことができます。Slim では, 閉じタグを使った HTML タグ形式や HTML と Slim を混ぜてテンプレートの中に書くことができます。
行頭が '<' の場合, 暗黙的に `|` があるものとして動作します:

~~~ slim
<html>
  head
    title Example
  <body>
    - if articles.empty?
    - else
      table
        - articles.each do |a|
          <tr><td>#{a.name}</td><td>#{a.description}</td></tr>
  </body>
</html>
~~~

### 制御コード `-`

ダッシュは制御コードを意味します。制御コードの例としてループと条件文があります。`end` は `-` の後ろに置くことができません。ブロックはインデントによってのみ定義されます。
複数行にわたる Ruby のコードが必要な場合, 行末にバックスラッシュ `\` を追加します。行末がカンマ `,` で終わる場合 (例 関数呼び出し) には, 行末にバックスラッシュを追加する必要はありません。

~~~ slim
body
  - if articles.empty?
    | 在庫なし
~~~

### 出力 `=`

イコールはバッファに追加する出力を生成する Ruby コードの呼び出しを Slim に命令します。Ruby のコードが複数行にわたる場合, 例のように行末にバックスラッシュを追加します。

~~~ slim
= javascript_include_tag \
   "jquery",
   "application"
~~~

行末がカンマ `,` で終わる場合 (例 関数呼び出し) には行末にバックスラッシュを追加する必要はありません。行末・行頭にスペースを追加するために修飾子の `>` や `<` がサポートされています。

* `=>` は末尾のスペースを伴った出力をします。 末尾のスペースが追加されることを除いて, 単一の等合 (`=`) と同じです。
* `=<` は先頭のスペースを伴った出力をします。先頭のスペースが追加されることを除いて, 単一の等号 (`=`) と同じです。

### HTML エスケープを伴わない出力 `==`

単一のイコール (`=`) と同じですが, `escape_html` メソッドを経由しません。 末尾や先頭のスペースを追加するための修飾子 `>` と `<` はサポートされています。

* `==>` は HTML エスケープを行わずに, 末尾のスペースを伴った出力をします。末尾のスペースが追加されることを除いて, 二重等号 (`==`) と同じです。
* `==<` は HTML エスケープを行わずに, 先頭のスペースを伴った出力をします。先頭のスペースが追加されることを除いて, 二重等号 (`==`) と同じです。

### コードコメント `/`

コードコメントにはスラッシュを使います。スラッシュ以降は最終的なレンダリング結果に表示されません。コードコメントには `/` を, html コメントには `/!` を使います。

~~~ slim
body
  p
    / この行は表示されません。
      この行も表示されません。
    /! html コメントとして表示されます。
~~~

  構文解析結果は以下:

~~~ html
<body><p><!--html コメントとして表示されます。--></p></body>
~~~

### HTML コメント `/!`

html コメントにはスラッシュの直後にエクスクラメーションマークを使います (`<!-- ... -->`)。

### IE コンディショナルコメント `/[...]`

~~~ slim
/[if IE]
    p もっといいブラウザを使ってください。
~~~

レンダリング結果:

~~~ html
<!--[if IE]><p>もっといいブラウザを使ってください。</p><![endif]-->
~~~

## HTML タグ

### <!DOCTYPE> 宣言

doctype キーワードでは, とても簡単な方法で複雑な DOCTYPE を生成できます。

XML バージョン

~~~ slim
doctype xml
  <?xml version="1.0" encoding="utf-8" ?>

doctype xml ISO-8859-1
  <?xml version="1.0" encoding="iso-8859-1" ?>
~~~

XHTML DOCTYPES

~~~ slim
doctype html
  <!DOCTYPE html>

doctype 5
  <!DOCTYPE html>

doctype 1.1
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
    "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

doctype strict
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

doctype frameset
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">

doctype mobile
  <!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN"
    "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">

doctype basic
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN"
    "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">

doctype transitional
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
~~~

HTML 4 DOCTYPES

~~~ slim
doctype strict
  <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
    "http://www.w3.org/TR/html4/strict.dtd">

doctype frameset
  <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN"
    "http://www.w3.org/TR/html4/frameset.dtd">

doctype transitional
  <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd">
~~~

### 閉じタグ (末尾の `/`)

末尾に `/` を付けることで明示的にタグを閉じることができます。

~~~ slim
img src="image.png"/
~~~

(注) 標準的な html タグ (img, br, ...) は自動的にタグを閉じるので,
通常必要ありません。

### 行頭・行末にスペースを追加する (`<`, `>`)

a タグの後に > を追加することで末尾にスペースを追加するよう Slim に強制することができます。

~~~ slim
a> href='url1' リンク1
a> href='url2' リンク2
~~~

< を追加することで先頭にスペースを追加できます。

~~~ slim
a< href='url1' リンク1
a< href='url2' リンク2
~~~

これらを組み合わせて使うこともできます。

~~~ slim
a<> href='url1' リンク1
~~~

### インラインタグ

タグをよりコンパクトにインラインにしたくなることがあるかもしれません。

~~~ slim
ul
  li.first: a href="/a" A リンク
  li: a href="/b" B リンク
~~~

可読性のために, 属性を囲むことができるのを忘れないでください。

~~~ slim
ul
  li.first: a[href="/a"] A リンク
  li: a[href="/b"] B リンク
~~~

### テキストコンテンツ

タグと同じ行で開始するか

~~~ slim
body
  h1 id="headline" 私のサイトへようこそ。
~~~

入れ子にするかのどちらかです。エスケープ処理を行うためにはパイプかシングルクォートを使わなければなりません。


~~~ slim
body
  h1 id="headline"
    | 私のサイトへようこそ。
~~~

スマートテキストモードを有効化して利用する場合

~~~ slim
body
  h1 id="headline"
    私のサイトへようこそ。
~~~

### 動的コンテンツ (`=` と `==`)

同じ行で呼び出すか

~~~ slim
body
  h1 id="headline" = page_headline
~~~

入れ子にすることができます。

~~~ slim
body
  h1 id="headline"
    = page_headline
~~~

### 属性

タグの後に直接属性を書きます。通常の属性記述にはダブルクォート `"` か シングルクォート `'` を使わなければなりません (引用符で囲まれた属性)。

~~~ slim
a href="http://slim-lang.com" title='Slim のホームページ' Slim のホームページへ
~~~

引用符で囲まれたテキストを属性として使えます。

#### 属性の囲み

区切り文字が構文を読みやすくするのであれば,
`{...}`, `(...)`, `[...]` で属性を囲むことができます。
これらの記号は設定で変更できます (`:attr_list_delims` オプション参照)。

~~~ slim
body
  h1(id="logo") = page_logo
  h2[id="tagline" class="small tagline"] = page_tagline
~~~

属性を囲んだ場合, 属性を複数行にわたって書くことができます:

~~~ slim
h2[id="tagline"
   class="small tagline"] = page_tagline
~~~

属性の囲みや変数まわりにスペースを使うことができます:

~~~ slim
h1 id = "logo" = page_logo
h2 [ id = "tagline" ] = page_tagline
~~~

#### 引用符で囲まれた属性

例:

~~~ slim
a href="http://slim-lang.com" title='Slim のホームページ' Slim のホームページへ
~~~

引用符で囲まれたテキストを属性として使えます:

~~~ slim
a href="http://#{url}" #{url} へ
~~~

属性値はデフォルトでエスケープされます。属性のエスケープを無効にしたい場合 == を使います。

~~~ slim
a href=="&amp;"
~~~

引用符で囲まれた属性をバックスラッシュ `\` で改行できます。

~~~ slim
a data-title="help" data-content="極めて長い長い長いヘルプテキストで\
  続けてその後はまたやり直して繰り返し...."
~~~

#### Ruby コードを用いた属性

`=` の後に直接 Ruby コードを書きます。コードにスペースが含まれる場合,
`(...)` の括弧でコードを囲まなければなりません。ハッシュを `{...}` に, 配列を `[...]` に書くこともできます。

~~~ slim
body
  table
    - for user in users
      td id="user_#{user.id}" class=user.role
        a href=user_action(user, :edit) Edit #{user.name}
        a href=(path_to_user user) = user.name
~~~

属性値はデフォルトでエスケープされます。属性のエスケープを無効にしたい場合 == を使います。

~~~ slim
a href==action_path(:start)
~~~

Ruby コードの属性は, コントロールセクションにあるようにバックスラッシュ `\` や `,` を用いて改行できます。

#### 真偽値属性

属性値の `true`, `false` や `nil` は真偽値として
評価されます。属性を括弧で囲む場合, 属性値の指定を省略することができます。

~~~ slim
input type="text" disabled="disabled"
input type="text" disabled=true
input(type="text" disabled)

input type="text"
input type="text" disabled=false
input type="text" disabled=nil
~~~

#### 属性の結合

複数の属性が与えられた場合に属性をまとめるように設定することができます (`:merge_attrs` 参照)。デフォルト設定では
 class 属性はスペース区切りで結合されます。

~~~ slim
a.menu class="highlight" href="http://slim-lang.com/" Slim-lang.com
~~~

レンダリング結果:

~~~ html
<a class="menu highlight" href="http://slim-lang.com/">Slim-lang.com</a>
~~~

また, `Array` を属性値として使うと、配列要素が区切り文字で結合されます。

~~~ slim
a class=["menu","highlight"]
a class=:menu,:highlight
~~~

#### アスタリスク属性 `*`

アスタリスクによってハッシュを属性/値のペアとして使うことができます。

~~~ slim
.card*{'data-url'=>place_path(place), 'data-id'=>place.id} = place.name
~~~

レンダリング結果:

~~~ html
<div class="card" data-id="1234" data-url="/place/1234">Slim の家</div>
~~~

次のようにハッシュを返すメソッドやインスタンス変数を使うこともできます。

~~~ slim
.card *method_which_returns_hash = place.name
.card *@hash_instance_variable = place.name
~~~

属性の結合 (Slim オプション `:merge_attrs` 参照) に対応するハッシュ属性には `Array` を与えることもできます。

~~~ slim
.first *{class: [:second, :third]} テキスト
~~~

レンダリング結果

~~~ slim
div class="first second third"
~~~

アスタリスク(スプラット)属性のプレフィックスは `splat_prefix` オプションで設定できます。デフォルト値は `'*'` です。

#### 動的タグ `*`

アスタリスク属性を使用することで完全に動的なタグを作ることができます。:tag をキーにもつハッシュを返すメソッドを
作るだけです。

~~~ slim
ruby:
  def a_unless_current
    @page_current ? {tag: 'span'} : {tag: 'a', href: 'http://slim-lang.com/'}
  end
- @page_current = true
*a_unless_current リンク
- @page_current = false
*a_unless_current リンク
~~~

レンダリング結果:

~~~ html
<span>リンク</span><a href="http://slim-lang.com/">リンク</a>
~~~

### ショートカット

#### タグショートカット

`:shortcut` オプションを設定することで独自のタグショートカットを定義できます。Rails アプリケーションでは, `config/initializers/slim.rb` のようなイニシャライザに定義します。Sinatra アプリでは, `require 'slim'` を書いた行以降であれば, どこにでも設定を定義することができます。

~~~ ruby
Slim::Engine.set_options shortcut: {'c' => {tag: 'container'}, '#' => {attr: 'id'}, '.' => {attr: 'class'} }
~~~

Slim コードの中でこの様に使用できます。

~~~ slim
c.content テキスト
~~~

レンダリング結果

~~~ html
<container class="content">テキスト</container>
~~~

#### 属性のショートカット

カスタムショートカットを定義することができます (id の`#` , class の `.` のように)。

例として, type 属性付きの input 要素のショートカット `&` を追加します。

~~~ ruby
Slim::Engine.set_options shortcut: {'&' => {tag: 'input', attr: 'type'}, '#' => {attr: 'id'}, '.' => {attr: 'class'}}
~~~

Slim コードの中でこの様に使用できます。

~~~ slim
&text name="user"
&password name="pw"
&submit
~~~

レンダリング結果

~~~ html
<input type="text" name="user" />
<input type="password" name="pw" />
<input type="submit" />
~~~

別の例として, role 属性のショートカット `@` を追加します。

~~~ ruby
Slim::Engine.set_options shortcut: {'@' => 'role', '#' => 'id', '.' => 'class'}
~~~

Slim コードの中でこの様に使用できます。

~~~ slim
.person@admin = person.name
~~~

レンダリング結果

~~~ html
<div class="person" role="admin">Daniel</div>
~~~

1つのショートカットを使って複数の属性を設定することもできます。

~~~ ruby
Slim::Engine.set_options shortcut: {'@' => {attr: %w(data-role role)}}
~~~

Slim の中で次のように使用すると,

~~~ slim
.person@admin = person.name
~~~

このようにレンダリングされます。

~~~ html
<div class="person" role="admin" data-role="admin">Daniel</div>
~~~

次のように追加の属性固定値を設定することもできます。

~~~ ruby
Slim::Engine.set_options shortcut: {'^' => {tag: 'script', attr: 'data-binding',
  additional_attrs: { type: "text/javascript" }}}
~~~

このように使用します。

~~~ slim
^products
  == @products.to_json
~~~

レンダリング結果です。

~~~ html
<script data-binding="products" type="text/javascript">
[{"name": "product1", "price": "$100"},
 {"name": "prodcut2", "price": "$200"}]
</script>
~~~

#### ID ショートカット `#` と class ショートカット `.`

`id` と `class` の属性を次のショートカットで指定できます。

~~~ slim
body
  h1#headline
    = page_headline
  h2#tagline.small.tagline
    = page_tagline
  .content
    = show_content
~~~

これは次に同じです

~~~ slim
body
  h1 id="headline"
    = page_headline
  h2 id="tagline" class="small tagline"
    = page_tagline
  div class="content"
    = show_content
~~~

## ヘルパ, キャプチャとインクルード

いくつかのヘルパを使用してテンプレートを拡張することもできます。次のヘルパが定義されているとして,

~~~ruby
module Helpers
  def headline(&block)
    if defined?(::Rails)
      # Rails の場合には capture メソッドを使う
      "<h1>#{capture(&block)}</h1>"
    else
      # フレームワークなしで Slim を使う場合(Tilt の場合),
      # そのまま出力する
      "<h1>#{yield}</h1>"
    end
  end
end
~~~

実行する Slim のテンプレートコードのスコープにインクルードされます。このヘルパは, Slim テンプレートの中で次のように使用することができます。

~~~ slim
p
  = headline do
    ' Hello
    = user.name
~~~

`do` ブロック内のコンテンツが自動的にキャプチャされ `yield` を通してヘルパに渡されます。糖衣構文として
`do` キーワードを省略して書くこともできます。

~~~ slim
p
  = headline
    ' Hello
    = user.name
~~~

### ローカル変数のキャプチャ

次のように `Binding` を使ってローカル変数をキャプチャすることができます:

~~~ruby
module Helpers
  def capture_to_local(var, &block)
    set_var = block.binding.eval("lambda {|x| #{var} = x }")
    # Rails では capture! を使います
    # Slim をフレームワークなしで使う場合 (Tilt のみを使う場合),
    # キャプチャブロックを取得するには yield だけが利用できます
    set_var.call(defined?(::Rails) ? capture(&block) : yield)
  end
end
~~~

このヘルパは次のように使用できます

~~~ slim
/ captured_content 変数は Binding 前に定義されていなければいけません。
= capture_to_local captured_content=:captured_content
  p この段落は captured_content 変数にキャプチャされます
= captured_content
~~~

別の興味深いユースケースは, enumerableを使いそれぞれの要素をキャプチャすることです。ヘルパは, このようになります。

~~~ ruby
module Capture
  def capture(var, enumerable = nil, &block)
    value = enumerable ? enumerable.map(&block) : yield
    block.binding.eval("lambda {|x| #{var} = x }").call(value)
    nil
  end
end
~~~

そして, 次のように使用出来ます。

~~~ slim
- links = { 'http://slim-lang.com' => 'The Slim Template Language' }
= capture link_list=:link_list, links do |url, text|
  a href=url = text
~~~

その後は, `link_list`はキャプチャしたコンテンツを含みます。

### インクルードヘルパ

コンパイル時にインクルード機能を使いたい場合には, [パーシャルのインクルード](doc/jp/include.md) を見てください。
実行時にサブテンプレートを実行すること ( Rails の `#render` のように) もできます。インクルードヘルパを自分で用意する必要があります:

~~~ ruby
module Helpers
  def include_slim(name, options = {}, &block)
    Slim::Template.new("#{name}.slim", options).render(self, &block)
  end
end
~~~

このヘルパは次のように使用できます

~~~ slim
nav = include_slim 'menu'
section = include_slim 'content'
~~~

しかし, このヘルパはキャッシュを行いません。その為, 目的にあったよりインテリジェントなバージョンを
実装する必要があります。また, ほとんどのフレームワークにはすでに同様のヘルパが含まれるので注意してください。(例: Rails の `render` メソッド)

## テキストの展開

Ruby の標準的な展開方法を使用します。テキストはデフォルトで html エスケープされます。2 重括弧にすることでエスケープしないこともできます。

~~~ slim
body
  h1 ようこそ #{current_user.name} ショーへ。
  | エスケープしない #{{content}} こともできます。
~~~

展開したテキストのエスケープ方法 (言い換えればそのままのレンダリング)

~~~ slim
body
  h1 ようこそ \#{current_user.name} ショーへ。
~~~

## 埋め込みエンジン (Markdown, ...)

[Tilt](https://github.com/rtomayko/tilt)のおかげで, Slim は他のテンプレートエンジンの埋め込みに見事に対応しています。

例:

~~~ slim
    coffee:
      square = (x) -> x * x

    markdown:
      #Header
        #{"Markdown"} からこんにちわ!
        2行目!

p: markdown: Tag with **inline** markdown!
~~~

対応エンジン:

| フィルタ | 必要な gems | 種類 | 説明 |
| -------- | ----------- | ---- | ----------- |
| ruby: | なし | ショートカット | Ruby コードを埋め込むショートカット |
| javascript: | なし | ショートカット | javascript コードを埋め込み、script タグで囲む |
| css: | なし | ショートカット | css コードを埋め込み、style タグで囲む |
| sass: | sass | コンパイル時 | sass コードを埋め込み、style タグで囲む |
| scss: | sass | コンパイル時 | scss コードを埋め込み、style タグで囲む |
| less: | less | コンパイル時 | less コードを埋め込み、style タグで囲む |
| coffee: | coffee-script | コンパイル時 | CoffeeScript をコンパイルし、 script タグで囲む |
| markdown: | redcarpet/rdiscount/kramdown | コンパイル時 + 展開 | Markdown をコンパイルし、テキスト中の # \{variables} を展開 |
| textile: | redcloth | コンパイル時 + 展開 | textile をコンパイルし、テキスト中の # \{variables} を展開 |
| rdoc: | rdoc | コンパイル時 + 展開 | RDoc をコンパイルし、テキスト中の # \{variables} を展開 |

埋め込みエンジンは Slim の `Slim::Embedded` フィルタのオプションで直接設定されます。例:

~~~ ruby
Slim::Embedded.options[:markdown] = {auto_ids: false}
~~~

以下埋め込みエンジンの場合はHTMLのattributeも指定できます：

* Javascript
* CSS
* CoffeeScript
* LESS
* SASS
* SCSS

例：

~~~ scss
scss class="myClass":
  $color: #f00;
  body { color: $color; }
~~~

レンダリング結果：

~~~ html
<style class="myClass" type="text/css">body{color:red}</style>
~~~

## Slim の設定

Slim とその基礎となる [Temple](https://github.com/judofyr/temple) は非常に柔軟に設定可能です。
Slim を設定する方法はコンパイル機構に少し依存します。(Rails や [Tilt](https://github.com/rtomayko/tilt))。デフォルトオプションの設定は `Slim::Engine` クラスでいつでも可能です。Rails の 環境設定ファイルで設定可能です。例えば, config/environments/developers.rb で設定したいとします:

### デフォルトオプション

~~~ ruby
# デバック用に html をきれいにインデントし属性をソートしない
Slim::Engine.set_options pretty: true, sort_attrs: false
~~~

ハッシュで直接オプションにアクセスすることもできます:

~~~ ruby
Slim::Engine.options[:pretty] = true
~~~

### 実行時のオプション設定

実行時のオプション設定の方法は2つあります。Tilt テンプレート (`Slim::Template`) の場合, テンプレートを
インスタンス化する時にオプションを設定できます。

~~~ ruby
Slim::Template.new('template.slim', optional_option_hash).render(scope)
~~~

他の方法は Rails に主に関係がありますがスレッド毎にオプション設定を行う方法です:

~~~ slim
Slim::Engine.with_options(option_hash) do
   # ここで作成される Slim エンジンは option_hash を使用します
   # Rails での使用例:
   render :page, layout: true
end
~~~

Rails ではコンパイルされたテンプレートエンジンのコードとオプションはテンプレート毎にキャッシュされ, 後でオプションを変更できないことに注意する必要があります。

~~~ slim
# 最初のレンダリング呼び出し
Slim::Engine.with_options(pretty: true) do
   render :page, layout: true
end

# 2回目のレンダリング呼び出し
Slim::Engine.with_options(pretty: false) do
   render :page, layout: true # :pretty is still true because it is cached
end
~~~

### 設定可能なオプション

次のオプションが `Slim::Engine` によって用意され `Slim::Engine.set_options` で設定することができます。
沢山ありますが, 素晴らしいことに, Slim は設定キーをチェックし, 無効な設定キーを使用しようとしていた場合, エラーを返してくれます。


| 型 | 名前 | デフォルト | 用途 |
| ---- | ---- | ---------- | ---- |
| String | :file | nil | 解析対象のファイル名。  Slim::Template によって自動的に設定されます |
| Integer | :tabsize | 4 | 1 タブあたりのスペース数 (構文解析で利用されます) |
| String | :encoding | "utf-8" | テンプレートのエンコーディングを設定 |
| String | :default_tag | "div" | タグ名が省略されている場合デフォルトのタグとして使用される |
| Hash | :shortcut | \{'.' => {attr: 'class'}, '#' => {attr: 'id'}} | 属性のショートカット |
| Hash | :code_attr_delims | \{'(' => ')', '[' => ']', '{' => '}'} | Ruby コードの属性区切り文字 |
| Hash | :attr_list_delims | \{'(' => ')', '[' => ']', '{' => '}'} | 属性リスト区切り文字 |
| Array&lt;Symbol,String&gt; | :enable_engines | nil <i>(すべて有効)</i> | 有効な埋め込みエンジンリスト (ホワイトリスト) |
| Array&lt;Symbol,String&gt; | :disable_engines | nil <i>(無効なし)</i> | 無効な埋め込みエンジンリスト (ブラックリスト) |
| Boolean | :disable_capture | false (Rails では true) | ブロック内キャプチャ無効 (ブロックはデフォルトのバッファに書き込む)  |
| Boolean | :disable_escape | false | Stringの自動エスケープ無効 |
| Boolean | :use_html_safe | false (Rails では true) | ActiveSupport の String# html_safe? を使う (:disable_escape と一緒に機能する) |
| Symbol | :format | :xhtml | HTML の出力フォーマット (対応フォーマット :html, :xhtml, :xml) |
| String | :attr_quote |  '"'  | HTML の属性を囲む文字 (' または " が可能) |
| Hash | :merge_attrs | \{'class' => ' '} | 複数の html 属性が与えられたときに, 結合に使われる文字 (例: class="class1 class2") |
| Array&lt;String&gt; | :hyphen_attrs | %w(data) | 属性にハッシュが与えられたとき, ハイフンで区切られます。(例: data={a:1, b:2} は data-a="1" data-b="2" のように) |
| Boolean | :sort_attrs | true | 名前順に属性をソート |
| Symbol | :js_wrapper | nil | :commentや :cdata , :both で JavaScript をラップします。:guess を指定することで :format オプションに基いて設定することもできます |
| Boolean | :pretty | false | HTML を綺麗にインデントします。ブロック要素のタグでのみ、インデントされます。 <b>(遅くなります!)</b> |
| String | :indent | '  ' | インデントに使用される文字列 |
| Boolean | :streaming | false (Rails では true, 無効化するにはストリーミングを参照) | ストリーミング出力の有効化, 体感的なパフォーマンスの向上 |
| Class | :generator | Temple::Generators::StringBuffer/ RailsOutputBuffer | Temple コードジェネレータ (デフォルトのジェネレータはStringバッファを生成します) |
| String | :buffer | '_buf' (Rails では '@output_buffer') | バッファに使用される変数 |
| String | :splat_prefix | '*' | アスタリスク(スプラット)属性のプレフィックス |

Temple フィルタによってもっと多くのオプションがサポートされていますが一覧には載せず公式にはサポートしません。
Slim と Temple のコードを確認しなければなりません。

### オプションの優先順位と継承

Slim や Temple のアーキテクチャについてよく知っている開発者は, 別の場所で設定を
上書きすることができます。 Temple はサブクラスがスーパークラスのオプションを上書きできるように
継承メカニズムを採用しています。オプションの優先順位は次のとおりです:

1. `Slim::Template` オプションはエンジン初期化時に適用されます
2. `Slim::Template.options`
3. `Slim::Engine.thread_options`, `Slim::Engine.options`
5. Praser/Filter/Generator `thread_options`, `options` (例: `Slim::Parser`, `Slim::Compiler`)

`Temple::Engine` のようにスーパークラスのオプションを設定することも可能です。しかし, こうするとすべての Temple テンプレートエンジンに影響します。

~~~ ruby
Slim::Engine < Temple::Engine
Slim::Compiler < Temple::Filter
~~~

## プラグイン

Slim はロジックレスモードと I18n, インクルードプラグインを提供しています。プラグインのドキュメントを確認してください。

* [ロジックレスモード](doc/jp/logic_less.md)
* [パーシャルのインクルード](doc/jp/include.md)
* [多言語化/I18n](doc/jp/translator.md)
* [スマートテキストモード](doc/jp/smart.md)

## フレームワークサポート

### Tilt

Slim は生成されたコードをコンパイルするために [Tilt](https://github.com/rtomayko/tilt) を使用します。Slim テンプレートを直接使いたい場合, Tilt インターフェイスが使用できます。

~~~ ruby
Tilt.new['template.slim'].render(scope)
Slim::Template.new('template.slim', optional_option_hash).render(scope)
Slim::Template.new(optional_option_hash) { source }.render(scope)
~~~

optional_option_hash は前述のオプションを持つことができます。スコープはコードが実行されるテンプレートの
オブジェクトです。

### Sinatra

~~~ ruby
require 'sinatra'
require 'slim'

get('/') { slim :index }

 __END__
@@ index
doctype html
html
  head
    title Slim で Sinatra
  body
    h1 Slim は楽しい!
~~~

### Rails

Rails のジェネレータは [slim-rails](https://github.com/slim-template/slim-rails) によって提供されます。
slim-rails は Rails で Slim を使用する場合に必須ではありません。Slim をインストールし Gemfile に `gem 'slim'` を追加するだけです。
後は .slim 拡張子を使うだけです。

#### ストリーミング

HTTP ストリーミングをサポートしているバージョンの Rails であれば, デフォルトで有効化されています。しかし, ストリーミングは体感的なパフォーマンスを改善しているだけであることに注意してください。
レンダリング時間は増加するでしょう。ストリーミングを無効化したい場合, 以下のように設定します:

~~~ ruby
Slim::RailsTemplate.set_options streaming: false
~~~

### Angular2

Slim は Angular2 の構文に対応しています。ただし, いくつかのオプションを設定する必要があります:

#### `splat_prefix` オプション

このオプションは, アスタリスク(スプラット)属性に使用する構文をパーサに指定します。
デフォルト値はアスタリスクです: `splat_prefix: '*'`
アスタリスクは Angular2 でも構造ディレクティブとして `*ngIf` などで使われます。デフォルトの設定値では, Slim と Angular2 の構文は衝突します。

解決方法は 2 つあります:

* `splat_prefix` に 2重アスタリスクのようなカスタム値(`splat_prefix: '**'`)を設定します。これで構造ディレクティブは期待通りに機能するはずです。アスタリスク属性は設定したカスタム値のプレフィックスで書かなければならないので注意してください。
* アスタリスクではない代わりのディレクティブ構文を使います。

#### 属性区切り文字

Angular と Slim はそれぞれの構文で括弧を使います。この場合も解決方法は 2 つあります:
* バインディングに代わりの構文を使う (`bind-...` など)
* 属性区切り文字を波括弧に限定する
```
code_attr_delims: {
 '{' => '}',
},
attr_list_delims: {
 '{' => '}',
},
```

これで次のように書けます:
```
h1{ #var (bind1)="test" [bind2]="ok" [(bind3)]="works?" *ngIf="expr" *ngFor="expression" } {{it works}}
```

コンパイル結果:
```
<h1 #var="" (bind1)="test" [bind2]="ok" [(bind3)]="works?" *ngIf="expr" *ngFor="expression">
  {{it works}}
</h1>
```

## ツール

### Slim コマンド 'slimrb'

gem の 'slim' にはコマンドラインから Slim をテストするための小さなツール 'slimrb' が付属します。

<pre>
$ slimrb --help
Usage: slimrb [options]
    -s, --stdin                      Read input from standard input instead of an input file
        --trace                      Show a full traceback on error
    -c, --compile                    Compile only but do not run
    -e, --erb                        Convert to ERB
        --rails                      Generate rails compatible code (Implies --compile)
    -r, --require library            Load library or plugin with -r slim/plugin
    -p, --pretty                     Produce pretty html
    -o, --option name=code           Set slim option
    -l, --locals Hash|YAML|JSON      Set local variables
    -h, --help                       Show this message
    -v, --version                    Print version
</pre>

'slimrb' で起動し, コードをタイプし Ctrl-d で EOF を送ります。Windows のコマンドプロンプトでは Ctrl-z で EOF を送ります。使い方例:

<pre>
$ slimrb
markdown:
  最初の段落。

  2つ目の段落。

  * 1つ
  * 2つ
  * 3つ

//Enter Ctrl-d
&lt;p&gt;最初の段落。 &lt;/p&gt;

&lt;p&gt;2つめの段落。 &lt;/p&gt;

&lt;ul&gt;
&lt;li&gt;1つ&lt;/li&gt;
&lt;li&gt;2つ&lt;/li&gt;
&lt;li&gt;3つ&lt;/li&gt;
&lt;/ul&gt;
</pre>

### 構文ハイライト

様々なテキストエディタ(Vim や Emacs, Textmateなど)のためのプラグインがあります。:

* [Vim](https://github.com/slim-template/vim-slim)
* [Emacs](https://github.com/slim-template/emacs-slim)
* [Textmate / Sublime Text](https://github.com/slim-template/ruby-slim.tmbundle)
* [Espresso text editor](https://github.com/slim-template/Slim-Sugar)
* [Coda](https://github.com/slim-template/Coda-2-Slim.mode)
* [Atom](https://github.com/slim-template/language-slim)

### テンプレート変換 (HAML, ERB, ...)

* Slim は gem に含まれる `slimrb` や `Slim::ERBConverter` を用いて ERB に変換できます。
* [Haml2Slim converter](https://github.com/slim-template/haml2slim)
* [ERB2Slim, HTML2Slim converter](https://github.com/slim-template/html2slim)

## テスト

### ベンチマーク

  *そうです, Slim は最速の Ruby のテンプレートエンジンです!
   production モードの Slim は Erubis (最速のテンプレートエンジン) と同じくらい高速です。
   どんな理由であれ, あなたが Slim を選択していただければ嬉しいし, 私たちは
   パフォーマンスが障害にならないだろうことを保証します。*

ベンチマークは `rake bench` で実行します。時間が余計にかかりますが遅い解析ベンチマークを
実行したい場合 `slow` オプションを追加できます。

~~~
rake bench slow=1 iterations=1000
~~~

私たちはコミット毎に Travis-CI でベンチマークをとっています。最新のベンチマーク結果はこちらです: <http://travis-ci.org/slim-template/slim>

### テストスイートと継続的インテグレーション

Slim は minitest ベースの拡張性のあるテストスイートを提供します。テストは 'rake test' または
rails のインテグレーションテストの場合 'rake test:rails' で実行できます。

私たちは現在 markdown ファイルで書かれ, 人間が読み書きしやすいテストを試しています: [TESTS.md](test/literate/TESTS.md)

Travis-CI は継続的インテグレーションテストに利用されています: <http://travis-ci.org/slim-template/slim>

Slim は主要な Ruby 実装全てで動作します:

* Ruby 2.0, 2.1, 2.2 および 2.3
* JRuby 1.9 mode
* Rubinius 2.0

## 貢献

Slim の改良を支援したい場合, Git で管理されているプロジェクトを clone してください。

~~~
$ git clone git://github.com/slim-template/slim
~~~

魔法をかけた後 pull request を送ってください。私たちは pull request が大好きです！

Ruby の 2.3.0, 2.2.0, 2.1.0 と 2.0.0 でテストをすることを覚えておいてください。

もしドキュメントの不足を見つけたら, README.md をアップデートして私たちを助けて下さい。Slim に割ける時間がないが, 私たちが知っておくべきことを見つけた場合には issue を送ってください。

## License

Slim は [MIT license](http://www.opensource.org/licenses/MIT) に基づいてリリースされています。

## 作者

* [Daniel Mendler](https://github.com/minad) (Lead developer)
* [Andrew Stone](https://github.com/stonean)
* [Fred Wu](https://github.com/fredwu)

## 寄付と支援

このプロジェクトをサポートしたい場合, Gittip や Flattr のページを見てください。

[![Gittip donate button](http://img.shields.io/gittip/bevry.png)](https://www.gittip.com/min4d/ "Donate weekly to this project using Gittip")
[![Flattr donate button](https://raw.github.com/balupton/flattr-buttons/master/badge-89x18.gif)](https://flattr.com/submit/auto?user_id=min4d&url=http%3A%2F%2Fslim-lang.org%2F "Donate monthly to this project using Flattr")

今のところ, 寄付はホスティング費用 (ドメインなど) に当てられる予定です。

## 議論

* [Google Group](http://groups.google.com/group/slim-template)

## 関連プロジェクト

テンプレートのコンパイルフレームワーク:

* [Temple](https://github.com/judofyr/temple)

フレームワークサポート:

* [Rails generators (slim-rails)](https://github.com/slim-template/slim-rails)
  * [slimkeyfy - Translation string extraction](https://github.com/phrase/slimkeyfy)

構文ハイライト:

* [Vim](https://github.com/slim-template/vim-slim)
* [Emacs](https://github.com/slim-template/emacs-slim)
* [Textmate / Sublime Text](https://github.com/slim-template/ruby-slim.tmbundle)
* [Espresso text editor](https://github.com/slim-template/Slim-Sugar)
* [Coda](https://github.com/slim-template/Coda-2-Slim.mode)
* [Atom](https://github.com/slim-template/language-slim)

静的コード解析:

* [Slim-Lint](https://github.com/sds/slim-lint)
* [SublimeLinter-slim-lint](https://github.com/elstgav/SublimeLinter-slim-lint)

テンプレート変換 (HAML, ERB, ...):

* [Haml2Slim converter](https://github.com/slim-template/haml2slim)
* [ERB2Slim, HTML2Slim converter](https://github.com/slim-template/html2slim)

移植言語/同様の言語:

* [Sliq (Slim/Liquid integration)](https://github.com/slim-template/sliq)
* [Slm (Slim port to Javascript)](https://github.com/slm-lang/slm)
* [Coffee script plugin for Slim](https://github.com/yury/coffee-views)
* [Clojure port of Slim](https://github.com/chaslemley/slim.clj)
* [Hamlet.rb (Similar template language)](https://github.com/gregwebs/hamlet.rb)
* [Plim (Python port of Slim)](https://github.com/2nd/plim)
* [Skim (Slim for Javascript)](https://github.com/jfirebaugh/skim)
* [Emblem.js (Javascript, similar to Slim)](https://github.com/machty/emblem.js)
* [Hamlit (High performance Haml implementation, based on Temple like Slim)](https://github.com/k0kubun/hamlit)
* [Faml (Faster Haml implementation, also using Temple like Slim)](https://github.com/eagletmt/faml)
* [Haml (Older engine which inspired Slim)](https://github.com/haml/haml)
* [Jade (Similar engine for javascript)](https://github.com/visionmedia/jade)
* [Pug (Successor of Jade, Similar engine for javascript)](https://github.com/pugjs/pug)
* [Sweet (Similar engine which also allows to write classes and functions)](https://github.com/joaomdmoura/sweet)
* [Amber (Similar engine for Go)](https://github.com/eknkc/amber)
* [Slang (Slim-inspired templating language for Crystal)](https://github.com/jeromegn/slang)
