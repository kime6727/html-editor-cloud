import SwiftUI

// MARK: - HTML Template
struct HTMLTemplate: Identifiable {
    let id: UUID
    let nameKey: String
    let descriptionKey: String
    let files: [ProjectFile]
    let previewImage: String?
    let category: TemplateCategory
    let isPro: Bool

    var name: String { nameKey.localized }
    var description: String { descriptionKey.localized }

    init(nameKey: String, descriptionKey: String, files: [ProjectFile], previewImage: String? = nil, category: TemplateCategory = .other, isPro: Bool = false) {
        self.id = UUID()
        self.nameKey = nameKey
        self.descriptionKey = descriptionKey
        self.files = files
        self.previewImage = previewImage
        self.category = category
        self.isPro = isPro
    }
    
    enum TemplateCategory: String, CaseIterable {
        case basic, game, animation, effect, component, other
        
        var localized: String {
            switch self {
            case .basic: return "cat_basic".localized
            case .game: return "cat_game".localized
            case .animation: return "cat_animation".localized
            case .effect: return "cat_effect".localized
            case .component: return "cat_component".localized
            case .other: return "cat_other".localized
            }
        }
        
        var icon: String {
            switch self {
            case .basic: return "doc"
            case .game: return "gamecontroller"
            case .animation: return "sparkles"
            case .effect: return "wand.and.stars"
            case .component: return "square.grid.2x2"
            case .other: return "folder"
            }
        }
    }
    
        static var templates: [HTMLTemplate] {
        [
            HTMLTemplate(
                nameKey: "template_blank_name",
                descriptionKey: "template_blank_desc",
                files: [
                    ProjectFile(name: "index", content: HTMLProject.defaultHTML(), type: .html)
                ],
                category: .basic
            ),
            HTMLTemplate(
                nameKey: "template_website_name",
                descriptionKey: "template_website_desc",
                files: [
                    ProjectFile(name: "index", content: HTMLProject.defaultHTML(), type: .html),
                    ProjectFile(name: "style", content: HTMLProject.defaultCSS(), type: .css),
                    ProjectFile(name: "script", content: HTMLProject.defaultJS(), type: .javascript)
                ],
                category: .basic
            ),
            HTMLTemplate(
                nameKey: "template_responsive_name",
                descriptionKey: "template_responsive_desc",
                files: [
                    ProjectFile(name: "index", content: responsiveLayoutHTML, type: .html),
                    ProjectFile(name: "style", content: responsiveLayoutCSS, type: .css)
                ],
                category: .component
            ),
            HTMLTemplate(
                nameKey: "template_login_name",
                descriptionKey: "template_login_desc",
                files: [
                    ProjectFile(name: "index", content: loginFormHTML, type: .html),
                    ProjectFile(name: "style", content: loginFormCSS, type: .css)
                ],
                category: .component
            ),
            HTMLTemplate(
                nameKey: "template_animation_name",
                descriptionKey: "template_animation_desc",
                files: [
                    ProjectFile(name: "index", content: animationHTML, type: .html),
                    ProjectFile(name: "style", content: animationCSS, type: .css)
                ],
                category: .animation
            ),
            HTMLTemplate(
                nameKey: "template_click_name",
                descriptionKey: "template_click_desc",
                files: [
                    ProjectFile(name: "index", content: gameHTML, type: .html),
                    ProjectFile(name: "style", content: gameCSS, type: .css),
                    ProjectFile(name: "game", content: gameJS, type: .javascript)
                ],
                category: .game
            ),
            HTMLTemplate(
                nameKey: "template_snake_name",
                descriptionKey: "template_snake_desc",
                files: [
                    ProjectFile(name: "index", content: snakeGameHTML, type: .html),
                    ProjectFile(name: "style", content: snakeGameCSS, type: .css),
                    ProjectFile(name: "game", content: snakeGameJS, type: .javascript)
                ],
                category: .game
            ),
            HTMLTemplate(
                nameKey: "template_breakout_name",
                descriptionKey: "template_breakout_desc",
                files: [
                    ProjectFile(name: "index", content: breakoutHTML, type: .html),
                    ProjectFile(name: "style", content: breakoutCSS, type: .css),
                    ProjectFile(name: "game", content: breakoutJS, type: .javascript)
                ],
                category: .game,
                isPro: true
            ),
            HTMLTemplate(
                nameKey: "template_memory_name",
                descriptionKey: "template_memory_desc",
                files: [
                    ProjectFile(name: "index", content: memoryHTML, type: .html),
                    ProjectFile(name: "style", content: memoryCSS, type: .css),
                    ProjectFile(name: "game", content: memoryJS, type: .javascript)
                ],
                category: .game
            ),
            HTMLTemplate(
                nameKey: "template_particles_name",
                descriptionKey: "template_particles_desc",
                files: [
                    ProjectFile(name: "index", content: particlesHTML, type: .html),
                    ProjectFile(name: "style", content: particlesCSS, type: .css),
                    ProjectFile(name: "script", content: particlesJS, type: .javascript)
                ],
                category: .effect,
                isPro: true
            ),
            HTMLTemplate(
                nameKey: "template_clock_name",
                descriptionKey: "template_clock_desc",
                files: [
                    ProjectFile(name: "index", content: clockHTML, type: .html),
                    ProjectFile(name: "style", content: clockCSS, type: .css),
                    ProjectFile(name: "script", content: clockJS, type: .javascript)
                ],
                category: .component
            ),
            HTMLTemplate(
                nameKey: "template_cube_name",
                descriptionKey: "template_cube_desc",
                files: [
                    ProjectFile(name: "index", content: cube3dHTML, type: .html),
                    ProjectFile(name: "style", content: cube3dCSS, type: .css)
                ],
                category: .animation,
                isPro: true
            ),
            HTMLTemplate(
                nameKey: "template_typewriter_name",
                descriptionKey: "template_typewriter_desc",
                files: [
                    ProjectFile(name: "index", content: typewriterHTML, type: .html),
                    ProjectFile(name: "style", content: typewriterCSS, type: .css),
                    ProjectFile(name: "script", content: typewriterJS, type: .javascript)
                ],
                category: .effect
            ),
            HTMLTemplate(
                nameKey: "template_todo_name",
                descriptionKey: "template_todo_desc",
                files: [
                    ProjectFile(name: "index", content: todoHTML, type: .html),
                    ProjectFile(name: "style", content: todoCSS, type: .css),
                    ProjectFile(name: "script", content: todoJS, type: .javascript)
                ],
                category: .component
            ),
            HTMLTemplate(
                nameKey: "template_weather_name",
                descriptionKey: "template_weather_desc",
                files: [
                    ProjectFile(name: "index", content: weatherHTML, type: .html),
                    ProjectFile(name: "style", content: weatherCSS, type: .css),
                    ProjectFile(name: "script", content: weatherJS, type: .javascript)
                ],
                category: .component,
                isPro: true
            )
        ]
    }
}

// MARK: - Template Content

private let responsiveLayoutHTML = """
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>响应式布局</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <header>
        <nav>
            <div class="logo">MySite</div>
            <ul>
                <li><a href="#home">首页</a></li>
                <li><a href="#about">关于</a></li>
                <li><a href="#services">服务</a></li>
                <li><a href="#contact">联系</a></li>
            </ul>
        </nav>
    </header>
    <section class="hero">
        <h1>欢迎来到我的网站</h1>
        <p>构建令人惊叹的网页体验</p>
        <button class="cta">开始探索</button>
    </section>
    <section class="features">
        <div class="card">
            <h3>响应式设计</h3>
            <p>完美适配各种设备屏幕</p>
        </div>
        <div class="card">
            <h3>现代技术</h3>
            <p>使用最新的 Web 技术栈</p>
        </div>
        <div class="card">
            <h3>极速加载</h3>
            <p>优化的性能体验</p>
        </div>
    </section>
</body>
</html>
"""

private let responsiveLayoutCSS = """
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, sans-serif; line-height: 1.6; }
header { background: #2c3e50; padding: 1rem 0; position: sticky; top: 0; }
nav { max-width: 1200px; margin: 0 auto; display: flex; justify-content: space-between; align-items: center; padding: 0 2rem; }
.logo { color: white; font-size: 1.5rem; font-weight: bold; }
nav ul { display: flex; list-style: none; gap: 2rem; }
nav a { color: white; text-decoration: none; }
.hero { background: linear-gradient(135deg, #667eea, #764ba2); color: white; text-align: center; padding: 6rem 2rem; }
.hero h1 { font-size: 3rem; margin-bottom: 1rem; }
.cta { background: white; color: #667eea; border: none; padding: 1rem 2rem; border-radius: 50px; font-size: 1.1rem; margin-top: 2rem; cursor: pointer; }
.features { max-width: 1200px; margin: 4rem auto; display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 2rem; padding: 0 2rem; }
.card { background: white; padding: 2rem; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
@media (max-width: 768px) { .hero h1 { font-size: 2rem; } nav ul { gap: 1rem; } }
"""

private let loginFormHTML = """
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>登录</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="login-container">
        <h1>欢迎回来</h1>
        <p class="subtitle">登录您的账户</p>
        <form>
            <div class="form-group">
                <label>邮箱</label>
                <input type="email" placeholder="you@example.com">
            </div>
            <div class="form-group">
                <label>密码</label>
                <input type="password" placeholder="输入密码">
            </div>
            <button type="submit">登录</button>
        </form>
        <div class="links">
            <a href="#">忘记密码？</a>
        </div>
    </div>
</body>
</html>
"""

private let loginFormCSS = """
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, sans-serif; background: linear-gradient(135deg, #667eea, #764ba2); min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }
.login-container { background: white; padding: 2.5rem; border-radius: 16px; box-shadow: 0 10px 40px rgba(0,0,0,0.2); width: 100%; max-width: 400px; }
h1 { text-align: center; margin-bottom: 0.5rem; }
.subtitle { text-align: center; color: #666; margin-bottom: 2rem; }
.form-group { margin-bottom: 1.5rem; }
label { display: block; margin-bottom: 0.5rem; color: #555; font-weight: 500; }
input { width: 100%; padding: 12px 16px; border: 2px solid #e1e1e1; border-radius: 8px; font-size: 16px; transition: border-color 0.3s; }
input:focus { outline: none; border-color: #667eea; }
button { width: 100%; padding: 14px; background: linear-gradient(135deg, #667eea, #764ba2); color: white; border: none; border-radius: 8px; font-size: 16px; font-weight: 600; cursor: pointer; }
.links { text-align: center; margin-top: 1.5rem; }
.links a { color: #667eea; text-decoration: none; }
"""

private let animationHTML = """
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CSS 动画</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <h1>CSS 动画展示</h1>
    <div class="spinner"></div>
    <div class="pulse"></div>
    <div class="bounce">
        <span></span><span></span><span></span>
    </div>
    <div class="card">
        <h2>悬停我！</h2>
        <p>平滑的过渡和变换效果</p>
    </div>
</body>
</html>
"""

private let animationCSS = """
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, sans-serif; background: #1a1a2e; color: white; min-height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 3rem; padding: 2rem; }
h1 { font-size: 2.5rem; background: linear-gradient(45deg, #ff6b6b, #4ecdc4, #45b7d1); background-size: 300% 300%; -webkit-background-clip: text; background-clip: text; -webkit-text-fill-color: transparent; animation: gradient 3s ease infinite; }
@keyframes gradient { 0%, 100% { background-position: 0% 50%; } 50% { background-position: 100% 50%; } }
.spinner { width: 60px; height: 60px; border: 4px solid rgba(255,255,255,0.1); border-top-color: #ff6b6b; border-radius: 50%; animation: spin 1s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.pulse { width: 60px; height: 60px; background: #4ecdc4; border-radius: 50%; animation: pulse 2s ease infinite; }
@keyframes pulse { 0%, 100% { transform: scale(1); opacity: 1; } 50% { transform: scale(1.3); opacity: 0.5; } }
.bounce { display: flex; gap: 10px; }
.bounce span { width: 15px; height: 15px; background: #ff6b6b; border-radius: 50%; animation: bounce 1.4s ease infinite both; }
.bounce span:nth-child(1) { animation-delay: -0.32s; background: #ff6b6b; }
.bounce span:nth-child(2) { animation-delay: -0.16s; background: #4ecdc4; }
.bounce span:nth-child(3) { animation-delay: 0s; background: #45b7d1; }
@keyframes bounce { 0%, 80%, 100% { transform: scale(0); } 40% { transform: scale(1); } }
.card { background: rgba(255,255,255,0.05); padding: 2rem; border-radius: 16px; text-align: center; transition: all 0.3s ease; cursor: pointer; }
.card:hover { transform: translateY(-10px) scale(1.05); background: rgba(255,255,255,0.1); box-shadow: 0 20px 40px rgba(0,0,0,0.3); }
"""

private let gameHTML = """
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>点击方块</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="game-container">
        <div class="loading-screen" id="loadingScreen">
            <div class="loading-spinner"></div>
            <p>加载中...</p>
        </div>
        <div class="start-screen" id="startScreen">
            <div class="game-icon">🎯</div>
            <h1>点击方块</h1>
            <p class="subtitle">快速点击出现的方块获得分数</p>
            <div class="high-score-display">最高分: <span id="highScoreDisplay">0</span></div>
            <button id="startGameBtn" class="primary-btn">开始游戏</button>
            <div class="tips">
                <p>💡 连续点击获得连击加成</p>
                <p>⚡ 速度越快分数越高</p>
            </div>
        </div>
        <div class="game-screen" id="gameScreen" style="display:none;">
            <div class="top-bar">
                <button id="pauseBtn" class="icon-btn">⏸️</button>
                <div class="score-board">
                    <div class="score-item">
                        <span class="label">得分</span>
                        <b id="score">0</b>
                    </div>
                    <div class="score-item">
                        <span class="label">连击</span>
                        <b id="combo">0</b>
                    </div>
                    <div class="score-item">
                        <span class="label">时间</span>
                        <b id="time">30</b>
                    </div>
                </div>
                <button id="soundBtn" class="icon-btn">🔊</button>
            </div>
            <div class="combo-display" id="comboDisplay"></div>
            <div class="grid" id="grid"></div>
        </div>
        <div class="pause-overlay" id="pauseOverlay" style="display:none;">
            <div class="pause-card">
                <h2>游戏暂停</h2>
                <button id="resumeBtn" class="primary-btn">继续游戏</button>
                <button id="restartBtn" class="secondary-btn">重新开始</button>
            </div>
        </div>
    </div>
    <script src="game.js"></script>
</body>
</html>
"""

private let gameCSS = """
* { margin: 0; padding: 0; box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
body { font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif; background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; overflow: hidden; position: relative; user-select: none; -webkit-user-select: none; }
body::before { content: ''; position: fixed; top: -50%; left: -50%; width: 200%; height: 200%; background: radial-gradient(circle, rgba(102,126,234,0.1) 0%, transparent 70%); animation: bgRotate 20s linear infinite; pointer-events: none; }
@keyframes bgRotate { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
.game-container { text-align: center; position: relative; z-index: 1; width: 100%; max-width: 400px; }
.loading-screen { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: linear-gradient(135deg, #1a1a2e, #16213e); display: flex; flex-direction: column; align-items: center; justify-content: center; z-index: 2000; transition: opacity 0.5s; }
.loading-screen.hidden { opacity: 0; pointer-events: none; }
.loading-spinner { width: 50px; height: 50px; border: 4px solid rgba(255,255,255,0.1); border-top-color: #667eea; border-radius: 50%; animation: spin 1s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.loading-screen p { color: white; margin-top: 20px; font-size: 1.1rem; }
.start-screen { animation: fadeInUp 0.6s ease-out; }
@keyframes fadeInUp { from { opacity: 0; transform: translateY(30px); } to { opacity: 1; transform: translateY(0); } }
.game-icon { font-size: 5rem; margin-bottom: 20px; animation: bounce 2s ease-in-out infinite; }
@keyframes bounce { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-15px); } }
h1 { color: white; margin-bottom: 10px; font-size: 2.5rem; text-shadow: 0 0 20px rgba(102,126,234,0.5), 0 0 40px rgba(118,75,162,0.3); }
.subtitle { color: rgba(255,255,255,0.7); font-size: 1rem; margin-bottom: 30px; }
.high-score-display { background: rgba(255,215,0,0.1); border: 1px solid rgba(255,215,0,0.3); padding: 12px 25px; border-radius: 16px; margin-bottom: 25px; color: #ffd700; font-size: 1.2rem; font-weight: bold; }
.primary-btn { background: linear-gradient(135deg, #667eea, #764ba2); color: white; border: none; padding: 16px 60px; border-radius: 30px; font-size: 1.3rem; font-weight: bold; cursor: pointer; box-shadow: 0 8px 25px rgba(102,126,234,0.4); transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); position: relative; overflow: hidden; }
.primary-btn::before { content: ''; position: absolute; top: 0; left: -100%; width: 100%; height: 100%; background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent); transition: left 0.5s; }
.primary-btn:active::before { left: 100%; }
.primary-btn:active { transform: scale(0.95); }
.secondary-btn { background: rgba(255,255,255,0.1); color: white; border: 1px solid rgba(255,255,255,0.2); padding: 14px 50px; border-radius: 30px; font-size: 1.1rem; font-weight: bold; cursor: pointer; transition: all 0.3s; }
.secondary-btn:active { background: rgba(255,255,255,0.2); transform: scale(0.95); }
.tips { margin-top: 30px; color: rgba(255,255,255,0.5); font-size: 0.9rem; }
.tips p { margin: 8px 0; }
.top-bar { display: flex; align-items: center; justify-content: space-between; margin-bottom: 15px; padding: 0 5px; }
.icon-btn { background: rgba(255,255,255,0.1); border: none; width: 40px; height: 40px; border-radius: 12px; font-size: 1.2rem; cursor: pointer; transition: all 0.2s; }
.icon-btn:active { background: rgba(255,255,255,0.2); transform: scale(0.9); }
.score-board { display: flex; gap: 20px; background: rgba(255,255,255,0.1); backdrop-filter: blur(10px); padding: 12px 20px; border-radius: 16px; border: 1px solid rgba(255,255,255,0.2); box-shadow: 0 8px 32px rgba(0,0,0,0.2); }
.score-item { text-align: center; }
.score-item .label { display: block; color: rgba(255,255,255,0.6); font-size: 0.75rem; margin-bottom: 4px; }
.score-item b { color: #ffd700; font-size: 1.3rem; transition: all 0.3s; }
.score-item b.pop { animation: scorePop 0.3s ease-out; }
@keyframes scorePop { 0% { transform: scale(1); } 50% { transform: scale(1.5); color: #ff6b6b; } 100% { transform: scale(1); } }
.combo-display { height: 30px; margin-bottom: 10px; font-size: 1.5rem; font-weight: bold; color: #ff9ff3; text-shadow: 0 0 20px rgba(255,159,243,0.5); opacity: 0; transition: all 0.3s; }
.combo-display.active { opacity: 1; animation: comboPulse 0.5s ease-out; }
@keyframes comboPulse { 0% { transform: scale(0.5); } 50% { transform: scale(1.2); } 100% { transform: scale(1); } }
.grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; max-width: 320px; margin: 0 auto; padding: 15px; background: rgba(255,255,255,0.05); backdrop-filter: blur(10px); border-radius: 20px; border: 1px solid rgba(255,255,255,0.1); box-shadow: 0 8px 32px rgba(0,0,0,0.3), inset 0 0 20px rgba(255,255,255,0.05); }
.cell { width: 90px; height: 90px; background: linear-gradient(145deg, rgba(255,255,255,0.1), rgba(255,255,255,0.05)); border-radius: 16px; cursor: pointer; transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1); position: relative; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.1); }
.cell::before { content: ''; position: absolute; top: 50%; left: 50%; width: 0; height: 0; background: radial-gradient(circle, rgba(255,255,255,0.3), transparent); border-radius: 50%; transform: translate(-50%, -50%); transition: width 0.4s, height 0.4s; }
.cell:active::before { width: 200px; height: 200px; }
.cell.active { background: linear-gradient(135deg, #ff6b6b, #ee5a6f); transform: scale(1.05); box-shadow: 0 0 30px rgba(255,107,107,0.6), 0 8px 25px rgba(0,0,0,0.3); animation: cellPulse 0.8s ease-in-out infinite; }
@keyframes cellPulse { 0%, 100% { box-shadow: 0 0 30px rgba(255,107,107,0.6), 0 8px 25px rgba(0,0,0,0.3); } 50% { box-shadow: 0 0 50px rgba(255,107,107,0.8), 0 8px 35px rgba(0,0,0,0.4); } }
.cell.active::after { content: ''; position: absolute; top: 10%; left: 10%; width: 30%; height: 30%; background: rgba(255,255,255,0.3); border-radius: 50%; filter: blur(5px); }
.cell:active { transform: scale(0.95); }
.pause-overlay { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.8); backdrop-filter: blur(10px); display: flex; align-items: center; justify-content: center; z-index: 1000; animation: fadeIn 0.3s ease-out; }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
.pause-card { background: linear-gradient(135deg, #1a1a2e, #16213e); padding: 40px; border-radius: 24px; text-align: center; border: 1px solid rgba(255,255,255,0.2); box-shadow: 0 20px 60px rgba(0,0,0,0.5); animation: slideUp 0.4s cubic-bezier(0.4, 0, 0.2, 1); }
@keyframes slideUp { from { transform: translateY(50px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
.pause-card h2 { color: white; margin-bottom: 30px; font-size: 2rem; }
.pause-card button { display: block; width: 100%; margin: 10px 0; }
.game-over-overlay { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.85); backdrop-filter: blur(10px); display: flex; align-items: center; justify-content: center; z-index: 1000; animation: fadeIn 0.3s ease-out; }
.game-over-card { background: linear-gradient(135deg, #1a1a2e, #16213e); padding: 40px; border-radius: 24px; text-align: center; border: 1px solid rgba(255,255,255,0.2); box-shadow: 0 20px 60px rgba(0,0,0,0.5); animation: slideUp 0.4s cubic-bezier(0.4, 0, 0.2, 1); max-width: 350px; width: 90%; }
.game-over-card .result-icon { font-size: 4rem; margin-bottom: 15px; }
.game-over-card h2 { color: white; font-size: 2rem; margin-bottom: 10px; }
.game-over-card .final-score { color: #ffd700; font-size: 3.5rem; font-weight: bold; margin: 15px 0; }
.game-over-card .stats { display: flex; justify-content: center; gap: 30px; margin: 20px 0; }
.game-over-card .stat-item { text-align: center; }
.game-over-card .stat-value { color: #4ecdc4; font-size: 1.5rem; font-weight: bold; }
.game-over-card .stat-label { color: rgba(255,255,255,0.6); font-size: 0.85rem; margin-top: 5px; }
.game-over-card .new-record { color: #ff9ff3; font-size: 1.1rem; margin: 10px 0; animation: recordPulse 1s ease-in-out infinite; }
@keyframes recordPulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.6; } }
.game-over-card button { display: block; width: 100%; margin: 10px 0; }
.particle { position: fixed; pointer-events: none; border-radius: 50%; animation: particleFly 0.6s ease-out forwards; z-index: 999; }
@keyframes particleFly { 0% { transform: translate(0, 0) scale(1); opacity: 1; } 100% { transform: translate(var(--tx), var(--ty)) scale(0); opacity: 0; } }
.score-popup { position: fixed; color: #ffd700; font-weight: bold; font-size: 1.5rem; pointer-events: none; animation: floatUp 0.8s ease-out forwards; text-shadow: 0 0 10px rgba(255,215,0,0.5); z-index: 999; }
@keyframes floatUp { 0% { transform: translateY(0) scale(1); opacity: 1; } 100% { transform: translateY(-60px) scale(1.2); opacity: 0; } }
.screen-shake { animation: shake 0.3s ease-out; }
@keyframes shake { 0%, 100% { transform: translateX(0); } 25% { transform: translateX(-5px); } 75% { transform: translateX(5px); } }
@media (max-width: 380px) { .cell { width: 80px; height: 80px; } h1 { font-size: 2rem; } .score-board { gap: 15px; padding: 10px 15px; } }
"""

private let gameJS = """
const grid = document.getElementById('grid');
const scoreEl = document.getElementById('score');
const comboEl = document.getElementById('combo');
const timeEl = document.getElementById('time');
const comboDisplay = document.getElementById('comboDisplay');
const loadingScreen = document.getElementById('loadingScreen');
const startScreen = document.getElementById('startScreen');
const gameScreen = document.getElementById('gameScreen');
const pauseOverlay = document.getElementById('pauseOverlay');
const highScoreDisplay = document.getElementById('highScoreDisplay');

let score = 0, timeLeft = 30, activeCell = null, timer = null, gameActive = false;
let combo = 0, comboTimer = null, maxCombo = 0;
let soundEnabled = true, isPaused = false;
let audioCtx = null;

const AudioSystem = {
    init() {
        if (!audioCtx) {
            audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        }
    },
    playClick() {
        if (!soundEnabled || !audioCtx) return;
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.frequency.setValueAtTime(800, audioCtx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(1200, audioCtx.currentTime + 0.1);
        gain.gain.setValueAtTime(0.3, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.1);
        osc.start(audioCtx.currentTime);
        osc.stop(audioCtx.currentTime + 0.1);
    },
    playCombo() {
        if (!soundEnabled || !audioCtx) return;
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.type = 'sine';
        osc.frequency.setValueAtTime(600 + combo * 50, audioCtx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(1000 + combo * 100, audioCtx.currentTime + 0.15);
        gain.gain.setValueAtTime(0.4, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.15);
        osc.start(audioCtx.currentTime);
        osc.stop(audioCtx.currentTime + 0.15);
    },
    playGameOver() {
        if (!soundEnabled || !audioCtx) return;
        [0, 0.15, 0.3].forEach((delay, i) => {
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.connect(gain);
            gain.connect(audioCtx.destination);
            osc.frequency.setValueAtTime(400 - i * 100, audioCtx.currentTime + delay);
            gain.gain.setValueAtTime(0.3, audioCtx.currentTime + delay);
            gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + delay + 0.2);
            osc.start(audioCtx.currentTime + delay);
            osc.stop(audioCtx.currentTime + delay + 0.2);
        });
    },
    playNewRecord() {
        if (!soundEnabled || !audioCtx) return;
        [0, 0.1, 0.2, 0.3].forEach((delay, i) => {
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.connect(gain);
            gain.connect(audioCtx.destination);
            osc.type = 'sine';
            osc.frequency.setValueAtTime(500 + i * 200, audioCtx.currentTime + delay);
            gain.gain.setValueAtTime(0.3, audioCtx.currentTime + delay);
            gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + delay + 0.2);
            osc.start(audioCtx.currentTime + delay);
            osc.stop(audioCtx.currentTime + delay + 0.2);
        });
    }
};

function hapticFeedback(type) {
    if (window.antigravity && window.antigravity.haptic) {
        window.antigravity.haptic(type);
    } else if (navigator.vibrate) {
        const patterns = { light: 10, medium: 20, heavy: 30, success: [30, 50, 30] };
        navigator.vibrate(patterns[type] || 10);
    }
}

function getHighScore() {
    return parseInt(localStorage.getItem('clickBlockHighScore') || '0');
}

function setHighScore(score) {
    localStorage.setItem('clickBlockHighScore', score.toString());
}

function showScreen(screen) {
    [loadingScreen, startScreen, gameScreen].forEach(s => s.style.display = 'none');
    screen.style.display = 'block';
}

function updateComboDisplay() {
    if (combo >= 3) {
        comboDisplay.textContent = `🔥 ${combo} 连击!`;
        comboDisplay.className = 'combo-display active';
        comboDisplay.style.animation = 'none';
        void comboDisplay.offsetWidth;
        comboDisplay.style.animation = 'comboPulse 0.5s ease-out';
    } else {
        comboDisplay.className = 'combo-display';
    }
}

function resetCombo() {
    combo = 0;
    comboEl.textContent = '0';
    comboDisplay.className = 'combo-display';
    if (comboTimer) clearTimeout(comboTimer);
}

function addCombo() {
    combo++;
    if (combo > maxCombo) maxCombo = combo;
    comboEl.textContent = combo;
    comboEl.classList.remove('pop');
    void comboEl.offsetWidth;
    comboEl.classList.add('pop');
    updateComboDisplay();
    if (comboTimer) clearTimeout(comboTimer);
    comboTimer = setTimeout(resetCombo, 2000);
    if (combo >= 3) {
        AudioSystem.playCombo();
        hapticFeedback('medium');
    }
}

for (let i = 0; i < 9; i++) {
    const cell = document.createElement('div');
    cell.className = 'cell';
    cell.addEventListener('click', (e) => {
        if (!gameActive || isPaused) return;
        if (cell === activeCell) {
            const comboMultiplier = combo >= 5 ? 3 : combo >= 3 ? 2 : 1;
            const points = comboMultiplier;
            score += points;
            scoreEl.textContent = score;
            scoreEl.classList.remove('pop');
            void scoreEl.offsetWidth;
            scoreEl.classList.add('pop');
            addCombo();
            AudioSystem.playClick();
            hapticFeedback('light');
            createParticles(e.clientX, e.clientY);
            showScorePopup(e.clientX, e.clientY, points);
            if (combo >= 5) {
                document.querySelector('.game-container').classList.add('screen-shake');
                setTimeout(() => document.querySelector('.game-container').classList.remove('screen-shake'), 300);
            }
            cell.classList.remove('active');
            activeCell = null;
            const spawnDelay = Math.max(100, 200 - combo * 10);
            setTimeout(spawnBlock, spawnDelay);
        }
    });
    grid.appendChild(cell);
}

function createParticles(x, y) {
    const colors = ['#ff6b6b', '#ffd700', '#4ecdc4', '#ff9ff3', '#54a0ff'];
    const count = Math.min(8 + combo, 15);
    for (let i = 0; i < count; i++) {
        const particle = document.createElement('div');
        particle.className = 'particle';
        const size = Math.random() * 10 + 5;
        const angle = (Math.PI * 2 * i) / count;
        const distance = Math.random() * 60 + 40;
        const tx = Math.cos(angle) * distance;
        const ty = Math.sin(angle) * distance;
        particle.style.cssText = `width: ${size}px; height: ${size}px; background: ${colors[Math.floor(Math.random() * colors.length)]}; left: ${x}px; top: ${y}px; --tx: ${tx}px; --ty: ${ty}px;`;
        document.body.appendChild(particle);
        setTimeout(() => particle.remove(), 600);
    }
}

function showScorePopup(x, y, points) {
    const popup = document.createElement('div');
    popup.className = 'score-popup';
    popup.textContent = `+${points}`;
    popup.style.left = x + 'px';
    popup.style.top = y + 'px';
    if (points >= 3) {
        popup.style.color = '#ff9ff3';
        popup.style.fontSize = '2rem';
    }
    document.body.appendChild(popup);
    setTimeout(() => popup.remove(), 800);
}

function spawnBlock() {
    if (!gameActive || isPaused) return;
    if (activeCell) activeCell.classList.remove('active');
    const cells = document.querySelectorAll('.cell');
    activeCell = cells[Math.floor(Math.random() * cells.length)];
    activeCell.classList.add('active');
}

function startGame() {
    AudioSystem.init();
    score = 0; timeLeft = 30; combo = 0; maxCombo = 0; gameActive = true; isPaused = false;
    scoreEl.textContent = '0'; timeEl.textContent = '30'; comboEl.textContent = '0';
    comboDisplay.className = 'combo-display';
    showScreen(gameScreen);
    spawnBlock();
    timer = setInterval(() => {
        timeLeft--; timeEl.textContent = timeLeft;
        if (timeLeft <= 10) {
            timeEl.style.color = '#ff6b6b';
        }
        if (timeLeft <= 0) {
            clearInterval(timer);
            gameActive = false;
            if (comboTimer) clearTimeout(comboTimer);
            if (activeCell) activeCell.classList.remove('active');
            timeEl.style.color = '#ffd700';
            showGameOver();
        }
    }, 1000);
}

function pauseGame() {
    if (!gameActive) return;
    isPaused = true;
    clearInterval(timer);
    pauseOverlay.style.display = 'flex';
    hapticFeedback('light');
}

function resumeGame() {
    isPaused = false;
    pauseOverlay.style.display = 'none';
    gameActive = true;
    timer = setInterval(() => {
        timeLeft--; timeEl.textContent = timeLeft;
        if (timeLeft <= 10) timeEl.style.color = '#ff6b6b';
        if (timeLeft <= 0) {
            clearInterval(timer);
            gameActive = false;
            if (comboTimer) clearTimeout(comboTimer);
            if (activeCell) activeCell.classList.remove('active');
            timeEl.style.color = '#ffd700';
            showGameOver();
        }
    }, 1000);
    hapticFeedback('light');
}

function restartGame() {
    pauseOverlay.style.display = 'none';
    startGame();
}

function toggleSound() {
    soundEnabled = !soundEnabled;
    document.getElementById('soundBtn').textContent = soundEnabled ? '🔊' : '🔇';
    hapticFeedback('light');
}

function showGameOver() {
    AudioSystem.playGameOver();
    const highScore = getHighScore();
    const isNewRecord = score > highScore;
    if (isNewRecord) {
        setHighScore(score);
        AudioSystem.playNewRecord();
    }
    const overlay = document.createElement('div');
    overlay.className = 'game-over-overlay';
    overlay.innerHTML = `
        <div class="game-over-card">
            <div class="result-icon">${isNewRecord ? '🏆' : '🎮'}</div>
            <h2>游戏结束</h2>
            <div class="final-score">${score}</div>
            ${isNewRecord ? '<div class="new-record">🎉 新纪录！</div>' : `<div style="color: rgba(255,255,255,0.6); margin-bottom: 10px;">最高分: ${highScore}</div>`}
            <div class="stats">
                <div class="stat-item">
                    <div class="stat-value">${maxCombo}</div>
                    <div class="stat-label">最大连击</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value">${Math.round(score / 30 * 10) / 10}</div>
                    <div class="stat-label">每秒得分</div>
                </div>
            </div>
            <button onclick="this.closest('.game-over-overlay').remove(); showScreen(startScreen); updateHighScoreDisplay();" class="primary-btn">再来一次</button>
        </div>
    `;
    document.body.appendChild(overlay);
    overlay.addEventListener('click', (e) => { if (e.target === overlay) { overlay.remove(); showScreen(startScreen); updateHighScoreDisplay(); } });
}

function updateHighScoreDisplay() {
    highScoreDisplay.textContent = getHighScore();
}

document.getElementById('startGameBtn').addEventListener('click', startGame);
document.getElementById('pauseBtn').addEventListener('click', pauseGame);
document.getElementById('resumeBtn').addEventListener('click', resumeGame);
document.getElementById('restartBtn').addEventListener('click', restartGame);
document.getElementById('soundBtn').addEventListener('click', toggleSound);

window.addEventListener('load', () => {
    updateHighScoreDisplay();
    setTimeout(() => loadingScreen.classList.add('hidden'), 500);
    setTimeout(() => loadingScreen.remove(), 1000);
});
"""

private let snakeGameHTML = """
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>贪吃蛇</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="game-wrapper">
        <div class="loading-screen" id="loadingScreen">
            <div class="loading-spinner"></div>
            <p>加载中...</p>
        </div>
        <div class="start-screen" id="startScreen">
            <div class="game-icon">🐍</div>
            <h1>贪吃蛇</h1>
            <p class="subtitle">控制蛇的方向吃食物获得分数</p>
            <div class="high-score-display">最高分: <span id="highScoreDisplay">0</span></div>
            <button id="startGameBtn" class="primary-btn">开始游戏</button>
            <div class="tips">
                <p>🎮 使用方向键或滑动屏幕控制</p>
                <p>⚡ 连续吃食物获得连击加成</p>
            </div>
        </div>
        <div class="game-screen" id="gameScreen" style="display:none;">
            <div class="top-bar">
                <button id="pauseBtn" class="icon-btn">⏸️</button>
                <div class="score-board">
                    <div class="score-item">
                        <span class="label">得分</span>
                        <span id="score">0</span>
                    </div>
                    <div class="score-item">
                        <span class="label">连击</span>
                        <span id="combo">0</span>
                    </div>
                    <div class="score-item">
                        <span class="label">长度</span>
                        <span id="length">1</span>
                    </div>
                </div>
                <button id="soundBtn" class="icon-btn">🔊</button>
            </div>
            <div class="combo-display" id="comboDisplay"></div>
            <canvas id="game" width="300" height="300"></canvas>
            <div class="controls">
                <button id="up" class="ctrl-btn">↑</button>
                <div>
                    <button id="left" class="ctrl-btn">←</button>
                    <button id="down" class="ctrl-btn">↓</button>
                    <button id="right" class="ctrl-btn">→</button>
                </div>
            </div>
        </div>
        <div class="pause-overlay" id="pauseOverlay" style="display:none;">
            <div class="pause-card">
                <h2>游戏暂停</h2>
                <button id="resumeBtn" class="primary-btn">继续游戏</button>
                <button id="restartBtn" class="secondary-btn">重新开始</button>
            </div>
        </div>
    </div>
    <script src="game.js"></script>
</body>
</html>
"""

private let snakeGameCSS = """
* { margin: 0; padding: 0; box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
body { font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif; background: linear-gradient(135deg, #0a0a0a 0%, #1a1a2e 50%, #0f3460 100%); color: white; display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 20px; overflow: hidden; position: relative; user-select: none; -webkit-user-select: none; }
body::before { content: ''; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: radial-gradient(circle at 50% 50%, rgba(78,205,196,0.05) 0%, transparent 50%); pointer-events: none; }
.game-wrapper { text-align: center; position: relative; z-index: 1; width: 100%; max-width: 380px; }
.loading-screen { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: linear-gradient(135deg, #0a0a0a, #1a1a2e); display: flex; flex-direction: column; align-items: center; justify-content: center; z-index: 2000; transition: opacity 0.5s; }
.loading-screen.hidden { opacity: 0; pointer-events: none; }
.loading-spinner { width: 50px; height: 50px; border: 4px solid rgba(255,255,255,0.1); border-top-color: #4ecdc4; border-radius: 50%; animation: spin 1s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.loading-screen p { color: white; margin-top: 20px; font-size: 1.1rem; }
.start-screen { animation: fadeInUp 0.6s ease-out; }
@keyframes fadeInUp { from { opacity: 0; transform: translateY(30px); } to { opacity: 1; transform: translateY(0); } }
.game-icon { font-size: 5rem; margin-bottom: 20px; animation: bounce 2s ease-in-out infinite; }
@keyframes bounce { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-15px); } }
h1 { margin-bottom: 10px; font-size: 2.5rem; background: linear-gradient(45deg, #4ecdc4, #7eddd8, #45b7d1); background-size: 200% 200%; -webkit-background-clip: text; background-clip: text; -webkit-text-fill-color: transparent; animation: gradientShift 3s ease infinite; }
@keyframes gradientShift { 0%, 100% { background-position: 0% 50%; } 50% { background-position: 100% 50%; } }
.subtitle { color: rgba(255,255,255,0.7); font-size: 1rem; margin-bottom: 30px; }
.high-score-display { background: rgba(255,215,0,0.1); border: 1px solid rgba(255,215,0,0.3); padding: 12px 25px; border-radius: 16px; margin-bottom: 25px; color: #ffd700; font-size: 1.2rem; font-weight: bold; }
.primary-btn { background: linear-gradient(135deg, #4ecdc4, #3db8b0); color: #0a0a0a; border: none; padding: 16px 60px; border-radius: 30px; font-size: 1.3rem; font-weight: bold; cursor: pointer; box-shadow: 0 8px 25px rgba(78,205,196,0.4); transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); position: relative; overflow: hidden; }
.primary-btn::before { content: ''; position: absolute; top: 0; left: -100%; width: 100%; height: 100%; background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent); transition: left 0.5s; }
.primary-btn:active::before { left: 100%; }
.primary-btn:active { transform: scale(0.95); }
.secondary-btn { background: rgba(255,255,255,0.1); color: white; border: 1px solid rgba(255,255,255,0.2); padding: 14px 50px; border-radius: 30px; font-size: 1.1rem; font-weight: bold; cursor: pointer; transition: all 0.3s; }
.secondary-btn:active { background: rgba(255,255,255,0.2); transform: scale(0.95); }
.tips { margin-top: 30px; color: rgba(255,255,255,0.5); font-size: 0.9rem; }
.tips p { margin: 8px 0; }
.top-bar { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; padding: 0 5px; }
.icon-btn { background: rgba(255,255,255,0.1); border: none; width: 40px; height: 40px; border-radius: 12px; font-size: 1.2rem; cursor: pointer; transition: all 0.2s; }
.icon-btn:active { background: rgba(255,255,255,0.2); transform: scale(0.9); }
.score-board { display: flex; gap: 18px; background: rgba(255,255,255,0.1); backdrop-filter: blur(10px); padding: 10px 18px; border-radius: 16px; border: 1px solid rgba(255,255,255,0.2); box-shadow: 0 8px 32px rgba(0,0,0,0.2); }
.score-item { text-align: center; }
.score-item .label { display: block; color: rgba(255,255,255,0.6); font-size: 0.7rem; margin-bottom: 3px; }
.score-item span { color: #ffd700; font-size: 1.2rem; font-weight: bold; transition: all 0.3s; }
.score-item span.pop { animation: scorePop 0.3s ease-out; }
@keyframes scorePop { 0% { transform: scale(1); } 50% { transform: scale(1.5); color: #ff6b6b; } 100% { transform: scale(1); } }
.combo-display { height: 25px; margin-bottom: 8px; font-size: 1.3rem; font-weight: bold; color: #ff9ff3; text-shadow: 0 0 20px rgba(255,159,243,0.5); opacity: 0; transition: all 0.3s; }
.combo-display.active { opacity: 1; animation: comboPulse 0.5s ease-out; }
@keyframes comboPulse { 0% { transform: scale(0.5); } 50% { transform: scale(1.2); } 100% { transform: scale(1); } }
canvas { background: linear-gradient(135deg, #0a0a0a, #111111); border: 3px solid #4ecdc4; border-radius: 16px; display: block; margin: 0 auto 12px; box-shadow: 0 0 30px rgba(78,205,196,0.3), 0 10px 40px rgba(0,0,0,0.5), inset 0 0 20px rgba(78,205,196,0.1); }
.controls { display: flex; flex-direction: column; align-items: center; gap: 8px; }
.controls div { display: flex; gap: 8px; }
.ctrl-btn { width: 65px; height: 65px; background: linear-gradient(145deg, #4ecdc4, #3db8b0); border: none; border-radius: 16px; color: #0a0a0a; font-size: 1.5rem; font-weight: bold; cursor: pointer; box-shadow: 0 6px 20px rgba(78,205,196,0.4); transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1); position: relative; overflow: hidden; }
.ctrl-btn::before { content: ''; position: absolute; top: 50%; left: 50%; width: 0; height: 0; background: rgba(255,255,255,0.3); border-radius: 50%; transform: translate(-50%, -50%); transition: width 0.3s, height 0.3s; }
.ctrl-btn:active::before { width: 150px; height: 150px; }
.ctrl-btn:active { transform: scale(0.95); box-shadow: 0 4px 15px rgba(78,205,196,0.3); }
.pause-overlay { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.8); backdrop-filter: blur(10px); display: flex; align-items: center; justify-content: center; z-index: 1000; animation: fadeIn 0.3s ease-out; }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
.pause-card { background: linear-gradient(135deg, #1a1a2e, #16213e); padding: 40px; border-radius: 24px; text-align: center; border: 1px solid rgba(255,255,255,0.2); box-shadow: 0 20px 60px rgba(0,0,0,0.5); animation: slideUp 0.4s cubic-bezier(0.4, 0, 0.2, 1); }
@keyframes slideUp { from { transform: translateY(50px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
.pause-card h2 { color: white; margin-bottom: 30px; font-size: 2rem; }
.pause-card button { display: block; width: 100%; margin: 10px 0; }
.game-over-overlay { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.85); backdrop-filter: blur(10px); display: flex; align-items: center; justify-content: center; z-index: 1000; animation: fadeIn 0.3s ease-out; }
.game-over-card { background: linear-gradient(135deg, #1a1a2e, #16213e); padding: 40px; border-radius: 24px; text-align: center; border: 1px solid rgba(255,255,255,0.2); box-shadow: 0 20px 60px rgba(0,0,0,0.5); animation: slideUp 0.4s cubic-bezier(0.4, 0, 0.2, 1); max-width: 350px; width: 90%; }
.game-over-card .result-icon { font-size: 4rem; margin-bottom: 15px; }
.game-over-card h2 { color: white; font-size: 2rem; margin-bottom: 10px; }
.game-over-card .final-score { color: #ffd700; font-size: 3.5rem; font-weight: bold; margin: 15px 0; }
.game-over-card .stats { display: flex; justify-content: center; gap: 25px; margin: 20px 0; }
.game-over-card .stat-item { text-align: center; }
.game-over-card .stat-value { color: #4ecdc4; font-size: 1.5rem; font-weight: bold; }
.game-over-card .stat-label { color: rgba(255,255,255,0.6); font-size: 0.85rem; margin-top: 5px; }
.game-over-card .new-record { color: #ff9ff3; font-size: 1.1rem; margin: 10px 0; animation: recordPulse 1s ease-in-out infinite; }
@keyframes recordPulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.6; } }
.game-over-card button { display: block; width: 100%; margin: 10px 0; }
.screen-shake { animation: shake 0.3s ease-out; }
@keyframes shake { 0%, 100% { transform: translateX(0); } 25% { transform: translateX(-5px); } 75% { transform: translateX(5px); } }
@media (max-width: 380px) { .ctrl-btn { width: 55px; height: 55px; font-size: 1.3rem; } canvas { width: 280px; height: 280px; } }
"""

private let snakeGameJS = """
const canvas = document.getElementById('game');
const ctx = canvas.getContext('2d');
const scoreEl = document.getElementById('score');
const comboEl = document.getElementById('combo');
const lengthEl = document.getElementById('length');
const comboDisplay = document.getElementById('comboDisplay');
const loadingScreen = document.getElementById('loadingScreen');
const startScreen = document.getElementById('startScreen');
const gameScreen = document.getElementById('gameScreen');
const pauseOverlay = document.getElementById('pauseOverlay');
const highScoreDisplay = document.getElementById('highScoreDisplay');

const gridSize = 15;
const tileCount = canvas.width / gridSize;
let snake = [{x: 10, y: 10}];
let food = {x: 15, y: 15};
let dx = 0, dy = 0;
let score = 0, combo = 0, maxCombo = 0;
let gameLoop, gameStarted = false, isPaused = false;
let particles = [], foodPulse = 0;
let comboTimer = null, soundEnabled = true;
let audioCtx = null, baseSpeed = 100;

const AudioSystem = {
    init() { if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)(); },
    playEat() {
        if (!soundEnabled || !audioCtx) return;
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.connect(gain); gain.connect(audioCtx.destination);
        osc.frequency.setValueAtTime(600, audioCtx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(1000 + combo * 50, audioCtx.currentTime + 0.1);
        gain.gain.setValueAtTime(0.3, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.1);
        osc.start(audioCtx.currentTime); osc.stop(audioCtx.currentTime + 0.1);
    },
    playGameOver() {
        if (!soundEnabled || !audioCtx) return;
        [0, 0.15, 0.3].forEach((delay, i) => {
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.connect(gain); gain.connect(audioCtx.destination);
            osc.frequency.setValueAtTime(400 - i * 100, audioCtx.currentTime + delay);
            gain.gain.setValueAtTime(0.3, audioCtx.currentTime + delay);
            gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + delay + 0.2);
            osc.start(audioCtx.currentTime + delay); osc.stop(audioCtx.currentTime + delay + 0.2);
        });
    },
    playNewRecord() {
        if (!soundEnabled || !audioCtx) return;
        [0, 0.1, 0.2, 0.3].forEach((delay, i) => {
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.connect(gain); gain.connect(audioCtx.destination);
            osc.type = 'sine';
            osc.frequency.setValueAtTime(500 + i * 200, audioCtx.currentTime + delay);
            gain.gain.setValueAtTime(0.3, audioCtx.currentTime + delay);
            gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + delay + 0.2);
            osc.start(audioCtx.currentTime + delay); osc.stop(audioCtx.currentTime + delay + 0.2);
        });
    }
};

function hapticFeedback(type) {
    if (window.antigravity && window.antigravity.haptic) {
        window.antigravity.haptic(type);
    } else if (navigator.vibrate) {
        const patterns = { light: 10, medium: 20, heavy: 30, success: [30, 50, 30] };
        navigator.vibrate(patterns[type] || 10);
    }
}

function getHighScore() { return parseInt(localStorage.getItem('snakeHighScore') || '0'); }
function setHighScore(s) { localStorage.setItem('snakeHighScore', s.toString()); }

function showScreen(screen) {
    [loadingScreen, startScreen, gameScreen].forEach(s => s.style.display = 'none');
    screen.style.display = 'block';
}

function updateComboDisplay() {
    if (combo >= 3) {
        comboDisplay.textContent = `🔥 ${combo} 连击!`;
        comboDisplay.className = 'combo-display active';
        comboDisplay.style.animation = 'none';
        void comboDisplay.offsetWidth;
        comboDisplay.style.animation = 'comboPulse 0.5s ease-out';
    } else { comboDisplay.className = 'combo-display'; }
}

function resetCombo() {
    combo = 0; comboEl.textContent = '0';
    comboDisplay.className = 'combo-display';
    if (comboTimer) clearTimeout(comboTimer);
}

function addCombo() {
    combo++; if (combo > maxCombo) maxCombo = combo;
    comboEl.textContent = combo;
    comboEl.classList.remove('pop'); void comboEl.offsetWidth; comboEl.classList.add('pop');
    updateComboDisplay();
    if (comboTimer) clearTimeout(comboTimer);
    comboTimer = setTimeout(resetCombo, 3000);
    if (combo >= 3) { AudioSystem.playEat(); hapticFeedback('medium'); }
}

class Particle {
    constructor(x, y, color) {
        this.x = x; this.y = y;
        this.size = Math.random() * 4 + 2;
        this.speedX = Math.random() * 4 - 2;
        this.speedY = Math.random() * 4 - 2;
        this.color = color; this.life = 1;
        this.decay = Math.random() * 0.03 + 0.02;
    }
    update() { this.x += this.speedX; this.y += this.speedY; this.life -= this.decay; this.size *= 0.98; }
    draw() {
        ctx.save(); ctx.globalAlpha = this.life; ctx.fillStyle = this.color;
        ctx.beginPath(); ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2); ctx.fill(); ctx.restore();
    }
}

function createExplosion(x, y, color, count = 12) {
    for (let i = 0; i < count; i++) particles.push(new Particle(x, y, color));
}

function drawStartScreen() {
    ctx.fillStyle = '#0a0a0a'; ctx.fillRect(0, 0, canvas.width, canvas.height);
    drawGrid();
    ctx.fillStyle = '#4ecdc4'; ctx.font = 'bold 28px -apple-system, sans-serif'; ctx.textAlign = 'center';
    ctx.shadowColor = 'rgba(78,205,196,0.5)'; ctx.shadowBlur = 20;
    ctx.fillText('🐍 贪吃蛇', canvas.width/2, canvas.height/2 - 40);
    ctx.shadowBlur = 0; ctx.font = '16px -apple-system, sans-serif'; ctx.fillStyle = '#7eddd8';
    ctx.fillText('点击方向键或滑动开始', canvas.width/2, canvas.height/2 + 10);
}

function drawGrid() {
    ctx.strokeStyle = 'rgba(78,205,196,0.05)'; ctx.lineWidth = 0.5;
    for (let i = 0; i <= tileCount; i++) {
        ctx.beginPath(); ctx.moveTo(i * gridSize, 0); ctx.lineTo(i * gridSize, canvas.height); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(0, i * gridSize); ctx.lineTo(canvas.width, i * gridSize); ctx.stroke();
    }
}

function startGame() {
    AudioSystem.init();
    snake = [{x: 10, y: 10}]; food = {x: 15, y: 15}; dx = 1; dy = 0;
    score = 0; combo = 0; maxCombo = 0; gameStarted = true; isPaused = false;
    scoreEl.textContent = '0'; comboEl.textContent = '0'; lengthEl.textContent = '1';
    comboDisplay.className = 'combo-display'; particles = [];
    showScreen(gameScreen);
    const speed = Math.max(50, baseSpeed - Math.floor(getHighScore() / 100) * 5);
    gameLoop = setInterval(drawGame, speed);
}

function drawGame() {
    if (isPaused) return;
    clearCanvas(); moveSnake();
    if (checkCollision()) { gameOver(); return; }
    drawSnake(); drawFood(); updateAndDrawParticles();
}

function clearCanvas() { ctx.fillStyle = '#0a0a0a'; ctx.fillRect(0, 0, canvas.width, canvas.height); drawGrid(); }

function moveSnake() {
    const head = {x: snake[0].x + dx, y: snake[0].y + dy};
    snake.unshift(head);
    if (head.x === food.x && head.y === food.y) {
        const comboMultiplier = combo >= 5 ? 3 : combo >= 3 ? 2 : 1;
        score += 10 * comboMultiplier;
        scoreEl.textContent = score;
        scoreEl.classList.remove('pop'); void scoreEl.offsetWidth; scoreEl.classList.add('pop');
        lengthEl.textContent = snake.length;
        lengthEl.classList.remove('pop'); void lengthEl.offsetWidth; lengthEl.classList.add('pop');
        addCombo();
        createExplosion(food.x * gridSize + gridSize/2, food.y * gridSize + gridSize/2, '#ff6b6b', 15);
        spawnFood(); hapticFeedback('medium');
        if (combo >= 5) {
            document.querySelector('.game-wrapper').classList.add('screen-shake');
            setTimeout(() => document.querySelector('.game-wrapper').classList.remove('screen-shake'), 300);
        }
    } else { snake.pop(); }
}

function drawSnake() {
    snake.forEach((segment, index) => {
        const x = segment.x * gridSize, y = segment.y * gridSize;
        if (index === 0) {
            const gradient = ctx.createRadialGradient(x + gridSize/2, y + gridSize/2, 0, x + gridSize/2, y + gridSize/2, gridSize);
            gradient.addColorStop(0, '#7eddd8'); gradient.addColorStop(1, '#4ecdc4');
            ctx.fillStyle = gradient; ctx.shadowColor = 'rgba(78,205,196,0.5)'; ctx.shadowBlur = 10;
        } else {
            const alpha = 1 - (index / snake.length) * 0.5;
            ctx.fillStyle = `rgba(78,205,196,${alpha})`; ctx.shadowBlur = 0;
        }
        ctx.beginPath(); ctx.roundRect(x + 1, y + 1, gridSize - 2, gridSize - 2, 3); ctx.fill();
    });
    ctx.shadowBlur = 0;
}

function drawFood() {
    foodPulse += 0.1; const pulse = Math.sin(foodPulse) * 2;
    const x = food.x * gridSize + gridSize/2, y = food.y * gridSize + gridSize/2;
    const gradient = ctx.createRadialGradient(x, y, 0, x, y, gridSize/2 + pulse);
    gradient.addColorStop(0, '#ff8888'); gradient.addColorStop(0.7, '#ff6b6b'); gradient.addColorStop(1, 'rgba(255,107,107,0)');
    ctx.fillStyle = gradient; ctx.shadowColor = 'rgba(255,107,107,0.6)'; ctx.shadowBlur = 15 + pulse * 2;
    ctx.beginPath(); ctx.arc(x, y, gridSize/2 - 1 + pulse/2, 0, Math.PI * 2); ctx.fill(); ctx.shadowBlur = 0;
}

function updateAndDrawParticles() {
    for (let i = particles.length - 1; i >= 0; i--) {
        particles[i].update(); particles[i].draw();
        if (particles[i].life <= 0) particles.splice(i, 1);
    }
}

function spawnFood() {
    food = {x: Math.floor(Math.random() * tileCount), y: Math.floor(Math.random() * tileCount)};
    if (snake.some(s => s.x === food.x && s.y === food.y)) spawnFood();
}

function checkCollision() {
    const head = snake[0];
    if (head.x < 0 || head.x >= tileCount || head.y < 0 || head.y >= tileCount) return true;
    for (let i = 1; i < snake.length; i++) if (head.x === snake[i].x && head.y === snake[i].y) return true;
    return false;
}

function gameOver() {
    clearInterval(gameLoop); gameStarted = false;
    if (comboTimer) clearTimeout(comboTimer);
    createExplosion(snake[0].x * gridSize + gridSize/2, snake[0].y * gridSize + gridSize/2, '#ff6b6b', 20);
    drawSnake(); updateAndDrawParticles();
    AudioSystem.playGameOver(); hapticFeedback('heavy');
    setTimeout(() => showGameOverScreen(), 500);
}

function showGameOverScreen() {
    const highScore = getHighScore();
    const isNewRecord = score > highScore;
    if (isNewRecord) { setHighScore(score); AudioSystem.playNewRecord(); }
    snake = [{x: 10, y: 10}]; dx = 0; dy = 0;
    scoreEl.textContent = '0'; lengthEl.textContent = '1';
    drawStartScreen();
    const overlay = document.createElement('div');
    overlay.className = 'game-over-overlay';
    overlay.innerHTML = `
        <div class="game-over-card">
            <div class="result-icon">${isNewRecord ? '🏆' : '🐍'}</div>
            <h2>游戏结束</h2>
            <div class="final-score">${score}</div>
            ${isNewRecord ? '<div class="new-record">🎉 新纪录！</div>' : `<div style="color: rgba(255,255,255,0.6); margin-bottom: 10px;">最高分: ${highScore}</div>`}
            <div class="stats">
                <div class="stat-item"><div class="stat-value">${snake.length}</div><div class="stat-label">蛇长度</div></div>
                <div class="stat-item"><div class="stat-value">${maxCombo}</div><div class="stat-label">最大连击</div></div>
            </div>
            <button onclick="this.closest('.game-over-overlay').remove(); showScreen(startScreen); updateHighScoreDisplay();" class="primary-btn">再来一次</button>
        </div>
    `;
    document.body.appendChild(overlay);
    overlay.addEventListener('click', (e) => { if (e.target === overlay) { overlay.remove(); showScreen(startScreen); updateHighScoreDisplay(); } });
}

function pauseGame() {
    if (!gameStarted) return;
    isPaused = true; pauseOverlay.style.display = 'flex'; hapticFeedback('light');
}

function resumeGame() {
    isPaused = false; pauseOverlay.style.display = 'none'; hapticFeedback('light');
}

function restartGame() { pauseOverlay.style.display = 'none'; startGame(); }

function toggleSound() {
    soundEnabled = !soundEnabled;
    document.getElementById('soundBtn').textContent = soundEnabled ? '🔊' : '🔇';
    hapticFeedback('light');
}

function updateHighScoreDisplay() { highScoreDisplay.textContent = getHighScore(); }

function changeDirection(newDx, newDy) {
    if (dx === -newDx && dy === -newDy) return;
    dx = newDx; dy = newDy;
    if (!gameStarted) startGame();
    hapticFeedback('light');
}

document.addEventListener('keydown', (e) => {
    switch(e.key) {
        case 'ArrowUp': if (dy === 0) changeDirection(0, -1); break;
        case 'ArrowDown': if (dy === 0) changeDirection(0, 1); break;
        case 'ArrowLeft': if (dx === 0) changeDirection(-1, 0); break;
        case 'ArrowRight': if (dx === 0) changeDirection(1, 0); break;
    }
});

document.getElementById('up').addEventListener('click', () => { if (dy === 0) changeDirection(0, -1); });
document.getElementById('down').addEventListener('click', () => { if (dy === 0) changeDirection(0, 1); });
document.getElementById('left').addEventListener('click', () => { if (dx === 0) changeDirection(-1, 0); });
document.getElementById('right').addEventListener('click', () => { if (dx === 0) changeDirection(1, 0); });

let touchStartX = 0, touchStartY = 0;
canvas.addEventListener('touchstart', (e) => {
    touchStartX = e.touches[0].clientX; touchStartY = e.touches[0].clientY;
}, { passive: true });
canvas.addEventListener('touchend', (e) => {
    const dx2 = e.changedTouches[0].clientX - touchStartX;
    const dy2 = e.changedTouches[0].clientY - touchStartY;
    if (Math.abs(dx2) > Math.abs(dy2)) {
        if (dx2 > 20 && dx === 0) changeDirection(1, 0);
        else if (dx2 < -20 && dx === 0) changeDirection(-1, 0);
    } else {
        if (dy2 > 20 && dy === 0) changeDirection(0, 1);
        else if (dy2 < -20 && dy === 0) changeDirection(0, -1);
    }
}, { passive: true });

document.getElementById('startGameBtn').addEventListener('click', startGame);
document.getElementById('pauseBtn').addEventListener('click', pauseGame);
document.getElementById('resumeBtn').addEventListener('click', resumeGame);
document.getElementById('restartBtn').addEventListener('click', restartGame);
document.getElementById('soundBtn').addEventListener('click', toggleSound);

window.addEventListener('load', () => {
    updateHighScoreDisplay();
    setTimeout(() => loadingScreen.classList.add('hidden'), 500);
    setTimeout(() => loadingScreen.remove(), 1000);
    drawStartScreen();
});
"""

private let breakoutHTML = """
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>打砖块</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="game-wrapper">
        <div class="loading-screen" id="loadingScreen">
            <div class="loading-spinner"></div>
            <p>加载中...</p>
        </div>
        <div class="start-screen" id="startScreen">
            <div class="game-icon">🧱</div>
            <h1>打砖块</h1>
            <p class="subtitle">移动挡板击碎所有砖块</p>
            <div class="high-score-display">最高分: <span id="highScoreDisplay">0</span></div>
            <button id="startGameBtn" class="primary-btn">开始游戏</button>
            <div class="tips">
                <p>🎮 滑动屏幕或鼠标移动挡板</p>
                <p>⚡ 连续击碎砖块获得连击加成</p>
            </div>
        </div>
        <div class="game-screen" id="gameScreen" style="display:none;">
            <div class="top-bar">
                <button id="pauseBtn" class="icon-btn">⏸️</button>
                <div class="score-board">
                    <div class="score-item">
                        <span class="label">得分</span>
                        <span id="score">0</span>
                    </div>
                    <div class="score-item">
                        <span class="label">连击</span>
                        <span id="combo">0</span>
                    </div>
                    <div class="score-item">
                        <span class="label">生命</span>
                        <span id="lives">3</span>
                    </div>
                </div>
                <button id="soundBtn" class="icon-btn">🔊</button>
            </div>
            <div class="combo-display" id="comboDisplay"></div>
            <canvas id="game" width="320" height="400"></canvas>
        </div>
        <div class="pause-overlay" id="pauseOverlay" style="display:none;">
            <div class="pause-card">
                <h2>游戏暂停</h2>
                <button id="resumeBtn" class="primary-btn">继续游戏</button>
                <button id="restartBtn" class="secondary-btn">重新开始</button>
            </div>
        </div>
    </div>
    <script src="game.js"></script>
</body>
</html>
"""

private let breakoutCSS = """
* { margin: 0; padding: 0; box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
body { font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif; background: linear-gradient(135deg, #0a0a0a 0%, #1a1a2e 50%, #0f3460 100%); color: white; display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 20px; overflow: hidden; position: relative; user-select: none; -webkit-user-select: none; }
body::before { content: ''; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: radial-gradient(circle at 50% 50%, rgba(254,202,87,0.05) 0%, transparent 50%); pointer-events: none; }
.game-wrapper { text-align: center; position: relative; z-index: 1; width: 100%; max-width: 380px; }
.loading-screen { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: linear-gradient(135deg, #0a0a0a, #1a1a2e); display: flex; flex-direction: column; align-items: center; justify-content: center; z-index: 2000; transition: opacity 0.5s; }
.loading-screen.hidden { opacity: 0; pointer-events: none; }
.loading-spinner { width: 50px; height: 50px; border: 4px solid rgba(255,255,255,0.1); border-top-color: #feca57; border-radius: 50%; animation: spin 1s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.loading-screen p { color: white; margin-top: 20px; font-size: 1.1rem; }
.start-screen { animation: fadeInUp 0.6s ease-out; }
@keyframes fadeInUp { from { opacity: 0; transform: translateY(30px); } to { opacity: 1; transform: translateY(0); } }
.game-icon { font-size: 5rem; margin-bottom: 20px; animation: bounce 2s ease-in-out infinite; }
@keyframes bounce { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-15px); } }
h1 { margin-bottom: 10px; font-size: 2.5rem; background: linear-gradient(45deg, #feca57, #ff9ff3, #feca57); background-size: 200% 200%; -webkit-background-clip: text; background-clip: text; -webkit-text-fill-color: transparent; animation: gradientShift 3s ease infinite; }
@keyframes gradientShift { 0%, 100% { background-position: 0% 50%; } 50% { background-position: 100% 50%; } }
.subtitle { color: rgba(255,255,255,0.7); font-size: 1rem; margin-bottom: 30px; }
.high-score-display { background: rgba(255,215,0,0.1); border: 1px solid rgba(255,215,0,0.3); padding: 12px 25px; border-radius: 16px; margin-bottom: 25px; color: #ffd700; font-size: 1.2rem; font-weight: bold; }
.primary-btn { background: linear-gradient(135deg, #feca57, #ff9ff3); color: #1a1a2e; border: none; padding: 16px 60px; border-radius: 30px; font-size: 1.3rem; font-weight: bold; cursor: pointer; box-shadow: 0 8px 25px rgba(254,202,87,0.4); transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); position: relative; overflow: hidden; }
.primary-btn::before { content: ''; position: absolute; top: 0; left: -100%; width: 100%; height: 100%; background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent); transition: left 0.5s; }
.primary-btn:active::before { left: 100%; }
.primary-btn:active { transform: scale(0.95); }
.secondary-btn { background: rgba(255,255,255,0.1); color: white; border: 1px solid rgba(255,255,255,0.2); padding: 14px 50px; border-radius: 30px; font-size: 1.1rem; font-weight: bold; cursor: pointer; transition: all 0.3s; }
.secondary-btn:active { background: rgba(255,255,255,0.2); transform: scale(0.95); }
.tips { margin-top: 30px; color: rgba(255,255,255,0.5); font-size: 0.9rem; }
.tips p { margin: 8px 0; }
.top-bar { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; padding: 0 5px; }
.icon-btn { background: rgba(255,255,255,0.1); border: none; width: 40px; height: 40px; border-radius: 12px; font-size: 1.2rem; cursor: pointer; transition: all 0.2s; }
.icon-btn:active { background: rgba(255,255,255,0.2); transform: scale(0.9); }
.score-board { display: flex; gap: 18px; background: rgba(255,255,255,0.1); backdrop-filter: blur(10px); padding: 10px 18px; border-radius: 16px; border: 1px solid rgba(255,255,255,0.2); box-shadow: 0 8px 32px rgba(0,0,0,0.2); }
.score-item { text-align: center; }
.score-item .label { display: block; color: rgba(255,255,255,0.6); font-size: 0.7rem; margin-bottom: 3px; }
.score-item span { color: #feca57; font-size: 1.2rem; font-weight: bold; transition: all 0.3s; }
.score-item span.pop { animation: scorePop 0.3s ease-out; }
@keyframes scorePop { 0% { transform: scale(1); } 50% { transform: scale(1.5); color: #ff6b6b; } 100% { transform: scale(1); } }
.combo-display { height: 25px; margin-bottom: 8px; font-size: 1.3rem; font-weight: bold; color: #ff9ff3; text-shadow: 0 0 20px rgba(255,159,243,0.5); opacity: 0; transition: all 0.3s; }
.combo-display.active { opacity: 1; animation: comboPulse 0.5s ease-out; }
@keyframes comboPulse { 0% { transform: scale(0.5); } 50% { transform: scale(1.2); } 100% { transform: scale(1); } }
canvas { background: linear-gradient(135deg, #0a0a0a, #111111); border: 3px solid #feca57; border-radius: 16px; display: block; margin: 0 auto 12px; box-shadow: 0 0 30px rgba(254,202,87,0.3), 0 10px 40px rgba(0,0,0,0.5), inset 0 0 20px rgba(254,202,87,0.1); }
.pause-overlay { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.8); backdrop-filter: blur(10px); display: flex; align-items: center; justify-content: center; z-index: 1000; animation: fadeIn 0.3s ease-out; }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
.pause-card { background: linear-gradient(135deg, #1a1a2e, #16213e); padding: 40px; border-radius: 24px; text-align: center; border: 1px solid rgba(255,255,255,0.2); box-shadow: 0 20px 60px rgba(0,0,0,0.5); animation: slideUp 0.4s cubic-bezier(0.4, 0, 0.2, 1); }
@keyframes slideUp { from { transform: translateY(50px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
.pause-card h2 { color: white; margin-bottom: 30px; font-size: 2rem; }
.pause-card button { display: block; width: 100%; margin: 10px 0; }
.game-over-overlay { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.85); backdrop-filter: blur(10px); display: flex; align-items: center; justify-content: center; z-index: 1000; animation: fadeIn 0.3s ease-out; }
.game-over-card { background: linear-gradient(135deg, #1a1a2e, #16213e); padding: 40px; border-radius: 24px; text-align: center; border: 1px solid rgba(255,255,255,0.2); box-shadow: 0 20px 60px rgba(0,0,0,0.5); animation: slideUp 0.4s cubic-bezier(0.4, 0, 0.2, 1); max-width: 350px; width: 90%; }
.game-over-card .result-icon { font-size: 4rem; margin-bottom: 15px; }
.game-over-card h2 { color: white; font-size: 2rem; margin-bottom: 10px; }
.game-over-card .final-score { color: #feca57; font-size: 3.5rem; font-weight: bold; margin: 15px 0; }
.game-over-card .stats { display: flex; justify-content: center; gap: 25px; margin: 20px 0; }
.game-over-card .stat-item { text-align: center; }
.game-over-card .stat-value { color: #4ecdc4; font-size: 1.5rem; font-weight: bold; }
.game-over-card .stat-label { color: rgba(255,255,255,0.6); font-size: 0.85rem; margin-top: 5px; }
.game-over-card .new-record { color: #ff9ff3; font-size: 1.1rem; margin: 10px 0; animation: recordPulse 1s ease-in-out infinite; }
@keyframes recordPulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.6; } }
.game-over-card button { display: block; width: 100%; margin: 10px 0; }
.screen-shake { animation: shake 0.3s ease-out; }
@keyframes shake { 0%, 100% { transform: translateX(0); } 25% { transform: translateX(-5px); } 75% { transform: translateX(5px); } }
@media (max-width: 380px) { canvas { width: 300px; height: 375px; } }
"""

private let breakoutJS = """
const canvas = document.getElementById('game');
const ctx = canvas.getContext('2d');
const scoreEl = document.getElementById('score');
const comboEl = document.getElementById('combo');
const livesEl = document.getElementById('lives');
const comboDisplay = document.getElementById('comboDisplay');
const loadingScreen = document.getElementById('loadingScreen');
const startScreen = document.getElementById('startScreen');
const gameScreen = document.getElementById('gameScreen');
const pauseOverlay = document.getElementById('pauseOverlay');
const highScoreDisplay = document.getElementById('highScoreDisplay');

let score = 0, lives = 3, combo = 0, maxCombo = 0;
let isPlaying = false, isPaused = false, animationId;
let ball = {x: 160, y: 300, dx: 3, dy: -3, radius: 6};
let paddle = {x: 120, y: 380, width: 80, height: 10};
let bricks = [];
let particles = [];
let ballTrail = [];
let comboTimer = null, soundEnabled = true;
let audioCtx = null, baseSpeed = 3;
const brickRowCount = 5, brickColumnCount = 8, brickWidth = 35, brickHeight = 15, brickPadding = 4, brickOffsetTop = 30, brickOffsetLeft = 10;

const AudioSystem = {
    init() { if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)(); },
    playHit() {
        if (!soundEnabled || !audioCtx) return;
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.connect(gain); gain.connect(audioCtx.destination);
        osc.frequency.setValueAtTime(400 + combo * 50, audioCtx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(600 + combo * 100, audioCtx.currentTime + 0.1);
        gain.gain.setValueAtTime(0.3, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.1);
        osc.start(audioCtx.currentTime); osc.stop(audioCtx.currentTime + 0.1);
    },
    playPaddle() {
        if (!soundEnabled || !audioCtx) return;
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.connect(gain); gain.connect(audioCtx.destination);
        osc.frequency.setValueAtTime(300, audioCtx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(400, audioCtx.currentTime + 0.05);
        gain.gain.setValueAtTime(0.2, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.05);
        osc.start(audioCtx.currentTime); osc.stop(audioCtx.currentTime + 0.05);
    },
    playGameOver() {
        if (!soundEnabled || !audioCtx) return;
        [0, 0.15, 0.3].forEach((delay, i) => {
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.connect(gain); gain.connect(audioCtx.destination);
            osc.frequency.setValueAtTime(400 - i * 100, audioCtx.currentTime + delay);
            gain.gain.setValueAtTime(0.3, audioCtx.currentTime + delay);
            gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + delay + 0.2);
            osc.start(audioCtx.currentTime + delay); osc.stop(audioCtx.currentTime + delay + 0.2);
        });
    },
    playWin() {
        if (!soundEnabled || !audioCtx) return;
        [0, 0.1, 0.2, 0.3, 0.4].forEach((delay, i) => {
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.connect(gain); gain.connect(audioCtx.destination);
            osc.type = 'sine';
            osc.frequency.setValueAtTime(400 + i * 100, audioCtx.currentTime + delay);
            gain.gain.setValueAtTime(0.3, audioCtx.currentTime + delay);
            gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + delay + 0.2);
            osc.start(audioCtx.currentTime + delay); osc.stop(audioCtx.currentTime + delay + 0.2);
        });
    },
    playNewRecord() {
        if (!soundEnabled || !audioCtx) return;
        [0, 0.1, 0.2, 0.3].forEach((delay, i) => {
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.connect(gain); gain.connect(audioCtx.destination);
            osc.type = 'sine';
            osc.frequency.setValueAtTime(500 + i * 200, audioCtx.currentTime + delay);
            gain.gain.setValueAtTime(0.3, audioCtx.currentTime + delay);
            gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + delay + 0.2);
            osc.start(audioCtx.currentTime + delay); osc.stop(audioCtx.currentTime + delay + 0.2);
        });
    }
};

function hapticFeedback(type) {
    if (window.antigravity && window.antigravity.haptic) {
        window.antigravity.haptic(type);
    } else if (navigator.vibrate) {
        const patterns = { light: 10, medium: 20, heavy: 30, success: [30, 50, 30] };
        navigator.vibrate(patterns[type] || 10);
    }
}

function getHighScore() { return parseInt(localStorage.getItem('breakoutHighScore') || '0'); }
function setHighScore(s) { localStorage.setItem('breakoutHighScore', s.toString()); }

function showScreen(screen) {
    [loadingScreen, startScreen, gameScreen].forEach(s => s.style.display = 'none');
    screen.style.display = 'block';
}

function updateComboDisplay() {
    if (combo >= 3) {
        comboDisplay.textContent = `🔥 ${combo} 连击!`;
        comboDisplay.className = 'combo-display active';
        comboDisplay.style.animation = 'none';
        void comboDisplay.offsetWidth;
        comboDisplay.style.animation = 'comboPulse 0.5s ease-out';
    } else { comboDisplay.className = 'combo-display'; }
}

function resetCombo() {
    combo = 0; comboEl.textContent = '0';
    comboDisplay.className = 'combo-display';
    if (comboTimer) clearTimeout(comboTimer);
}

function addCombo() {
    combo++; if (combo > maxCombo) maxCombo = combo;
    comboEl.textContent = combo;
    comboEl.classList.remove('pop'); void comboEl.offsetWidth; comboEl.classList.add('pop');
    updateComboDisplay();
    if (comboTimer) clearTimeout(comboTimer);
    comboTimer = setTimeout(resetCombo, 2000);
    if (combo >= 3) { AudioSystem.playHit(); hapticFeedback('medium'); }
}

class Particle {
    constructor(x, y, color) {
        this.x = x; this.y = y;
        this.size = Math.random() * 4 + 2;
        this.speedX = Math.random() * 6 - 3;
        this.speedY = Math.random() * 6 - 3;
        this.color = color; this.life = 1;
        this.decay = Math.random() * 0.03 + 0.02;
    }
    update() { this.x += this.speedX; this.y += this.speedY; this.life -= this.decay; this.size *= 0.98; }
    draw() {
        ctx.save(); ctx.globalAlpha = this.life; ctx.fillStyle = this.color;
        ctx.beginPath(); ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2); ctx.fill(); ctx.restore();
    }
}

function createExplosion(x, y, color, count = 15) {
    for (let i = 0; i < count; i++) particles.push(new Particle(x, y, color));
}

function adjustColor(color, amount) {
    const num = parseInt(color.slice(1), 16);
    const r = Math.min(255, Math.max(0, (num >> 16) + amount));
    const g = Math.min(255, Math.max(0, ((num >> 8) & 0x00FF) + amount));
    const b = Math.min(255, Math.max(0, (num & 0x0000FF) + amount));
    return `#${(r << 16 | g << 8 | b).toString(16).padStart(6, '0')}`;
}

function initBricks() {
    bricks = [];
    const colors = ['#ff6b6b', '#feca57', '#48dbfb', '#ff9ff3', '#54a0ff'];
    for (let c = 0; c < brickColumnCount; c++) {
        for (let r = 0; r < brickRowCount; r++) {
            bricks.push({x: c * (brickWidth + brickPadding) + brickOffsetLeft, y: r * (brickHeight + brickPadding) + brickOffsetTop, status: 1, color: colors[r]});
        }
    }
}

function drawBall() {
    ballTrail.push({x: ball.x, y: ball.y, life: 1});
    if (ballTrail.length > 8) ballTrail.shift();
    ballTrail.forEach((trail, i) => {
        trail.life -= 0.12;
        if (trail.life > 0) {
            ctx.beginPath();
            ctx.arc(trail.x, trail.y, ball.radius * trail.life, 0, Math.PI * 2);
            ctx.fillStyle = `rgba(255,255,255,${trail.life * 0.3})`;
            ctx.fill();
        }
    });
    ballTrail = ballTrail.filter(t => t.life > 0);
    const gradient = ctx.createRadialGradient(ball.x, ball.y, 0, ball.x, ball.y, ball.radius * 2);
    gradient.addColorStop(0, '#ffffff'); gradient.addColorStop(0.5, '#feca57'); gradient.addColorStop(1, 'rgba(254,202,87,0)');
    ctx.fillStyle = gradient; ctx.shadowColor = 'rgba(254,202,87,0.8)'; ctx.shadowBlur = 15;
    ctx.beginPath(); ctx.arc(ball.x, ball.y, ball.radius, 0, Math.PI * 2); ctx.fill(); ctx.shadowBlur = 0;
}

function drawPaddle() {
    const gradient = ctx.createLinearGradient(paddle.x, paddle.y, paddle.x + paddle.width, paddle.y);
    gradient.addColorStop(0, '#feca57'); gradient.addColorStop(1, '#ff9ff3');
    ctx.fillStyle = gradient; ctx.shadowColor = 'rgba(254,202,87,0.5)'; ctx.shadowBlur = 10;
    ctx.beginPath(); ctx.roundRect(paddle.x, paddle.y, paddle.width, paddle.height, 5); ctx.fill(); ctx.shadowBlur = 0;
}

function drawBricks() {
    bricks.forEach(brick => {
        if (brick.status === 1) {
            const gradient = ctx.createLinearGradient(brick.x, brick.y, brick.x, brick.y + brickHeight);
            gradient.addColorStop(0, brick.color); gradient.addColorStop(1, adjustColor(brick.color, -30));
            ctx.fillStyle = gradient; ctx.shadowColor = brick.color; ctx.shadowBlur = 5;
            ctx.beginPath(); ctx.roundRect(brick.x, brick.y, brickWidth, brickHeight, 3); ctx.fill(); ctx.shadowBlur = 0;
        }
    });
}

function updateAndDrawParticles() {
    for (let i = particles.length - 1; i >= 0; i--) {
        particles[i].update(); particles[i].draw();
        if (particles[i].life <= 0) particles.splice(i, 1);
    }
}

function update() {
    ball.x += ball.dx; ball.y += ball.dy;
    if (ball.x + ball.dx > canvas.width - ball.radius || ball.x + ball.dx < ball.radius) ball.dx = -ball.dx;
    if (ball.y + ball.dy < ball.radius) ball.dy = -ball.dy;
    else if (ball.y + ball.dy > canvas.height - ball.radius) {
        if (ball.x > paddle.x && ball.x < paddle.x + paddle.width) {
            ball.dy = -ball.dy;
            const hitPos = (ball.x - paddle.x) / paddle.width;
            ball.dx = 8 * (hitPos - 0.5);
            createExplosion(ball.x, ball.y, '#feca57', 8);
            AudioSystem.playPaddle(); hapticFeedback('light');
        } else {
            lives--; livesEl.textContent = lives;
            livesEl.classList.remove('pop'); void livesEl.offsetWidth; livesEl.classList.add('pop');
            resetCombo();
            if (lives === 0) { gameOver(false); return; }
            else { ball.x = 160; ball.y = 300; ball.dx = baseSpeed; ball.dy = -baseSpeed; }
        }
    }
    bricks.forEach(brick => {
        if (brick.status === 1) {
            if (ball.x > brick.x && ball.x < brick.x + brickWidth && ball.y > brick.y && ball.y < brick.y + brickHeight) {
                ball.dy = -ball.dy; brick.status = 0;
                const comboMultiplier = combo >= 5 ? 3 : combo >= 3 ? 2 : 1;
                score += 10 * comboMultiplier;
                scoreEl.textContent = score;
                scoreEl.classList.remove('pop'); void scoreEl.offsetWidth; scoreEl.classList.add('pop');
                addCombo();
                createExplosion(brick.x + brickWidth/2, brick.y + brickHeight/2, brick.color, 12);
                if (combo >= 5) {
                    document.querySelector('.game-wrapper').classList.add('screen-shake');
                    setTimeout(() => document.querySelector('.game-wrapper').classList.remove('screen-shake'), 300);
                }
                if (bricks.every(b => b.status === 0)) gameOver(true);
            }
        }
    });
}

function draw() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    drawBricks(); drawBall(); drawPaddle(); updateAndDrawParticles();
}

function gameLoop() {
    if (!isPlaying || isPaused) return;
    update(); draw();
    animationId = requestAnimationFrame(gameLoop);
}

function gameOver(won) {
    isPlaying = false; isPaused = false;
    cancelAnimationFrame(animationId);
    if (comboTimer) clearTimeout(comboTimer);
    if (won) AudioSystem.playWin(); else AudioSystem.playGameOver();
    hapticFeedback('heavy');
    setTimeout(() => showGameOverScreen(won), 500);
}

function showGameOverScreen(won) {
    const highScore = getHighScore();
    const isNewRecord = score > highScore;
    if (isNewRecord) { setHighScore(score); AudioSystem.playNewRecord(); }
    const overlay = document.createElement('div');
    overlay.className = 'game-over-overlay';
    overlay.innerHTML = `
        <div class="game-over-card">
            <div class="result-icon">${won ? '🎉' : '🧱'}</div>
            <h2>${won ? '恭喜通关！' : '游戏结束'}</h2>
            <div class="final-score">${score}</div>
            ${isNewRecord ? '<div class="new-record">🎉 新纪录！</div>' : `<div style="color: rgba(255,255,255,0.6); margin-bottom: 10px;">最高分: ${highScore}</div>`}
            <div class="stats">
                <div class="stat-item"><div class="stat-value">${bricks.filter(b => b.status === 0).length}/${bricks.length}</div><div class="stat-label">击碎砖块</div></div>
                <div class="stat-item"><div class="stat-value">${maxCombo}</div><div class="stat-label">最大连击</div></div>
            </div>
            <button onclick="this.closest('.game-over-overlay').remove(); showScreen(startScreen); updateHighScoreDisplay();" class="primary-btn">再来一次</button>
        </div>
    `;
    document.body.appendChild(overlay);
    overlay.addEventListener('click', (e) => { if (e.target === overlay) { overlay.remove(); showScreen(startScreen); updateHighScoreDisplay(); } });
}

function startGame() {
    AudioSystem.init();
    score = 0; lives = 3; combo = 0; maxCombo = 0; isPlaying = true; isPaused = false;
    scoreEl.textContent = '0'; livesEl.textContent = '3'; comboEl.textContent = '0';
    comboDisplay.className = 'combo-display';
    ball = {x: 160, y: 300, dx: baseSpeed, dy: -baseSpeed, radius: 6};
    paddle.x = 120; particles = []; ballTrail = [];
    initBricks();
    showScreen(gameScreen);
    gameLoop();
}

function pauseGame() {
    if (!isPlaying) return;
    isPaused = true; pauseOverlay.style.display = 'flex'; hapticFeedback('light');
}

function resumeGame() {
    isPaused = false; pauseOverlay.style.display = 'none'; hapticFeedback('light');
    gameLoop();
}

function restartGame() { pauseOverlay.style.display = 'none'; startGame(); }

function toggleSound() {
    soundEnabled = !soundEnabled;
    document.getElementById('soundBtn').textContent = soundEnabled ? '🔊' : '🔇';
    hapticFeedback('light');
}

function updateHighScoreDisplay() { highScoreDisplay.textContent = getHighScore(); }

canvas.addEventListener('touchmove', e => {
    e.preventDefault();
    const rect = canvas.getBoundingClientRect();
    const touchX = e.touches[0].clientX - rect.left;
    paddle.x = touchX - paddle.width / 2;
    if (paddle.x < 0) paddle.x = 0;
    if (paddle.x + paddle.width > canvas.width) paddle.x = canvas.width - paddle.width;
}, { passive: false });

canvas.addEventListener('mousemove', e => {
    const rect = canvas.getBoundingClientRect();
    const mouseX = e.clientX - rect.left;
    paddle.x = mouseX - paddle.width / 2;
    if (paddle.x < 0) paddle.x = 0;
    if (paddle.x + paddle.width > canvas.width) paddle.x = canvas.width - paddle.width;
});

document.getElementById('startGameBtn').addEventListener('click', startGame);
document.getElementById('pauseBtn').addEventListener('click', pauseGame);
document.getElementById('resumeBtn').addEventListener('click', resumeGame);
document.getElementById('restartBtn').addEventListener('click', restartGame);
document.getElementById('soundBtn').addEventListener('click', toggleSound);

window.addEventListener('load', () => {
    updateHighScoreDisplay();
    setTimeout(() => loadingScreen.classList.add('hidden'), 500);
    setTimeout(() => loadingScreen.remove(), 1000);
    initBricks(); draw();
});
"""

private let memoryHTML = """
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>记忆卡片</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="game-wrapper">
        <div class="loading-screen" id="loadingScreen">
            <div class="loading-spinner"></div>
            <p>加载中...</p>
        </div>
        <div class="start-screen" id="startScreen">
            <div class="game-icon">🃏</div>
            <h1>记忆卡片</h1>
            <p class="subtitle">找出所有配对的卡片</p>
            <div class="high-score-display">最佳步数: <span id="bestMovesDisplay">-</span></div>
            <button id="startGameBtn" class="primary-btn">开始游戏</button>
            <div class="tips">
                <p>🎮 点击卡片翻开记忆</p>
                <p>⚡ 连续匹配获得连击加成</p>
            </div>
        </div>
        <div class="game-screen" id="gameScreen" style="display:none;">
            <div class="top-bar">
                <button id="pauseBtn" class="icon-btn">⏸️</button>
                <div class="score-board">
                    <div class="score-item">
                        <span class="label">步数</span>
                        <span id="moves">0</span>
                    </div>
                    <div class="score-item">
                        <span class="label">连击</span>
                        <span id="combo">0</span>
                    </div>
                    <div class="score-item">
                        <span class="label">时间</span>
                        <span id="timer">0</span>
                    </div>
                </div>
                <button id="soundBtn" class="icon-btn">🔊</button>
            </div>
            <div class="combo-display" id="comboDisplay"></div>
            <div class="grid" id="grid"></div>
        </div>
        <div class="pause-overlay" id="pauseOverlay" style="display:none;">
            <div class="pause-card">
                <h2>游戏暂停</h2>
                <button id="resumeBtn" class="primary-btn">继续游戏</button>
                <button id="restartBtn" class="secondary-btn">重新开始</button>
            </div>
        </div>
    </div>
    <script src="game.js"></script>
</body>
</html>
"""

private let memoryCSS = """
* { margin: 0; padding: 0; box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
body { font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif; background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; overflow: hidden; position: relative; user-select: none; -webkit-user-select: none; }
body::before { content: ''; position: fixed; top: -50%; left: -50%; width: 200%; height: 200%; background: radial-gradient(circle, rgba(102,126,234,0.1) 0%, transparent 70%); animation: bgRotate 20s linear infinite; pointer-events: none; }
@keyframes bgRotate { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
.game-wrapper { text-align: center; position: relative; z-index: 1; width: 100%; max-width: 400px; }
.loading-screen { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: linear-gradient(135deg, #1a1a2e, #16213e); display: flex; flex-direction: column; align-items: center; justify-content: center; z-index: 2000; transition: opacity 0.5s; }
.loading-screen.hidden { opacity: 0; pointer-events: none; }
.loading-spinner { width: 50px; height: 50px; border: 4px solid rgba(255,255,255,0.1); border-top-color: #667eea; border-radius: 50%; animation: spin 1s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.loading-screen p { color: white; margin-top: 20px; font-size: 1.1rem; }
.start-screen { animation: fadeInUp 0.6s ease-out; }
@keyframes fadeInUp { from { opacity: 0; transform: translateY(30px); } to { opacity: 1; transform: translateY(0); } }
.game-icon { font-size: 5rem; margin-bottom: 20px; animation: bounce 2s ease-in-out infinite; }
@keyframes bounce { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-15px); } }
h1 { color: white; margin-bottom: 10px; font-size: 2.5rem; text-shadow: 0 0 20px rgba(102,126,234,0.5), 0 0 40px rgba(118,75,162,0.3); animation: titleGlow 2s ease-in-out infinite alternate; }
@keyframes titleGlow { 0% { text-shadow: 0 0 20px rgba(102,126,234,0.5), 0 0 40px rgba(118,75,162,0.3); } 100% { text-shadow: 0 0 30px rgba(102,126,234,0.8), 0 0 60px rgba(118,75,162,0.5), 0 0 80px rgba(118,75,162,0.3); } }
.subtitle { color: rgba(255,255,255,0.7); font-size: 1rem; margin-bottom: 30px; }
.high-score-display { background: rgba(255,215,0,0.1); border: 1px solid rgba(255,215,0,0.3); padding: 12px 25px; border-radius: 16px; margin-bottom: 25px; color: #ffd700; font-size: 1.2rem; font-weight: bold; }
.primary-btn { background: linear-gradient(135deg, #667eea, #764ba2); color: white; border: none; padding: 16px 60px; border-radius: 30px; font-size: 1.3rem; font-weight: bold; cursor: pointer; box-shadow: 0 8px 25px rgba(102,126,234,0.4); transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); position: relative; overflow: hidden; }
.primary-btn::before { content: ''; position: absolute; top: 0; left: -100%; width: 100%; height: 100%; background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent); transition: left 0.5s; }
.primary-btn:active::before { left: 100%; }
.primary-btn:active { transform: scale(0.95); }
.secondary-btn { background: rgba(255,255,255,0.1); color: white; border: 1px solid rgba(255,255,255,0.2); padding: 14px 50px; border-radius: 30px; font-size: 1.1rem; font-weight: bold; cursor: pointer; transition: all 0.3s; }
.secondary-btn:active { background: rgba(255,255,255,0.2); transform: scale(0.95); }
.tips { margin-top: 30px; color: rgba(255,255,255,0.5); font-size: 0.9rem; }
.tips p { margin: 8px 0; }
.top-bar { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; padding: 0 5px; }
.icon-btn { background: rgba(255,255,255,0.1); border: none; width: 40px; height: 40px; border-radius: 12px; font-size: 1.2rem; cursor: pointer; transition: all 0.2s; }
.icon-btn:active { background: rgba(255,255,255,0.2); transform: scale(0.9); }
.score-board { display: flex; gap: 18px; background: rgba(255,255,255,0.1); backdrop-filter: blur(10px); padding: 10px 18px; border-radius: 16px; border: 1px solid rgba(255,255,255,0.2); box-shadow: 0 8px 32px rgba(0,0,0,0.2); }
.score-item { text-align: center; }
.score-item .label { display: block; color: rgba(255,255,255,0.6); font-size: 0.7rem; margin-bottom: 3px; }
.score-item span { color: #ffd700; font-size: 1.2rem; font-weight: bold; transition: all 0.3s; }
.score-item span.pop { animation: scorePop 0.3s ease-out; }
@keyframes scorePop { 0% { transform: scale(1); } 50% { transform: scale(1.5); color: #ff6b6b; } 100% { transform: scale(1); } }
.combo-display { height: 25px; margin-bottom: 8px; font-size: 1.3rem; font-weight: bold; color: #ff9ff3; text-shadow: 0 0 20px rgba(255,159,243,0.5); opacity: 0; transition: all 0.3s; }
.combo-display.active { opacity: 1; animation: comboPulse 0.5s ease-out; }
@keyframes comboPulse { 0% { transform: scale(0.5); } 50% { transform: scale(1.2); } 100% { transform: scale(1); } }
.grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; max-width: 360px; margin: 0 auto 15px; padding: 15px; background: rgba(255,255,255,0.05); backdrop-filter: blur(10px); border-radius: 20px; border: 1px solid rgba(255,255,255,0.1); box-shadow: 0 8px 32px rgba(0,0,0,0.3), inset 0 0 20px rgba(255,255,255,0.05); }
.card { width: 75px; height: 75px; perspective: 1000px; cursor: pointer; position: relative; }
.card-inner { width: 100%; height: 100%; position: relative; transform-style: preserve-3d; transition: transform 0.6s cubic-bezier(0.4, 0, 0.2, 1); border-radius: 16px; box-shadow: 0 4px 15px rgba(0,0,0,0.2); }
.card.flipped .card-inner { transform: rotateY(180deg); }
.card-front, .card-back { position: absolute; width: 100%; height: 100%; backface-visibility: hidden; display: flex; align-items: center; justify-content: center; border-radius: 16px; font-size: 2.5rem; }
.card-front { background: linear-gradient(145deg, rgba(255,255,255,0.1), rgba(255,255,255,0.05)); border: 1px solid rgba(255,255,255,0.2); color: rgba(255,255,255,0.5); font-size: 2rem; }
.card-front::after { content: '?'; font-weight: bold; }
.card-back { background: linear-gradient(145deg, #ffffff, #f0f0f0); transform: rotateY(180deg); }
.card.matched .card-inner { animation: matchPulse 0.6s ease-out; }
.card.matched .card-back { background: linear-gradient(145deg, #d4edda, #c3e6cb); box-shadow: 0 0 20px rgba(40,167,69,0.4); }
@keyframes matchPulse { 0% { transform: rotateY(180deg) scale(1); } 50% { transform: rotateY(180deg) scale(1.1); } 100% { transform: rotateY(180deg) scale(1); } }
.card:active .card-inner { transform: scale(0.95); }
.pause-overlay { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.8); backdrop-filter: blur(10px); display: flex; align-items: center; justify-content: center; z-index: 1000; animation: fadeIn 0.3s ease-out; }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
.pause-card { background: linear-gradient(135deg, #1a1a2e, #16213e); padding: 40px; border-radius: 24px; text-align: center; border: 1px solid rgba(255,255,255,0.2); box-shadow: 0 20px 60px rgba(0,0,0,0.5); animation: slideUp 0.4s cubic-bezier(0.4, 0, 0.2, 1); }
@keyframes slideUp { from { transform: translateY(50px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
.pause-card h2 { color: white; margin-bottom: 30px; font-size: 2rem; }
.pause-card button { display: block; width: 100%; margin: 10px 0; }
.game-over-overlay { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.85); backdrop-filter: blur(10px); display: flex; align-items: center; justify-content: center; z-index: 1000; animation: fadeIn 0.3s ease-out; }
.game-over-card { background: linear-gradient(135deg, #1a1a2e, #16213e); padding: 40px; border-radius: 24px; text-align: center; border: 1px solid rgba(255,255,255,0.2); box-shadow: 0 20px 60px rgba(0,0,0,0.5); animation: slideUp 0.4s cubic-bezier(0.4, 0, 0.2, 1); max-width: 350px; width: 90%; }
.game-over-card .result-icon { font-size: 4rem; margin-bottom: 15px; }
.game-over-card h2 { color: white; font-size: 2rem; margin-bottom: 10px; }
.game-over-card .final-score { color: #ffd700; font-size: 2.5rem; font-weight: bold; margin: 15px 0; }
.game-over-card .stats { display: flex; justify-content: center; gap: 25px; margin: 20px 0; }
.game-over-card .stat-item { text-align: center; }
.game-over-card .stat-value { color: #667eea; font-size: 1.5rem; font-weight: bold; }
.game-over-card .stat-label { color: rgba(255,255,255,0.6); font-size: 0.85rem; margin-top: 5px; }
.game-over-card .new-record { color: #ff9ff3; font-size: 1.1rem; margin: 10px 0; animation: recordPulse 1s ease-in-out infinite; }
@keyframes recordPulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.6; } }
.game-over-card button { display: block; width: 100%; margin: 10px 0; }
@media (max-width: 400px) { .card { width: 65px; height: 65px; } .grid { gap: 8px; padding: 10px; } }
"""

private let memoryJS = """
const icons = ['🍎', '🍌', '🍇', '🍉', '🍓', '🍒', '🍑', '🍍'];
let cards = [];
let flippedCards = [];
let matchedPairs = 0;
let moves = 0, combo = 0, maxCombo = 0;
let timer = 0;
let timerInterval;
let isLocked = false, isPaused = false, gameStarted = false;
let comboTimer = null, soundEnabled = true;
let audioCtx = null;

const grid = document.getElementById('grid');
const movesEl = document.getElementById('moves');
const comboEl = document.getElementById('combo');
const timerEl = document.getElementById('timer');
const comboDisplay = document.getElementById('comboDisplay');
const loadingScreen = document.getElementById('loadingScreen');
const startScreen = document.getElementById('startScreen');
const gameScreen = document.getElementById('gameScreen');
const pauseOverlay = document.getElementById('pauseOverlay');
const bestMovesDisplay = document.getElementById('bestMovesDisplay');

const AudioSystem = {
    init() { if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)(); },
    playFlip() {
        if (!soundEnabled || !audioCtx) return;
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.connect(gain); gain.connect(audioCtx.destination);
        osc.frequency.setValueAtTime(400, audioCtx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(600, audioCtx.currentTime + 0.05);
        gain.gain.setValueAtTime(0.2, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.05);
        osc.start(audioCtx.currentTime); osc.stop(audioCtx.currentTime + 0.05);
    },
    playMatch() {
        if (!soundEnabled || !audioCtx) return;
        const baseFreq = 500 + combo * 100;
        [0, 0.1].forEach((delay, i) => {
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.connect(gain); gain.connect(audioCtx.destination);
            osc.type = 'sine';
            osc.frequency.setValueAtTime(baseFreq + i * 200, audioCtx.currentTime + delay);
            gain.gain.setValueAtTime(0.3, audioCtx.currentTime + delay);
            gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + delay + 0.15);
            osc.start(audioCtx.currentTime + delay); osc.stop(audioCtx.currentTime + delay + 0.15);
        });
    },
    playCombo() {
        if (!soundEnabled || !audioCtx) return;
        [0, 0.08, 0.16].forEach((delay, i) => {
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.connect(gain); gain.connect(audioCtx.destination);
            osc.type = 'sine';
            osc.frequency.setValueAtTime(600 + i * 200, audioCtx.currentTime + delay);
            gain.gain.setValueAtTime(0.3, audioCtx.currentTime + delay);
            gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + delay + 0.1);
            osc.start(audioCtx.currentTime + delay); osc.stop(audioCtx.currentTime + delay + 0.1);
        });
    },
    playWin() {
        if (!soundEnabled || !audioCtx) return;
        [0, 0.1, 0.2, 0.3, 0.4].forEach((delay, i) => {
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.connect(gain); gain.connect(audioCtx.destination);
            osc.type = 'sine';
            osc.frequency.setValueAtTime(400 + i * 100, audioCtx.currentTime + delay);
            gain.gain.setValueAtTime(0.3, audioCtx.currentTime + delay);
            gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + delay + 0.2);
            osc.start(audioCtx.currentTime + delay); osc.stop(audioCtx.currentTime + delay + 0.2);
        });
    },
    playNewRecord() {
        if (!soundEnabled || !audioCtx) return;
        [0, 0.1, 0.2, 0.3].forEach((delay, i) => {
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.connect(gain); gain.connect(audioCtx.destination);
            osc.type = 'sine';
            osc.frequency.setValueAtTime(500 + i * 200, audioCtx.currentTime + delay);
            gain.gain.setValueAtTime(0.3, audioCtx.currentTime + delay);
            gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + delay + 0.2);
            osc.start(audioCtx.currentTime + delay); osc.stop(audioCtx.currentTime + delay + 0.2);
        });
    }
};

function hapticFeedback(type) {
    if (window.antigravity && window.antigravity.haptic) {
        window.antigravity.haptic(type);
    } else if (navigator.vibrate) {
        const patterns = { light: 10, medium: 20, heavy: 30, success: [30, 50, 30] };
        navigator.vibrate(patterns[type] || 10);
    }
}

function getBestMoves() { return parseInt(localStorage.getItem('memoryBestMoves') || '999'); }
function setBestMoves(m) { localStorage.setItem('memoryBestMoves', m.toString()); }

function showScreen(screen) {
    [loadingScreen, startScreen, gameScreen].forEach(s => s.style.display = 'none');
    screen.style.display = 'block';
}

function updateComboDisplay() {
    if (combo >= 3) {
        comboDisplay.textContent = `🔥 ${combo} 连击!`;
        comboDisplay.className = 'combo-display active';
        comboDisplay.style.animation = 'none';
        void comboDisplay.offsetWidth;
        comboDisplay.style.animation = 'comboPulse 0.5s ease-out';
    } else { comboDisplay.className = 'combo-display'; }
}

function resetCombo() {
    combo = 0; comboEl.textContent = '0';
    comboDisplay.className = 'combo-display';
    if (comboTimer) clearTimeout(comboTimer);
}

function addCombo() {
    combo++; if (combo > maxCombo) maxCombo = combo;
    comboEl.textContent = combo;
    comboEl.classList.remove('pop'); void comboEl.offsetWidth; comboEl.classList.add('pop');
    updateComboDisplay();
    if (comboTimer) clearTimeout(comboTimer);
    comboTimer = setTimeout(resetCombo, 3000);
    if (combo >= 3) { AudioSystem.playCombo(); hapticFeedback('medium'); }
}

function shuffle(array) {
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
    }
    return array;
}

function createBoard() {
    grid.innerHTML = '';
    cards = shuffle([...icons, ...icons]);
    cards.forEach((icon, index) => {
        const card = document.createElement('div');
        card.className = 'card';
        card.dataset.index = index;
        card.dataset.icon = icon;
        card.innerHTML = `<div class="card-inner"><div class="card-front"></div><div class="card-back">${icon}</div></div>`;
        card.addEventListener('click', () => flipCard(card));
        grid.appendChild(card);
    });
}

function flipCard(card) {
    if (isLocked || isPaused || card.classList.contains('flipped') || card.classList.contains('matched')) return;

    AudioSystem.playFlip();
    hapticFeedback('light');
    card.classList.add('flipped');
    flippedCards.push(card);

    if (flippedCards.length === 2) {
        moves++;
        movesEl.textContent = moves;
        movesEl.classList.remove('pop'); void movesEl.offsetWidth; movesEl.classList.add('pop');
        checkMatch();
    }
}

function checkMatch() {
    isLocked = true;
    const [card1, card2] = flippedCards;
    const match = card1.dataset.icon === card2.dataset.icon;

    if (match) {
        card1.classList.add('matched');
        card2.classList.add('matched');
        matchedPairs++;
        addCombo();
        AudioSystem.playMatch();
        hapticFeedback('success');
        createMatchParticles(card1);
        createMatchParticles(card2);
        flippedCards = [];
        isLocked = false;
        if (matchedPairs === icons.length) {
            clearInterval(timerInterval);
            setTimeout(() => showGameOver(), 500);
        }
    } else {
        resetCombo();
        setTimeout(() => {
            card1.classList.remove('flipped');
            card2.classList.remove('flipped');
            flippedCards = [];
            isLocked = false;
        }, 800);
    }
}

function createMatchParticles(card) {
    const rect = card.getBoundingClientRect();
    const x = rect.left + rect.width / 2;
    const y = rect.top + rect.height / 2;
    const colors = ['#ffd700', '#4ecdc4', '#ff6b6b', '#48dbfb', '#ff9ff3'];
    for (let i = 0; i < 12; i++) {
        const particle = document.createElement('div');
        particle.style.cssText = `position: fixed; width: 8px; height: 8px; background: ${colors[Math.floor(Math.random() * colors.length)]}; border-radius: 50%; pointer-events: none; left: ${x}px; top: ${y}px; z-index: 1000;`;
        const angle = (Math.PI * 2 * i) / 12;
        const distance = Math.random() * 60 + 40;
        const tx = Math.cos(angle) * distance;
        const ty = Math.sin(angle) * distance;
        particle.animate([
            { transform: 'translate(0, 0) scale(1)', opacity: 1 },
            { transform: `translate(${tx}px, ${ty}px) scale(0)`, opacity: 0 }
        ], { duration: 600, easing: 'ease-out' });
        document.body.appendChild(particle);
        setTimeout(() => particle.remove(), 600);
    }
}

function startTimer() {
    clearInterval(timerInterval);
    timer = 0;
    timerEl.textContent = timer;
    timerInterval = setInterval(() => { if (!isPaused) { timer++; timerEl.textContent = timer; } }, 1000);
}

function showGameOver() {
    const bestMoves = getBestMoves();
    const isNewRecord = moves < bestMoves;
    if (isNewRecord) { setBestMoves(moves); AudioSystem.playNewRecord(); }
    AudioSystem.playWin();
    hapticFeedback('success');
    const overlay = document.createElement('div');
    overlay.className = 'game-over-overlay';
    overlay.innerHTML = `
        <div class="game-over-card">
            <div class="result-icon">${isNewRecord ? '🏆' : '🎉'}</div>
            <h2>恭喜完成！</h2>
            <div class="final-score">${moves} 步</div>
            ${isNewRecord ? '<div class="new-record">🎉 新纪录！</div>' : `<div style="color: rgba(255,255,255,0.6); margin-bottom: 10px;">最佳步数: ${bestMoves === 999 ? '-' : bestMoves}</div>`}
            <div class="stats">
                <div class="stat-item"><div class="stat-value">${timer}s</div><div class="stat-label">用时</div></div>
                <div class="stat-item"><div class="stat-value">${maxCombo}</div><div class="stat-label">最大连击</div></div>
            </div>
            <button onclick="this.closest('.game-over-overlay').remove(); showScreen(startScreen); updateBestDisplay();" class="primary-btn">再来一次</button>
        </div>
    `;
    document.body.appendChild(overlay);
    overlay.addEventListener('click', (e) => { if (e.target === overlay) { overlay.remove(); showScreen(startScreen); updateBestDisplay(); } });
}

function startGame() {
    AudioSystem.init();
    flippedCards = []; matchedPairs = 0; moves = 0; combo = 0; maxCombo = 0;
    isLocked = false; isPaused = false; gameStarted = true;
    movesEl.textContent = '0'; comboEl.textContent = '0'; timerEl.textContent = '0';
    comboDisplay.className = 'combo-display';
    createBoard();
    showScreen(gameScreen);
    startTimer();
}

function pauseGame() {
    if (!gameStarted || isPaused) return;
    isPaused = true; pauseOverlay.style.display = 'flex'; hapticFeedback('light');
}

function resumeGame() {
    isPaused = false; pauseOverlay.style.display = 'none'; hapticFeedback('light');
}

function restartGame() { pauseOverlay.style.display = 'none'; startGame(); }

function toggleSound() {
    soundEnabled = !soundEnabled;
    document.getElementById('soundBtn').textContent = soundEnabled ? '🔊' : '🔇';
    hapticFeedback('light');
}

function updateBestDisplay() {
    const best = getBestMoves();
    bestMovesDisplay.textContent = best === 999 ? '-' : best;
}

document.getElementById('startGameBtn').addEventListener('click', startGame);
document.getElementById('pauseBtn').addEventListener('click', pauseGame);
document.getElementById('resumeBtn').addEventListener('click', resumeGame);
document.getElementById('restartBtn').addEventListener('click', restartGame);
document.getElementById('soundBtn').addEventListener('click', toggleSound);

window.addEventListener('load', () => {
    updateBestDisplay();
    setTimeout(() => loadingScreen.classList.add('hidden'), 500);
    setTimeout(() => loadingScreen.remove(), 1000);
});
"""

private let particlesHTML = """
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>粒子特效</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <canvas id="canvas"></canvas>
    <div class="info">
        <h1>粒子特效</h1>
        <p>移动鼠标或触摸屏幕产生粒子</p>
    </div>
    <script src="script.js"></script>
</body>
</html>
"""

private let particlesCSS = """
* { margin: 0; padding: 0; box-sizing: border-box; }
body { overflow: hidden; background: #0a0a0a; font-family: -apple-system, sans-serif; }
canvas { position: fixed; top: 0; left: 0; width: 100%; height: 100%; }
.info { position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); text-align: center; color: white; pointer-events: none; z-index: 10; }
.info h1 { font-size: 2.5rem; margin-bottom: 10px; background: linear-gradient(45deg, #ff6b6b, #4ecdc4); -webkit-background-clip: text; background-clip: text; -webkit-text-fill-color: transparent; }
.info p { font-size: 1rem; opacity: 0.7; }
"""

private let particlesJS = """
const canvas = document.getElementById('canvas');
const ctx = canvas.getContext('2d');
canvas.width = window.innerWidth;
canvas.height = window.innerHeight;

const particles = [];
const colors = ['#ff6b6b', '#feca57', '#48dbfb', '#ff9ff3', '#54a0ff', '#5f27cd'];

class Particle {
    constructor(x, y) {
        this.x = x;
        this.y = y;
        this.size = Math.random() * 5 + 2;
        this.speedX = Math.random() * 6 - 3;
        this.speedY = Math.random() * 6 - 3;
        this.color = colors[Math.floor(Math.random() * colors.length)];
        this.life = 1;
    }
    update() {
        this.x += this.speedX;
        this.y += this.speedY;
        this.life -= 0.02;
        this.size *= 0.98;
    }
    draw() {
        ctx.fillStyle = this.color;
        ctx.globalAlpha = this.life;
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
        ctx.fill();
        ctx.globalAlpha = 1;
    }
}

function animate() {
    ctx.fillStyle = 'rgba(10, 10, 10, 0.1)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    for (let i = particles.length - 1; i >= 0; i--) {
        particles[i].update();
        particles[i].draw();
        if (particles[i].life <= 0) particles.splice(i, 1);
    }
    requestAnimationFrame(animate);
}

function createParticles(x, y) {
    for (let i = 0; i < 5; i++) {
        particles.push(new Particle(x, y));
    }
}

canvas.addEventListener('mousemove', e => createParticles(e.clientX, e.clientY));
canvas.addEventListener('touchmove', e => {
    e.preventDefault();
    createParticles(e.touches[0].clientX, e.touches[0].clientY);
});

window.addEventListener('resize', () => {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
});

animate();
"""

private let clockHTML = """
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>数字时钟</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="clock-container">
        <div class="date" id="date"></div>
        <div class="clock">
            <div class="digit" id="h1">0</div>
            <div class="digit" id="h2">0</div>
            <div class="separator">:</div>
            <div class="digit" id="m1">0</div>
            <div class="digit" id="m2">0</div>
            <div class="separator">:</div>
            <div class="digit" id="s1">0</div>
            <div class="digit" id="s2">0</div>
        </div>
        <div class="greeting" id="greeting"></div>
    </div>
    <script src="script.js"></script>
</body>
</html>
"""

private let clockCSS = """
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, sans-serif; background: linear-gradient(135deg, #1a1a2e, #16213e); min-height: 100vh; display: flex; align-items: center; justify-content: center; }
.clock-container { text-align: center; }
.date { color: #4ecdc4; font-size: 1.2rem; margin-bottom: 20px; letter-spacing: 2px; }
.clock { display: flex; align-items: center; justify-content: center; gap: 5px; }
.digit { width: 60px; height: 90px; background: linear-gradient(145deg, #0f3460, #16213e); border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 3rem; font-weight: bold; color: #4ecdc4; box-shadow: 0 8px 20px rgba(0,0,0,0.3); transition: all 0.3s; }
.digit:hover { transform: translateY(-5px); box-shadow: 0 12px 30px rgba(78, 205, 196, 0.2); }
.separator { font-size: 3rem; color: #ff6b6b; font-weight: bold; animation: blink 1s infinite; }
@keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }
.greeting { color: #ffd700; font-size: 1.3rem; margin-top: 25px; font-weight: 500; }
@media (max-width: 400px) { .digit { width: 45px; height: 70px; font-size: 2.2rem; } .separator { font-size: 2.2rem; } }
"""

private let clockJS = """
function updateClock() {
    const now = new Date();
    const h = String(now.getHours()).padStart(2, '0');
    const m = String(now.getMinutes()).padStart(2, '0');
    const s = String(now.getSeconds()).padStart(2, '0');

    document.getElementById('h1').textContent = h[0];
    document.getElementById('h2').textContent = h[1];
    document.getElementById('m1').textContent = m[0];
    document.getElementById('m2').textContent = m[1];
    document.getElementById('s1').textContent = s[0];
    document.getElementById('s2').textContent = s[1];

    const year = now.getFullYear();
    const month = now.getMonth() + 1;
    const day = now.getDate();
    const weekDays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    document.getElementById('date').textContent = `${year}年${month}月${day}日 ${weekDays[now.getDay()]}`;

    const hour = now.getHours();
    let greeting = '';
    if (hour < 6) greeting = '夜深了，注意休息';
    else if (hour < 9) greeting = '早上好，开启美好一天';
    else if (hour < 12) greeting = '上午好，工作顺利';
    else if (hour < 14) greeting = '中午好，记得午休';
    else if (hour < 18) greeting = '下午好，继续保持';
    else if (hour < 22) greeting = '晚上好，放松身心';
    else greeting = '晚安，好梦';
    document.getElementById('greeting').textContent = greeting;
}

updateClock();
setInterval(updateClock, 1000);
"""

private let cube3dHTML = """
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>3D 立方体</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="scene">
        <div class="cube">
            <div class="face front">前</div>
            <div class="face back">后</div>
            <div class="face right">右</div>
            <div class="face left">左</div>
            <div class="face top">上</div>
            <div class="face bottom">下</div>
        </div>
    </div>
    <div class="info">
        <h1>CSS 3D 立方体</h1>
        <p>拖动屏幕旋转立方体</p>
    </div>
</body>
</html>
"""

private let cube3dCSS = """
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, sans-serif; background: #1a1a2e; min-height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; overflow: hidden; }
.scene { width: 200px; height: 200px; perspective: 600px; margin-bottom: 40px; }
.cube { width: 100%; height: 100%; position: relative; transform-style: preserve-3d; animation: rotate 10s infinite linear; }
.face { position: absolute; width: 200px; height: 200px; border: 2px solid rgba(255,255,255,0.3); display: flex; align-items: center; justify-content: center; font-size: 24px; font-weight: bold; color: white; background: rgba(255,255,255,0.1); backdrop-filter: blur(10px); }
.front  { transform: rotateY(0deg) translateZ(100px); }
.back   { transform: rotateY(180deg) translateZ(100px); }
.right  { transform: rotateY(90deg) translateZ(100px); }
.left   { transform: rotateY(-90deg) translateZ(100px); }
.top    { transform: rotateX(90deg) translateZ(100px); }
.bottom { transform: rotateX(-90deg) translateZ(100px); }
@keyframes rotate {
    0% { transform: rotateX(-15deg) rotateY(0deg); }
    100% { transform: rotateX(-15deg) rotateY(360deg); }
}
.info { text-align: center; color: white; }
.info h1 { font-size: 24px; margin-bottom: 8px; }
.info p { font-size: 14px; opacity: 0.8; }
"""

private let typewriterHTML = """
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>打字机效果</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <h1 id="typewriter"></h1>
        <div class="cursor" id="cursor">|</div>
        <p class="subtitle">JavaScript 打字机效果演示</p>
    </div>
    <script src="script.js"></script>
</body>
</html>
"""

private let typewriterCSS = """
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, sans-serif; background: linear-gradient(135deg, #0f0c29, #302b63, #24243e); min-height: 100vh; display: flex; align-items: center; justify-content: center; }
.container { text-align: center; padding: 40px; }
h1 { font-size: 2.5rem; color: #fff; min-height: 3.5rem; letter-spacing: 2px; }
.cursor { display: inline-block; font-size: 2.5rem; color: #4ecdc4; animation: blink 0.7s infinite; }
@keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: 0; } }
.subtitle { color: rgba(255,255,255,0.5); margin-top: 20px; font-size: 1rem; }
@media (max-width: 400px) { h1 { font-size: 1.5rem; } .cursor { font-size: 1.5rem; } }
"""

private let typewriterJS = """
const texts = [
    '你好，欢迎来到 HTML 编辑器！',
    '支持实时预览和代码编辑',
    '可以创建游戏、动画和特效',
    '快来试试吧！'
];
let textIndex = 0;
let charIndex = 0;
let isDeleting = false;
const speed = 100;
const pauseTime = 1500;

function type() {
    const current = texts[textIndex];
    const el = document.getElementById('typewriter');
    
    if (isDeleting) {
        el.textContent = current.substring(0, charIndex - 1);
        charIndex--;
    } else {
        el.textContent = current.substring(0, charIndex + 1);
        charIndex++;
    }
    
    let typeSpeed = speed;
    if (isDeleting) typeSpeed /= 2;
    
    if (!isDeleting && charIndex === current.length) {
        typeSpeed = pauseTime;
        isDeleting = true;
    } else if (isDeleting && charIndex === 0) {
        isDeleting = false;
        textIndex = (textIndex + 1) % texts.length;
        typeSpeed = 300;
    }
    
    setTimeout(type, typeSpeed);
}

type();
"""

private let todoHTML = """
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>待办事项</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="app">
        <h1>📝 待办事项</h1>
        <div class="input-group">
            <input type="text" id="todoInput" placeholder="添加新任务...">
            <button id="addBtn">添加</button>
        </div>
        <div class="filters">
            <button class="filter active" data-filter="all">全部</button>
            <button class="filter" data-filter="active">进行中</button>
            <button class="filter" data-filter="completed">已完成</button>
        </div>
        <ul id="todoList"></ul>
        <div class="footer" id="footer" style="display:none;">
            <span id="count"></span>
            <button id="clearBtn">清除已完成</button>
        </div>
    </div>
    <script src="script.js"></script>
</body>
</html>
"""

private let todoCSS = """
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, sans-serif; background: linear-gradient(135deg, #667eea, #764ba2); min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }
.app { background: white; border-radius: 16px; padding: 30px; width: 100%; max-width: 400px; box-shadow: 0 20px 60px rgba(0,0,0,0.2); }
h1 { text-align: center; margin-bottom: 20px; color: #333; }
.input-group { display: flex; gap: 10px; margin-bottom: 20px; }
input { flex: 1; padding: 12px 16px; border: 2px solid #e1e1e1; border-radius: 10px; font-size: 16px; outline: none; transition: border-color 0.3s; }
input:focus { border-color: #667eea; }
#addBtn { padding: 12px 24px; background: linear-gradient(135deg, #667eea, #764ba2); color: white; border: none; border-radius: 10px; font-size: 16px; cursor: pointer; font-weight: 600; }
.filters { display: flex; gap: 8px; margin-bottom: 16px; }
.filter { flex: 1; padding: 8px; border: none; background: #f5f5f5; border-radius: 8px; cursor: pointer; font-size: 14px; transition: all 0.2s; }
.filter.active { background: #667eea; color: white; }
ul { list-style: none; }
li { display: flex; align-items: center; padding: 12px; border-bottom: 1px solid #f0f0f0; transition: all 0.3s; }
li.completed span { text-decoration: line-through; color: #999; }
li span { flex: 1; font-size: 16px; }
li input[type="checkbox"] { width: 20px; height: 20px; margin-right: 12px; accent-color: #667eea; }
li button { background: none; border: none; color: #ff6b6b; font-size: 18px; cursor: pointer; padding: 4px 8px; }
.footer { display: flex; justify-content: space-between; align-items: center; margin-top: 16px; padding-top: 16px; border-top: 1px solid #f0f0f0; font-size: 14px; color: #666; }
#clearBtn { background: none; border: none; color: #ff6b6b; cursor: pointer; font-size: 14px; }
"""

private let todoJS = """
let todos = [];
let currentFilter = 'all';

const todoInput = document.getElementById('todoInput');
const addBtn = document.getElementById('addBtn');
const todoList = document.getElementById('todoList');
const footer = document.getElementById('footer');
const countEl = document.getElementById('count');
const clearBtn = document.getElementById('clearBtn');
const filterBtns = document.querySelectorAll('.filter');

function addTodo() {
    const text = todoInput.value.trim();
    if (!text) return;
    todos.push({ id: Date.now(), text, completed: false });
    todoInput.value = '';
    render();
}

function toggleTodo(id) {
    const todo = todos.find(t => t.id === id);
    if (todo) todo.completed = !todo.completed;
    render();
}

function deleteTodo(id) {
    todos = todos.filter(t => t.id !== id);
    render();
}

function clearCompleted() {
    todos = todos.filter(t => !t.completed);
    render();
}

function render() {
    const filtered = todos.filter(t => {
        if (currentFilter === 'active') return !t.completed;
        if (currentFilter === 'completed') return t.completed;
        return true;
    });
    
    todoList.innerHTML = filtered.map(t => `
        <li class="${t.completed ? 'completed' : ''}">
            <input type="checkbox" ${t.completed ? 'checked' : ''} onchange="toggleTodo(${t.id})">
            <span>${t.text}</span>
            <button onclick="deleteTodo(${t.id})">✕</button>
        </li>
    `).join('');
    
    const activeCount = todos.filter(t => !t.completed).length;
    footer.style.display = todos.length > 0 ? 'flex' : 'none';
    countEl.textContent = `${activeCount} 项待完成`;
}

addBtn.addEventListener('click', addTodo);
todoInput.addEventListener('keypress', e => { if (e.key === 'Enter') addTodo(); });
clearBtn.addEventListener('click', clearCompleted);
filterBtns.forEach(btn => {
    btn.addEventListener('click', () => {
        filterBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentFilter = btn.dataset.filter;
        render();
    });
});

render();
"""

private let weatherHTML = """
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>天气预报</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="weather-card">
        <div class="location">📍 北京市</div>
        <div class="date" id="date"></div>
        <div class="temp-main">
            <span class="icon">☀️</span>
            <span class="temp">26°</span>
        </div>
        <div class="desc">晴朗</div>
        <div class="details">
            <div class="detail"><span>💧 湿度</span><span>45%</span></div>
            <div class="detail"><span>🌬️ 风速</span><span>12km/h</span></div>
            <div class="detail"><span>🌡️ 体感</span><span>28°</span></div>
            <div class="detail"><span>☀️ 紫外线</span><span>中等</span></div>
        </div>
        <div class="forecast">
            <div class="day"><span>明天</span><span>🌤️</span><span>28°/18°</span></div>
            <div class="day"><span>后天</span><span>⛅</span><span>25°/17°</span></div>
            <div class="day"><span>大后天</span><span>🌧️</span><span>22°/15°</span></div>
        </div>
    </div>
    <script src="script.js"></script>
</body>
</html>
"""

private let weatherCSS = """
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, sans-serif; background: linear-gradient(135deg, #4facfe, #00f2fe); min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }
.weather-card { background: rgba(255,255,255,0.2); backdrop-filter: blur(20px); border-radius: 24px; padding: 30px; width: 100%; max-width: 380px; color: white; box-shadow: 0 8px 32px rgba(0,0,0,0.1); }
.location { font-size: 1.2rem; font-weight: 600; margin-bottom: 4px; }
.date { font-size: 0.9rem; opacity: 0.8; margin-bottom: 20px; }
.temp-main { display: flex; align-items: center; justify-content: center; gap: 10px; margin: 20px 0; }
.icon { font-size: 3rem; }
.temp { font-size: 4.5rem; font-weight: 200; }
.desc { text-align: center; font-size: 1.2rem; margin-bottom: 24px; opacity: 0.9; }
.details { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 24px; }
.detail { display: flex; justify-content: space-between; background: rgba(255,255,255,0.15); padding: 10px 14px; border-radius: 12px; font-size: 0.9rem; }
.forecast { border-top: 1px solid rgba(255,255,255,0.2); padding-top: 16px; }
.day { display: flex; justify-content: space-between; align-items: center; padding: 8px 0; font-size: 0.95rem; }
"""

private let weatherJS = """
const dateEl = document.getElementById('date');
const now = new Date();
const weekDays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
"""
import SwiftUI

