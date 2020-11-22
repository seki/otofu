# OTofu

なにもしないWeb UIフレームワーク、tofuのチュートリアルです。
TofuはX11, Xtのプログラミングの経験を元にデザインしました。
CGI全盛の世代からやってきた非常に古風なアーキテクチャです。

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
今回はパスワードの管理等がめんどうなのでメールで一度限りのパウワードを送信するようにします。

### Mail

最近ではSMTPを利用してメール送信するのになんらかの認証が必要なケースが増えています。
src/mail_config.rbでメール送信の設定をすることにします。利用できるサーバに合わせて書き換えてください。
以下はherokuで利用しやすいSendGridの例です。環境変数で設定してください。

```
Mail.defaults do
  delivery_method :smtp, { :address   => "smtp.sendgrid.net",
                           :port      => 587,
                           :domain    => ENV['SENDGRID_DOMAIN'],
                           :user_name => ENV["SENDGRID_USERNAME"],
                           :password  => ENV["SENDGRID_PASSWORD"],
                           :authentication => :plain,
                           :enable_starttls_auto => true }
end
```

これ以外の例としてiCloudとGMailの設定を調べてみました。（が、どちらも以下の設定を参考に送れたので、特別な情報はありません）
アプリケーション用のパスワードを発行すると送れるようです。

- https://support.apple.com/ja-jp/HT202304
- https://support.google.com/mail/answer/185833?hl=ja

```
Mail.defaults do
  delivery_method :smtp, { :address   => "smtp.mail.me.com",
                           :port      => 587,
                           :user_name => ENV["ICLOUD_USERNAME"],
                           :password  => ENV["ICLOUD_APP_PASSWORD"],
                           :authentication => :plain,
                           :enable_starttls_auto => true }
end
```

```
Mail.defaults do
  delivery_method :smtp, { :address   => "smtp.gmail.com",
                           :port      => 587,
                           :user_name => ENV["GMAIL_USERNAME"],
                           :password  => ENV["GMAIL_APP_PASSWORD"],
                           :authentication => :plain,
                           :enable_starttls_auto => true }
end
```

### ユーティリティ

パラメーターを正規化するメソッドをTofuのベースクラスに追加しておきます。

- エンコードをutf-8
- 空白の削除

常にこれが期待した動作とは言い切れないため、Tofu本体には定義されていません。


```
module Tofu
  class Tofu
    def normalize_string(str_or_param)
      str ,= str_or_param
      return '' unless str
      str.force_encoding('utf-8').strip
    end
  end
end
```

### LoginTofu

LoginTofuはログインにまつわるUIを実現するTofu::Tofuです。
BaseTofuの中に配置して使います。

見た目はlogin.htmlで定義されます。BaseTofuの内側で使われるので、html, bodyなどは書かれていません。

Tofu::TofuはGET/POSTなどでブラウザにUI操作を提供します。Rubyではdo_をプレフィックスとしたメソッドとして定義します。
```
  def do_foo(context, params)
```
contextはto_htmlで渡るのと同じ、WEBrickのリクエストとレスポンスです。
paramsはリクエストから取り出したパラメータです。contextからも取れるので、今となっては不要かもしれませんが互換性のために残されています。

LoginTofuがWidgetとして提供するメソッドは次の三つです。

- do_send(context, params)    # メールアドレスを入力し、メールを送る
- do_login(context, params)   # パスワードを入力し、ログイン処理をする
- do_resend(context, params)  # やりかけの認証を中断して、最初からやり直す

ログイン処理中にしか使わない状態はLoginTofuのインスタンス変数として管理します。

- @confirm = nil              # 送信したパスワード。送信していなければnil。
- @curr_hint = @session.hint  # 未ログイン時に表示する、前回のメールアドレス
- @show = false               # 表示状態

#### do_send

ユーザーがブラウザからE-Mailアドレスを入力したときに呼ばれるメソッドです。

```
    def do_send(context, params)
      email = normalize_string(params['email'])
      return unless valid_email?(email)

      @email = email
      @curr_hint = email

      @confirm = "%06d" % rand(1000000)
      p [:confirm, @confirm]

      send_mail(email, context)
    end
```

1. リクエストから'email'を取り出す
2. emailが有効かどうか検査して@emailに覚える
3. 乱数でパスワードを生成して、@confirmに覚える
4. メールを送信する

通常、do_xxxの中でレスポンスを生成しません。
Tofuのフレームワークは、do_xxxが終わるとlookup_viewで土台のTofu::Tofu（この場合は@base）を選び、
to_htmlを使ってレスポンス（HTML）を生成させます。

メールアドレスの有効性は今回は事前に登録されたものと一致するかどうかで調べています。
（@sessionのvalid_email?で実装されています）

#### do_login

ユーザーがブラウザでパスワードを入力したときに呼ばれるメソッドです。

```
    def do_login(context, params)
      password = normalize_string(params['password'])

      if @confirm == password
        @session.login(@email)
        @confirm = nil
        @show = false
      end
    end
```

1. リクエストから'password'を取り出す
2. @confirmと一致するか調べる
3. @session.loginでセッションのユーザーを変更する
4. メモした状態を忘れ、非表示にする


