# OTofu

なにもしないWeb UIフレームワーク、tofuのチュートリアルです。
TofuはX11, Xtのプログラミングの経験を元にデザインしました。非常に古風なアーキテクチャです。

## 準備

tofuをインストール。

```
% gem install tofu
```

または

```
% sudo gem install tofu
```

### Tofuの役割

tofuは主に三つの部品で構成されます。

- Bartender
- Session
- Tofu

#### Bartender

Bartenderの役割は、httpのリクエストから適切なSessionを見つけて、そのSessionにリクエストを届けることです。
リクエストに対応するSessionが存在しない場合は、新規のSessionを生成します。

BartenderはWEBrickなどとの直接的なインターフェイスです。main.rbではTofuletという部品を介して/にマウントしています。

```
tofu = Tofu::Bartender.new(OTofu::Session, 'otofu')
server.mount('/', Tofu::Tofulet, tofu)
```

#### Session

Sessionはクライアント（ブラウザごと）に生成されるオブジェクトです。Cookieに保存される識別子によって特定されます。
GUIプログラミングでいうとSessionは一つの仮想的な画面、仮想的なウィンドウのようなものです。
ログインの状態など、その画面に固有の情報を保持します。

tofuはWeb UIのみを解決するフレームワークなので、永続化などに関してはなにもしません。

#### Tofu::Tofu

Tofu::Tofu（以下Tofu）はHTMLの部品に相当するオブジェクトです。GUIプログラミングでいうWidgetのようなものです。
TofuはSessionごとに生成されます。クライアントごとにGUI部品がある、といったイメージです。
Sessionは少なくとも一つのTofuを持ちます。00ではBaseという土台のTofuを生成しています。
TofuにはHTMLを生成するためのユーティリティメソッドが用意してあります。
文字列をHTMLに埋め込むためのhメソッドや、URLエンコーディングのためのuなどもその一つです。

Tofuは内部に画面の状態（のようなもの）を保持します。
たとえば、現在のリスト表示は日付順ソートである、とか、値の編集中である、などの見かけの状態をなどです。

また、GUIの操作をサーバーサイドで受け取る係でもあります。
GUIの操作をさせるためのリンクの生成メソッドが用意されています。

なお、Tofu::TofuはDivという名前にしていましたが、検索しづらいので改名しました。

### リクエストとレスポンス

TofuはGUI模したフレームワークなので、リクエスト、つまりGUI操作（状態の更新）と、レスポンス、GUIの描画とを分離して考えます。
これはWebアプリを関数と考えるケースが多いのとだいぶ異なっています。
GUI操作が連続あるいは同時に発生した場合を考えてください。
入力に対していつも同じ出力を返す関数として考えるのではなく、
さまざまな操作がなされた後の最新の状態のスナップショットを使って画面を作ると考えた方が都合がよいのです。
サーバー側に「状態」があり、複数のリクエストから状態を更新する、というのはWebアプリでは当たり前に発生することです。

- リクエストは状態を変更させる
- レスポンスは最新の状態のスナップショット（HTML）を返す

Tofuはこの2フェーズでプログラミングします。

WEBrickに届いたリクエストが処理される様子を示します。

1. BartenderはSessionを探す（「操作」がなければこれで終わり）
2. Tofuを探す
3. Tofuに操作の情報を渡す
4. 内部状態を更新する

レスポンスを組み立てる様子を示します。
すでにSessionは特定されているので、

1. Session#lookup_viewでHTMLを組み立てる土台のTofuを選ぶ
2. Tofu#to_htmlでHTMLを生成

API的なサービス（レスポンスがJSONなどHTML以外のなにか）の場合でもこの原則は同じです。


## 00

実験を進められるか確かめる実験です。

00ディレクトリに移動して、main.rbを実行してください。

```
% ruby main.rb
[2020-11-13 18:00:04] INFO  WEBrick 1.6.0
[2020-11-13 18:00:04] INFO  ruby 2.7.1 (2020-03-31) [x86_64-darwin19]
[2020-11-13 18:00:04] INFO  WEBrick::HTTPServer#start: pid=82365 port=8000
```

ブラウザで http://localhost:8000 にアクセスして、OTofuというバナーがあるか確かめてください。

### main.rb
WEBrickのWebサーバーを作り、Bartenderをマウントします。

### src/app.rb
Tofu::SessionのサブクラスとTofu::Tofuのサブクラスを書きます。

```
module OTofu
  class Session < Tofu::Session
    ...
  end


  class BaseTofu < Tofu::Tofu
    ...
  end
end
```

BaseTofuのクラスのコンテキストで奇妙なメソッド呼び出しがあります。
```
    set_erb(__dir__ + '/base.html')
```
これはbase.htmlの内容をto_htmlメソッドとして定義せよ、という処理です。

### src/base.html
base.htmlはBaseTofuの```to_html(context)```メソッドの定義です。ERBで書きます。
ERBは任意のテキストにrubyスクリプトを埋め込むものです。

base.htmlには次のようなERBのマークアップ部分があります。（他にもあります）

```
    <pre>
      path_info = <%=h context.req.path_info.pretty_inspect %>
      script_name = <%=h context.req.script_name.pretty_inspect %>
      query = <%=h context.req.query.pretty_inspect %>
    </pre>
```

BaseTofuのインスタンスメソッドですから、当然、変数のスコープもBaseTofuのインスタンスになります。
上記では、Tofu::Tofuのhメソッド、仮引数のcontextを利用していますね。
contextは、WEBrickのrequestとresponseのペアです。HTTPのリクエストごとに作られます。

## 01

もうちょっと実際の運用に近い設定を追加します。

### マウントポイント

マウントポイントを/以外にします。

main.rbを変更します。/appにマウントします。
```
tofu = Tofu::Bartender.new(OTofu::Session, 'otofu')
server.mount('/app/', Tofu::Tofulet, tofu)

server.mount_proc('/') {|req, res|
  res['Pragma'] = 'no-store'
  res.set_redirect(WEBrick::HTTPStatus::MovedPermanently, '/app')
}
```
（MovedPermanentlyだとさらに変更するときにブラウザのキャッシュのクリアが必要かもしれない）

マウントポイントが変わると、バナーに書いてあるトップへのリンクなどを書き換える必要があります。
いくつか解決方法が思いつきますが、今回はrootに相当するPathnameオブジェクトを返すメソッドをBaseTofuに追加します。

```
    def pathname(context)
      script_name = context.req_script_name
      script_name = '/' if script_name.empty?
      Pathname.new(script_name)
    end
```

base.htmlの最初にこのメソッドの結果をメモして、静的なリンクの生成に使いましょう。
くどいですが、base.htmlはBaseTofuのto_htmlメソッドの定義をERBで書いたものです。
BaseTofuから利用できるメソッドや変数と協調することができますから、ERBの中に全ての処理を書き下す必要ありません。

```
<%
  root = pathname(context)
%>
```
```
  <a class="navbar-brand" href="<%=h root %>">OTofu</a>
```
```
      <li class="nav-item"><a class="nav-link" href="<%=h root + "./admin/menu" %>">管理者メニュー</a></li>
```

これでマウントポイントを変更するようなことがあってもmain.rbの修正だけで完了します。

### cache-control

ブラウザにキャッシュさせないためにcache-controlを追加します。
リクエストはWEBrickからBartenderを経て、Sessionへ届きます。Sessionのdo_GETメソッドを上書きすると挙動を変更できます。

```
  class BaseTofu < Tofu::Tofu

    def do_GET(context)
      context.res_header('cache-control', 'no-store')
      super(context)
    end
```


### 演習
#### マウントポイントの変更

マウントポイントを/appから/otofuに変更してみましょう。

## 02

ログイン的な機能を追加します。

