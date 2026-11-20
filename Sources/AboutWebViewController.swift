
import UIKit
import WebKit

final class AboutWebViewController: UIViewController, WKNavigationDelegate {
    private let webView = WKWebView(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "О приложении"
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.backgroundColor = .clear
        webView.isOpaque = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        webView.loadHTMLString(Self.html, baseURL: nil)
    }

    private static let html = """
    <!doctype html>
    <html lang="ru">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
      * { box-sizing: border-box; }
      body { margin:0; padding:28px 22px 60px; background:#080814; color:#f5f5ff;
             font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif; }
      .hero { border-radius:24px; padding:28px 24px; background:linear-gradient(135deg,#ff2b86 0%,#7b2bff 100%);
              box-shadow:0 20px 50px rgba(255,43,134,.25); }
      .hero h1 { margin:0; font-size:34px; letter-spacing:-1px; }
      .hero p { margin:8px 0 0; opacity:.85; font-size:14px; }
      h2 { margin:32px 0 12px; font-size:20px; }
      .grid { display:grid; grid-template-columns:1fr 1fr; gap:12px; }
      .card { background:rgba(255,255,255,.06); border:1px solid rgba(255,255,255,.08);
              border-radius:18px; padding:16px; }
      .card b { display:block; font-size:22px; color:#4de3ff; }
      .card span { font-size:12px; opacity:.65; }
      .row { padding:13px 16px; border-radius:14px; background:rgba(255,255,255,.045); margin-bottom:9px;
             font-size:14px; }
      .row::before { content:'✦'; color:#ff2b86; margin-right:10px; }
      .foot { margin-top:30px; text-align:center; opacity:.45; font-size:12px; }
    </style>
    </head>
    <body>
      <div class="hero">
        <h1>ПУЛЬС</h1>
        <p>Мессенджер, собранный как продукт. Без сервера, без внешних ассетов, только Swift и забота о деталях.</p>
      </div>
      <h2>Масштаб</h2>
      <div class="grid">
        <div class="card"><b>29</b><span>чатов</span></div>
        <div class="card"><b>300+</b><span>сообщений</span></div>
        <div class="card"><b>14</b><span>историй</span></div>
        <div class="card"><b>24</b><span>контакта</span></div>
      </div>
      <h2>Что умеет</h2>
      <div class="row">Умные ответы и реакции</div>
      <div class="row">Голосовые, файлы, карты, ссылки</div>
      <div class="row">Звонки с анимированным оверлеем</div>
      <div class="row">Истории с прогрессом и ответами</div>
      <div class="row">Три темы, хаптики, уведомления</div>
      <div class="row">Экспорт данных и сброс демо</div>
      <div class="foot">Сделано в ПУЛЬСЕ · iOS 15+ · Swift / UIKit</div>
    </body>
    </html>
    """
}
