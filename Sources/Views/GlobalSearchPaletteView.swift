import SwiftUI

public struct LocalizedSearchItem: Identifiable {
    public let id = UUID()
    public let titles: [AppLanguage: String]
    public let subtitles: [AppLanguage: String]
    public let section: NavigationSection
    public let icon: String
    public let gradientColors: [Color]
    public let keywords: [String]
    
    public init(
        titles: [AppLanguage: String],
        subtitles: [AppLanguage: String],
        section: NavigationSection,
        icon: String,
        gradientColors: [Color],
        keywords: [String]
    ) {
        self.titles = titles
        self.subtitles = subtitles
        self.section = section
        self.icon = icon
        self.gradientColors = gradientColors
        self.keywords = keywords
    }
    
    public func title(for lang: AppLanguage) -> String {
        titles[lang] ?? titles[.zhHans] ?? titles[.en] ?? ""
    }
    
    public func subtitle(for lang: AppLanguage) -> String {
        subtitles[lang] ?? subtitles[.zhHans] ?? subtitles[.en] ?? ""
    }
}

public struct GlobalSearchPaletteView: View {
    @Binding var isPresented: Bool
    var onSelectSection: (NavigationSection) -> Void
    @ObservedObject var languageManager = LanguageManager.shared
    
    @State private var searchText: String = ""
    @FocusState private var isFieldFocused: Bool
    
    private var curLang: AppLanguage {
        languageManager.currentLanguage
    }
    
    // Feature catalogue with full localization
    private let allFeatures: [LocalizedSearchItem] = [
        // 1. Dashboard
        LocalizedSearchItem(
            titles: [
                .zhHans: "设备电池健康与温度监控",
                .zhHant: "設備電池健康與溫度監控",
                .en: "Battery Health & Temperature",
                .fr: "Santé et température de la batterie",
                .ja: "バッテリーの健全性と温度",
                .es: "Salud y temperatura de la batería",
                .ko: "배터리 상태 및 온도 모니터링",
                .ru: "Состояние и температура батареи",
                .uk: "Стан та температура батареї"
            ],
            subtitles: [
                .zhHans: "实时查看电池电量、健康状况、温度与充电状态",
                .zhHant: "即時查看電池電量、健康狀況、溫度與充電狀態",
                .en: "Monitor battery percentage, health, temperature and charging state",
                .fr: "Suivi du pourcentage, de la santé, de la température et de la charge",
                .ja: "バッテリー残量、状態、温度、充電状態をリアルタイム表示",
                .es: "Monitoreo en tiempo real del porcentaje, salud y temperatura",
                .ko: "배터리 잔량, 상태, 온도 및 충전 상태 실시간 확인",
                .ru: "Мониторинг уровня заряда, состояния, температуры и зарядки",
                .uk: "Моніторинг рівня заряду, стану, температури та заряджання"
            ],
            section: .dashboard,
            icon: "battery.100.bolt",
            gradientColors: [Color.blue, Color.cyan],
            keywords: ["电池", "電池", "battery", "电量", "電量", "温度", "健康", "充电", "充電"]
        ),
        LocalizedSearchItem(
            titles: [
                .zhHans: "系统版本与详细规格",
                .zhHant: "系統版本與詳細規格",
                .en: "System Version & Specifications",
                .fr: "Version du système et spécifications",
                .ja: "システムバージョンと仕様",
                .es: "Versión del sistema y especificaciones",
                .ko: "시스템 버전 및 상세 사양",
                .ru: "Версия системы и характеристики",
                .uk: "Версія системи та характеристики"
            ],
            subtitles: [
                .zhHans: "查看 Android 版本、SDK API 级别、处理器与安全补丁",
                .zhHant: "查看 Android 版本、SDK API 級別、處理器與安全修補程式",
                .en: "View Android version, SDK level, CPU architecture and security patch",
                .fr: "Consultez la version Android, le niveau SDK et le correctif de sécurité",
                .ja: "Androidバージョン、SDKレベル、CPU、セキュリティパッチを表示",
                .es: "Ver versión de Android, nivel de SDK, CPU y parche de seguridad",
                .ko: "Android 버전, SDK 레벨, 프로세서 및 보안 패치 확인",
                .ru: "Просмотр версии Android, уровня SDK, процессора и патча безопасности",
                .uk: "Перегляд версії Android, рівня SDK, процесора та патча безпеки"
            ],
            section: .dashboard,
            icon: "iphone.gen3",
            gradientColors: [Color.blue, Color.cyan],
            keywords: ["系统", "系統", "版本", "android", "sdk", "型号", "型號", "spec"]
        ),
        LocalizedSearchItem(
            titles: [
                .zhHans: "屏幕分辨率与 DPI 调节",
                .zhHant: "螢幕解析度與 DPI 調節",
                .en: "Screen Resolution & DPI Adjustment",
                .fr: "Résolution d'écran et réglage DPI",
                .ja: "画面解像度と DPI 調整",
                .es: "Resolución de pantalla y ajuste DPI",
                .ko: "화면 해상도 및 DPI 조정",
                .ru: "Разрешение экрана и настройка DPI",
                .uk: "Роздільна здатність екрана та налаштування DPI"
            ],
            subtitles: [
                .zhHans: "一键修改设备屏幕密度与自定义显示分辨率",
                .zhHant: "一鍵修改裝置螢幕密度與自訂解析度",
                .en: "Modify device screen density and custom resolution dynamically",
                .fr: "Modifiez la densité de l'écran et la résolution personnalisée",
                .ja: "画面密度とカスタム解像度を動的に変更",
                .es: "Modifique dinámicamente la densidad y resolución de la pantalla",
                .ko: "화면 밀도 및 사용자 지정 해상도 변경",
                .ru: "Настройка плотности экрана и пользовательского разрешения",
                .uk: "Налаштування щільності екрана та роздільної здатності"
            ],
            section: .dashboard,
            icon: "display",
            gradientColors: [Color.blue, Color.cyan],
            keywords: ["屏幕", "螢幕", "dpi", "density", "分辨率", "解析度", "display"]
        ),
        LocalizedSearchItem(
            titles: [
                .zhHans: "无线 ADB 配对与网络连接",
                .zhHant: "無線 ADB 配對與連線",
                .en: "Wireless ADB Pairing & Connection",
                .fr: "Appairage et connexion ADB sans fil",
                .ja: "ワイヤレス ADB ペアリングと接続",
                .es: "Emparejamiento y conexión ADB inalámbrica",
                .ko: "무선 ADB 페어링 및 연결",
                .ru: "Беспроводное сопряжение и подключение ADB",
                .uk: "Бездротове сполучення та підключення ADB"
            ],
            subtitles: [
                .zhHans: "免 USB 数据线通过 Wi-Fi 进行无线调试与配对",
                .zhHant: "免 USB 數據線透過 Wi-Fi 進行無線調試與配對",
                .en: "Debug Android over Wi-Fi without USB cables via wireless pairing",
                .fr: "Déboguer sans fil via Wi-Fi sans câble USB",
                .ja: "USBケーブル不要でWi-Fi経由のワイヤレスデバッグとペアリング",
                .es: "Depuración inalámbrica a través de Wi-Fi sin cables USB",
                .ko: "USB 케이블 없이 Wi-Fi를 통한 무선 디버깅 및 페어링",
                .ru: "Беспроводная отладка по Wi-Fi без кабелей USB",
                .uk: "Бездротове налагодження через Wi-Fi без кабелю USB"
            ],
            section: .dashboard,
            icon: "wifi",
            gradientColors: [Color.blue, Color.cyan],
            keywords: ["无线", "無線", "wifi", "配对", "配對", "tcpip", "connect", "网络"]
        ),
        
        // 2. Fastboot
        LocalizedSearchItem(
            titles: [
                .zhHans: "Fastboot 镜像分区刷入 (Boot / Recovery)",
                .zhHant: "Fastboot 鏡像分區刷入 (Boot / Recovery)",
                .en: "Fastboot Partition Flashing (Boot / Recovery)",
                .fr: "Flash de partition Fastboot (Boot / Recovery)",
                .ja: "Fastboot パーティションフラッシュ (Boot / Recovery)",
                .es: "Flasheo de particiones Fastboot (Boot / Recovery)",
                .ko: "Fastboot 파티션 플래시 (Boot / Recovery)",
                .ru: "Прошивка разделов Fastboot (Boot / Recovery)",
                .uk: "Прошивка розділів Fastboot (Boot / Recovery)"
            ],
            subtitles: [
                .zhHans: "线刷 Boot、Recovery、System、Vendor 等分区镜像",
                .zhHant: "線刷 Boot、Recovery、System、Vendor 等分區鏡像",
                .en: "Flash Boot, Recovery, System and Vendor partition images",
                .fr: "Flashez les images de partition Boot, Recovery, System et Vendor",
                .ja: "Boot、Recovery、System、Vendor パーティションをフラッシュ",
                .es: "Flashear imágenes de partición Boot, Recovery, System y Vendor",
                .ko: "Boot, Recovery, System, Vendor 파티션 이미지 플래시",
                .ru: "Прошивка образов разделов Boot, Recovery, System и Vendor",
                .uk: "Прошивка образів розділів Boot, Recovery, System та Vendor"
            ],
            section: .fastboot,
            icon: "bolt.horizontal.fill",
            gradientColors: [Color.orange, Color.red],
            keywords: ["fastboot", "刷机", "刷機", "boot", "recovery", "flash", "img", "线刷"]
        ),
        LocalizedSearchItem(
            titles: [
                .zhHans: "Bootloader 解锁与上锁 (BL)",
                .zhHant: "Bootloader 解鎖與上鎖 (BL)",
                .en: "Bootloader Unlock & Lock (BL)",
                .fr: "Déverrouillage et verrouillage du Bootloader (BL)",
                .ja: "Bootloader アンロック / ロック (BL)",
                .es: "Desbloqueo y bloqueo del Bootloader (BL)",
                .ko: "부트로더 언락 및 잠금 (BL)",
                .ru: "Разблокировка и блокировка загрузчика (BL)",
                .uk: "Розблокування та блокування завантажувача (BL)"
            ],
            subtitles: [
                .zhHans: "执行 OEM Unlock 或 Flashing Unlock 解除引导锁",
                .zhHant: "執行 OEM Unlock 或 Flashing Unlock 解除引導鎖",
                .en: "Execute OEM Unlock or Flashing Unlock to release boot lock",
                .fr: "Exécutez le déverrouillage OEM pour débloquer le bootloader",
                .ja: "OEM Unlock または Flashing Unlock を実行してロック解除",
                .es: "Ejecutar desbloqueo OEM para desbloquear el cargador de arranque",
                .ko: "OEM Unlock 또는 Flashing Unlock으로 부트로더 언락",
                .ru: "Выполнение OEM Unlock для разблокировки загрузчика",
                .uk: "Виконання OEM Unlock для розблокування завантажувача"
            ],
            section: .fastboot,
            icon: "lock.open.fill",
            gradientColors: [Color.orange, Color.red],
            keywords: ["bl", "bootloader", "解锁", "解鎖", "unlock", "lock", "oem"]
        ),
        LocalizedSearchItem(
            titles: [
                .zhHans: "A/B 槽位切换 (Slot Active)",
                .zhHant: "A/B 槽位切換 (Slot Active)",
                .en: "A/B Slot Switching (Slot Active)",
                .fr: "Changement de slot A/B (Slot actif)",
                .ja: "A/B スロット切り替え (Slot Active)",
                .es: "Cambio de ranura A/B (Ranura activa)",
                .ko: "A/B 슬롯 전환 (Slot Active)",
                .ru: "Переключение слота A/B (Активный слот)",
                .uk: "Перемикання слота A/B (Активний слот)"
            ],
            subtitles: [
                .zhHans: "查询与切换当前启动的分区槽位 (Slot A / Slot B)",
                .zhHant: "查詢與切換目前啟動的分區槽位 (Slot A / Slot B)",
                .en: "Inspect and switch current active partition slot (Slot A / Slot B)",
                .fr: "Inspectez et basculez le slot actif (Slot A / Slot B)",
                .ja: "現在のアクティブパーティションスロットを確認・切り替え",
                .es: "Inspeccione y cambie la ranura de partición activa (A / B)",
                .ko: "현재 활성 파티션 슬롯 확인 및 전환 (Slot A / Slot B)",
                .ru: "Проверка и переключение активного слота (Slot A / Slot B)",
                .uk: "Перевірка та перемикання активного слота (Slot A / Slot B)"
            ],
            section: .fastboot,
            icon: "arrow.triangle.swap",
            gradientColors: [Color.orange, Color.red],
            keywords: ["slot", "槽位", "a/b", "分区", "分區", "切换", "切換", "active"]
        ),
        
        // 3. Recovery
        LocalizedSearchItem(
            titles: [
                .zhHans: "ADB Sideload 旁推刷机 (OTA / ROM / Zip)",
                .zhHant: "ADB Sideload 線刷卡刷包 (OTA / ROM / Zip)",
                .en: "ADB Sideload (OTA / ROM / Zip)",
                .fr: "ADB Sideload (OTA / ROM / Zip)",
                .ja: "ADB Sideload フラッシュ (OTA / ROM / Zip)",
                .es: "ADB Sideload (OTA / ROM / Zip)",
                .ko: "ADB Sideload 플래시 (OTA / ROM / Zip)",
                .ru: "ADB Sideload (OTA / ROM / Zip)",
                .uk: "ADB Sideload (OTA / ROM / Zip)"
            ],
            subtitles: [
                .zhHans: "在 Recovery 模式下旁推安装系统升级包、ROM 或 Magisk",
                .zhHant: "在 Recovery 模式下旁推安裝系統升級包、ROM 或 Magisk",
                .en: "Sideload install system OTA updates, custom ROMs or Magisk root in Recovery",
                .fr: "Installez des mises à jour OTA, des ROM ou Magisk via Sideload en Recovery",
                .ja: "RecoveryモードでOTAアップデート、カスタムROM、Magiskをサイドロード",
                .es: "Instale actualizaciones OTA, ROM o Magisk mediante Sideload en Recovery",
                .ko: "Recovery 모드에서 OTA 업데이트, 커스텀 롬, Magisk 사이드로드",
                .ru: "Установка OTA, кастомных прошивок или Magisk через Sideload в Recovery",
                .uk: "Встановлення OTA, кастомних прошивок або Magisk через Sideload у Recovery"
            ],
            section: .recovery,
            icon: "arrow.down.doc.fill",
            gradientColors: [Color.purple, Color.indigo],
            keywords: ["sideload", "旁推", "卡刷", "ota", "rom", "zip", "magisk", "recovery"]
        ),
        LocalizedSearchItem(
            titles: [
                .zhHans: "一键重启至 Recovery 模式",
                .zhHant: "一鍵重啟至 Recovery 模式",
                .en: "Reboot to Recovery Mode",
                .fr: "Redémarrer en mode Recovery",
                .ja: "Recovery モードに再起動",
                .es: "Reiniciar en modo Recovery",
                .ko: "Recovery 모드로 재부팅",
                .ru: "Перезагрузка в режим Recovery",
                .uk: "Перезавантаження в режим Recovery"
            ],
            subtitles: [
                .zhHans: "通过 ADB 或 Fastboot 发送重启指令进入 Recovery 界面",
                .zhHant: "透過 ADB 或 Fastboot 發送重啟指令進入 Recovery 界面",
                .en: "Send reboot command via ADB or Fastboot to enter Recovery interface",
                .fr: "Envoyez la commande de redémarrage pour entrer en Recovery",
                .ja: "ADBまたはFastboot経由でコマンドを送信しRecovery画面へ移行",
                .es: "Envíe el comando de reinicio para acceder a la interfaz de Recovery",
                .ko: "ADB 또는 Fastboot 명령어로 Recovery 인터페이스 진입",
                .ru: "Отправка команды перезагрузки для входа в Recovery",
                .uk: "Відправка команди перезавантаження для входу в Recovery"
            ],
            section: .recovery,
            icon: "cross.case.fill",
            gradientColors: [Color.purple, Color.indigo],
            keywords: ["recovery", "rec", "重启", "重啟", "双清", "雙清", "twrp", "orangefox"]
        ),
        LocalizedSearchItem(
            titles: [
                .zhHans: "清除 Cache 缓存分区",
                .zhHant: "清除 Cache 快取分區",
                .en: "Wipe Cache Partition",
                .fr: "Effacer la partition Cache",
                .ja: "Cache パーティションを消去",
                .es: "Limpiar partición Cache",
                .ko: "Cache 파티션 삭제",
                .ru: "Очистка раздела Cache",
                .uk: "Очищення розділу Cache"
            ],
            subtitles: [
                .zhHans: "清除系统暂存缓存分区，解决部分系统异常与卡顿",
                .zhHant: "清除系統暫存快取分區，解決部分系統異常",
                .en: "Clear temporary system cache partition to fix anomalies",
                .fr: "Effacez le cache système temporaire pour résoudre les anomalies",
                .ja: "システムの一時キャッシュを消去して不具合を解消",
                .es: "Borre la caché temporal del sistema para resolver problemas",
                .ko: "임시 시스템 캐시를 지워 이상 증상 해결",
                .ru: "Очистка временного системного кэша для устранения сбоев",
                .uk: "Очищення тимчасового системного кешу для усунення збоїв"
            ],
            section: .recovery,
            icon: "wind",
            gradientColors: [Color.purple, Color.indigo],
            keywords: ["cache", "缓存", "快取", "wipe", "双清", "清理"]
        ),
        LocalizedSearchItem(
            titles: [
                .zhHans: "清除 Data / 恢复出厂设置",
                .zhHant: "清除 Data / 恢復原廠設定",
                .en: "Wipe Data / Factory Reset",
                .fr: "Effacer les données / Réinitialisation",
                .ja: "Data を消去 / 工場出荷状態へ初期化",
                .es: "Borrar datos / Restablecer fábrica",
                .ko: "Data 삭제 / 공장 초기화",
                .ru: "Сброс данных к заводским настройкам",
                .uk: "Скидання даних до заводських налаштувань"
            ],
            subtitles: [
                .zhHans: "在 Recovery 模式下清除用户数据，还原出厂纯净状态",
                .zhHant: "在 Recovery 模式下清除使用者資料，還原出廠狀態",
                .en: "Erase user data in Recovery mode to restore clean factory state",
                .fr: "Effacez les données utilisateur en Recovery pour restaurer l'état d'usine",
                .ja: "Recoveryモードでユーザーデータを消去し工場出荷時の状態に復元",
                .es: "Borre los datos de usuario para restaurar el estado original",
                .ko: "Recovery 모드에서 사용자 데이터를 삭제하여 공장 초기화",
                .ru: "Очистка данных пользователя в Recovery для возврата к заводскому состоянию",
                .uk: "Очищення даних користувача в Recovery для повернення до заводського стану"
            ],
            section: .recovery,
            icon: "exclamationmark.triangle.fill",
            gradientColors: [Color.purple, Color.indigo],
            keywords: ["wipe", "data", "恢复出厂", "恢復原廠", "重置", "reset"]
        ),
        
        // 4. Shell
        LocalizedSearchItem(
            titles: [
                .zhHans: "交互式 ADB Shell 终端",
                .zhHant: "互動式 ADB Shell 終端機",
                .en: "Interactive ADB Shell Terminal",
                .fr: "Terminal interactif ADB Shell",
                .ja: "インタラクティブ ADB Shell ターミナル",
                .es: "Terminal interactiva ADB Shell",
                .ko: "대화형 ADB Shell 터미널",
                .ru: "Интерактивный терминал ADB Shell",
                .uk: "Інтерактивний термінал ADB Shell"
            ],
            subtitles: [
                .zhHans: "直接执行 Android 系统 Linux 命令与自定义脚本",
                .zhHant: "直接執行 Android 系統 Linux 命令與自訂腳本",
                .en: "Execute Android Linux shell commands and custom scripts directly",
                .fr: "Exécutez des commandes shell Linux et des scripts personnalisés",
                .ja: "Android Linux シェルコマンドやカスタムスクリプトを直接実行",
                .es: "Ejecute comandos de shell Linux y scripts personalizados directamente",
                .ko: "Android Linux 셸 명령어 및 스크립트 직접 실행",
                .ru: "Прямое выполнение команд Linux и пользовательских скриптов",
                .uk: "Пряме виконання команд Linux та власних скриптів"
            ],
            section: .shell,
            icon: "apple.terminal",
            gradientColors: [Color.teal, Color.blue],
            keywords: ["shell", "terminal", "终端", "終端", "命令", "脚本", "linux"]
        ),
        LocalizedSearchItem(
            titles: [
                .zhHans: "实时 Logcat 日志抓取",
                .zhHant: "即時 Logcat 日誌抓取",
                .en: "Live Logcat Log Capture",
                .fr: "Capture de logs Logcat en direct",
                .ja: "リアルタイム Logcat ログ取得",
                .es: "Captura de registros Logcat en vivo",
                .ko: "실시간 Logcat 로그 수집",
                .ru: "Сбор логов Logcat в реальном времени",
                .uk: "Збір логів Logcat у реальному часі"
            ],
            subtitles: [
                .zhHans: "实时流式传输并过滤设备系统日志与 Crash 崩溃堆栈",
                .zhHant: "即時串流並過濾設備系統日誌、Crash 崩潰堆疊",
                .en: "Stream and filter real-time device system logs and crash stack traces",
                .fr: "Diffusez et filtrez les logs système et rapports de crash",
                .ja: "デバイスのシステムログやクラッシュログをリアルタイムで取得・フィルタ",
                .es: "Transmita y filtre registros del sistema y bloqueos en tiempo real",
                .ko: "기기 시스템 로그 및 크래시 로그 실시간 스트리밍 및 필터링",
                .ru: "Потоковая передача и фильтрация системных логов и отчетов об ошибках",
                .uk: "Потокова передача та фільтрація системних логів та звітів про помилки"
            ],
            section: .shell,
            icon: "doc.text.magnifyingglass",
            gradientColors: [Color.teal, Color.blue],
            keywords: ["log", "logcat", "日志", "日誌", "崩溃", "crash", "debug"]
        ),
        LocalizedSearchItem(
            titles: [
                .zhHans: "系统动画缩放倍率调节",
                .zhHant: "系統動畫縮放倍率調節",
                .en: "Window & Animation Speed Scale",
                .fr: "Échelle de vitesse des animations",
                .ja: "システムアニメーション速度調整",
                .es: "Escala de velocidad de animaciones",
                .ko: "시스템 애니메이션 속도 조절",
                .ru: "Настройка скорости анимаций системы",
                .uk: "Налаштування швидкості анімацій системи"
            ],
            subtitles: [
                .zhHans: "加速或关闭窗口动画、过渡动画与动画时长",
                .zhHant: "加速或關閉窗口動畫、過渡動畫與動畫時長",
                .en: "Accelerate or disable window, transition and animator duration scales",
                .fr: "Accélérez ou désactivez les échelles d'animation de fenêtres",
                .ja: "ウィンドウアニメーションや遷移アニメーションを高速化または無効化",
                .es: "Acelere o desactive las animaciones de ventanas y transiciones",
                .ko: "창 애니메이션, 전환 효과 속도 가속 또는 비활성화",
                .ru: "Ускорение или отключение анимации окон и переходов",
                .uk: "Прискорення або вимкнення анімації вікон та переходів"
            ],
            section: .shell,
            icon: "gauge.with.needle",
            gradientColors: [Color.teal, Color.blue],
            keywords: ["动画", "動畫", "加速", "速度", "0.5x", "animation", "scale"]
        ),
        
        // 5. Apps
        LocalizedSearchItem(
            titles: [
                .zhHans: "本地 APK 拖拽安装",
                .zhHant: "本地 APK 拖曳安裝",
                .en: "Local APK Drag & Drop Install",
                .fr: "Installation APK locale par glisser-déposer",
                .ja: "ローカル APK のドラッグ＆ドロップインストール",
                .es: "Instalación de APK arrastrando y soltando",
                .ko: "로컬 APK 드래그 앤 드롭 설치",
                .ru: "Установка APK перетаскиванием",
                .uk: "Встановлення APK перетягуванням"
            ],
            subtitles: [
                .zhHans: "支持拖拽 APK/APKS 文件一键安装至设备",
                .zhHant: "支援拖曳 APK/APKS 檔案一鍵安裝至裝置",
                .en: "Drag and drop APK/APKS package to install with one click",
                .fr: "Glissez-déposez le fichier APK pour l'installer en un clic",
                .ja: "APKファイルをドラッグ＆ドロップしてワンクリックでインストール",
                .es: "Arrastre y suelte archivos APK para instalarlos con un clic",
                .ko: "APK/APKS 파일을 드래그하여 원클릭 설치",
                .ru: "Перетащите файл APK для быстрой установки в один клик",
                .uk: "Перетягніть файл APK для швидкого встановлення в один клік"
            ],
            section: .apps,
            icon: "arrow.down.app.fill",
            gradientColors: [Color.green, Color.mint],
            keywords: ["安装", "安裝", "apk", "app", "应用", "應用", "install", "拖拽"]
        ),
        LocalizedSearchItem(
            titles: [
                .zhHans: "导出 / 提取已安装 APK 安装包",
                .zhHant: "匯出 / 提取已安裝 APK 安裝包",
                .en: "Extract Installed APK Packages",
                .fr: "Extraire les packages APK installés",
                .ja: "インストール済み APK の抽出 / エクスポート",
                .es: "Extraer paquetes APK instalados",
                .ko: "설치된 APK 패키지 추출 / 내보내기",
                .ru: "Извлечение установленных APK файлов",
                .uk: "Вилучення встановлених APK файлів"
            ],
            subtitles: [
                .zhHans: "将手机内已安装的应用提取备份为 APK 文件至 Mac",
                .zhHant: "將手機內已安裝的應用提取備份為 APK 檔案至 Mac",
                .en: "Extract installed apps from device and save APK backup to your Mac",
                .fr: "Sauvegardez les applications installées sous forme de fichiers APK",
                .ja: "端末内のアプリをAPKファイルとしてMacに抽出・バックアップ",
                .es: "Extraiga aplicaciones instaladas y guarde copias APK en su Mac",
                .ko: "기기에 설치된 앱을 APK 파일로 추출하여 Mac에 백업",
                .ru: "Сохранение установленных приложений в виде APK на ваш Mac",
                .uk: "Збереження встановлених додатків у вигляді APK на ваш Mac"
            ],
            section: .apps,
            icon: "arrow.up.doc.fill",
            gradientColors: [Color.green, Color.mint],
            keywords: ["提取", "导出", "導出", "备份", "備份", "apk", "export"]
        ),
        LocalizedSearchItem(
            titles: [
                .zhHans: "第三方应用与系统应用管理",
                .zhHant: "第三方應用與系統應用管理",
                .en: "Manage User & System Applications",
                .fr: "Gérer les applications tierces et système",
                .ja: "サードパーティおよびシステムアプリの管理",
                .es: "Gestionar aplicaciones de usuario y del sistema",
                .ko: "사용자 및 시스템 애플리케이션 관리",
                .ru: "Управление пользовательскими и системными приложениями",
                .uk: "Керування додатками користувача та системними додатками"
            ],
            subtitles: [
                .zhHans: "过滤查看已安装应用列表、包名与详细版本",
                .zhHant: "過濾檢視已安裝應用清單、套件名稱與版本號",
                .en: "Filter installed application lists, package names and versions",
                .fr: "Filtrez la liste des applications, noms de paquets et versions",
                .ja: "インストール済みアプリ一覧、パッケージ名、バージョンを表示",
                .es: "Filtre listas de aplicaciones, nombres de paquetes y versiones",
                .ko: "설치된 앱 목록, 패키지 이름 및 버전 필터링",
                .ru: "Фильтрация списка установленных приложений и названий пакетов",
                .uk: "Фільтрація списку встановлених додатків та назв пакетів"
            ],
            section: .apps,
            icon: "app.badge.fill",
            gradientColors: [Color.green, Color.mint],
            keywords: ["包名", "应用列表", "清單", "package", "系统应用", "第三方"]
        ),
        
        // 6. Files
        LocalizedSearchItem(
            titles: [
                .zhHans: "电脑文件推送到手机 (Push)",
                .zhHant: "電腦檔案推送到手機 (Push)",
                .en: "Push Files to Device (Push)",
                .fr: "Pousser des fichiers vers l'appareil (Push)",
                .ja: "ファイルを端末へ転送 (Push)",
                .es: "Enviar archivos al dispositivo (Push)",
                .ko: "기기로 파일 전송 (Push)",
                .ru: "Отправка файлов на устройство (Push)",
                .uk: "Надсилання файлів на пристрій (Push)"
            ],
            subtitles: [
                .zhHans: "发送 Mac 本地文件或文件夹至手机指定存储路径",
                .zhHant: "傳送 Mac 本地檔案或資料夾至手機指定儲存路徑",
                .en: "Transfer local Mac files or directories to device destination path",
                .fr: "Transférez des fichiers ou dossiers locaux vers l'appareil",
                .ja: "Macのファイルやフォルダを端末の指定パスへ送信",
                .es: "Transfiera archivos locales desde el Mac a su dispositivo",
                .ko: "Mac 로컬 파일 또는 폴더를 기기 경로로 전송",
                .ru: "Передача локальных файлов с Mac на устройство",
                .uk: "Передача локальних файлів з Mac на пристрій"
            ],
            section: .files,
            icon: "arrow.up.circle.fill",
            gradientColors: [Color.orange, Color.yellow],
            keywords: ["push", "推送", "上传", "上傳", "文件", "檔案", "传输"]
        ),
        LocalizedSearchItem(
            titles: [
                .zhHans: "从手机下载拉取文件 (Pull)",
                .zhHant: "從手機下載拉取檔案 (Pull)",
                .en: "Pull Files from Device (Pull)",
                .fr: "Récupérer des fichiers de l'appareil (Pull)",
                .ja: "端末からファイルをダウンロード (Pull)",
                .es: "Descargar archivos del dispositivo (Pull)",
                .ko: "기기에서 파일 가져오기 (Pull)",
                .ru: "Загрузка файлов с устройства (Pull)",
                .uk: "Завантаження файлів з пристрою (Pull)"
            ],
            subtitles: [
                .zhHans: "将手机内任何文件或文件夹下载保存至 Mac",
                .zhHant: "將手機內任何檔案或資料夾下載儲存至 Mac",
                .en: "Download and save any file or folder from device to your Mac",
                .fr: "Téléchargez des fichiers ou dossiers de l'appareil sur votre Mac",
                .ja: "端末内の任意のファイルやフォルダをMacにダウンロード保存",
                .es: "Descargue y guarde cualquier archivo del dispositivo en su Mac",
                .ko: "기기 내 파일 또는 폴더를 Mac으로 다운로드 저장",
                .ru: "Скачивание любых файлов или папок с устройства на Mac",
                .uk: "Завантаження будь-яких файлів або папок з пристрою на Mac"
            ],
            section: .files,
            icon: "arrow.down.circle.fill",
            gradientColors: [Color.orange, Color.yellow],
            keywords: ["pull", "拉取", "下载", "下載", "文件", "檔案", "导出"]
        ),
        LocalizedSearchItem(
            titles: [
                .zhHans: "手机屏幕截图与复制",
                .zhHant: "手機螢幕截圖與複製",
                .en: "Device Screenshot & Clipboard Copy",
                .fr: "Capture d'écran et copie dans le presse-papiers",
                .ja: "端末スクリーンショットとコピー",
                .es: "Captura de pantalla y copia al portapapeles",
                .ko: "기기 화면 캡처 및 클립보드 복사",
                .ru: "Снимок экрана устройства и копирование",
                .uk: "Знімок екрана пристрою та копіювання"
            ],
            subtitles: [
                .zhHans: "一键截取手机当前画面，支持直接复制至 Mac 剪贴板",
                .zhHant: "一鍵截取手機當前畫面，支援直接複製至 Mac 剪貼簿",
                .en: "Capture current device screen with one click and copy to Mac clipboard",
                .fr: "Capturez l'écran de l'appareil et copiez-le dans le presse-papiers",
                .ja: "端末の現在画面をワンクリックで撮影しMacのクリップボードにコピー",
                .es: "Capture la pantalla del dispositivo y cópiela al portapapeles",
                .ko: "기기 화면을 원클릭으로 캡처하여 Mac 클립보드에 복사",
                .ru: "Снимок экрана в один клик и копирование в буфер обмена Mac",
                .uk: "Знімок екрана в один клік та копіювання в буфер обміну Mac"
            ],
            section: .files,
            icon: "camera.viewfinder",
            gradientColors: [Color.orange, Color.yellow],
            keywords: ["截图", "截圖", "截屏", "screenshot", "照片", "复制"]
        ),
        
        // 7. Settings
        LocalizedSearchItem(
            titles: [
                .zhHans: "软件外观主题设置 (深色 / 浅色)",
                .zhHant: "軟體外觀主題設置 (深色 / 淺色)",
                .en: "Appearance Theme (Dark / Light)",
                .fr: "Thème d'apparence (Sombre / Clair)",
                .ja: "外観テーマ設定 (ダーク / ライト)",
                .es: "Tema de apariencia (Oscuro / Claro)",
                .ko: "테마 설정 (다크 / 라이트)",
                .ru: "Тема оформления (Темная / Светлая)",
                .uk: "Тема оформлення (Темна / Світла)"
            ],
            subtitles: [
                .zhHans: "自定义切换深色液态玻璃、浅色玻璃或跟随系统外观",
                .zhHant: "自訂切換深色液態玻璃、淺色玻璃或跟隨系統外觀",
                .en: "Toggle between Dark liquid glass, Light frosted glass or System appearance",
                .fr: "Basculez entre verre sombre, verre clair ou l'apparence du système",
                .ja: "ダークガラス、ライトガラス、またはシステム外観に切り替え",
                .es: "Cambie entre vidrio oscuro, vidrio claro o aspecto del sistema",
                .ko: "다크 글래스, 라이트 글래스 또는 시스템 테마로 전환",
                .ru: "Переключение между темной, светлой темой или системным стилем",
                .uk: "Перемикання між темною, світлою темою або системним стилем"
            ],
            section: .settings,
            icon: "paintbrush.fill",
            gradientColors: [Color.gray, Color.secondary],
            keywords: ["主题", "主題", "深色", "浅色", "淺色", "外观", "外觀", "theme", "dark"]
        ),
        LocalizedSearchItem(
            titles: [
                .zhHans: "多语言切换 (支持法语等9种语言)",
                .zhHant: "多語言切換 (支援法語等9種語言)",
                .en: "Language Selection (9 Languages)",
                .fr: "Sélection de la langue (9 langues)",
                .ja: "言語切り替え (9言語対応)",
                .es: "Selección de idioma (9 idiomas)",
                .ko: "언어 선택 (9개 언어 지원)",
                .ru: "Выбор языка (Поддержка 9 языков)",
                .uk: "Вибір мови (Підтримка 9 мов)"
            ],
            subtitles: [
                .zhHans: "切换简体中文、繁体中文、英语、法语、日语等",
                .zhHant: "切換簡體中文、繁體中文、英語、法語、日語等",
                .en: "Switch between English, French, Chinese, Japanese, Korean, Russian, etc.",
                .fr: "Basculez entre le français, l'anglais, le chinois, le japonais...",
                .ja: "日本語、英語、簡体字中国語、繁体字中国語、フランス語などを選択",
                .es: "Cambie entre español, inglés, francés, chino, japonés...",
                .ko: "한국어, 영어, 프랑스어, 중국어, 일본어 등으로 전환",
                .ru: "Переключение между русским, английским, французским, китайским...",
                .uk: "Перемикання між українською, англійською, французькою..."
            ],
            section: .settings,
            icon: "globe",
            gradientColors: [Color.gray, Color.secondary],
            keywords: ["语言", "語言", "language", "法语", "法語", "英语", "英語", "中文"]
        ),
        LocalizedSearchItem(
            titles: [
                .zhHans: "ADB 与 Fastboot 工具路径检测",
                .zhHant: "ADB 與 Fastboot 工具路徑檢測",
                .en: "ADB & Fastboot Tool Path Verification",
                .fr: "Vérification des chemins d'outils ADB et Fastboot",
                .ja: "ADB および Fastboot パス検出",
                .es: "Verificación de rutas de ADB y Fastboot",
                .ko: "ADB 및 Fastboot 도구 경로 확인",
                .ru: "Проверка путей к инструментам ADB и Fastboot",
                .uk: "Перевірка шляхів до інструментів ADB та Fastboot"
            ],
            subtitles: [
                .zhHans: "检查本机 Android Platform-tools 工具版本与可用性",
                .zhHant: "檢查本機 Android Platform-tools 工具版本與有效性",
                .en: "Verify Platform-tools binary existence, version and permissions",
                .fr: "Vérifiez les versions et autorisations des outils Platform-tools",
                .ja: "Android Platform-tools のバージョンと有効性を確認",
                .es: "Verifique la versión y disponibilidad de Android Platform-tools",
                .ko: "Android Platform-tools 도구 버전 및 사용 가능 여부 확인",
                .ru: "Проверка версии и доступности бинарных файлов Platform-tools",
                .uk: "Перевірка версії та доступності бінарних файлів Platform-tools"
            ],
            section: .settings,
            icon: "hammer.fill",
            gradientColors: [Color.gray, Color.secondary],
            keywords: ["adb", "fastboot", "工具", "路径", "路徑", "platform-tools"]
        ),
        LocalizedSearchItem(
            titles: [
                .zhHans: "GitHub 开源仓库与开源声明",
                .zhHant: "GitHub 開源倉庫與開源聲明",
                .en: "GitHub Repository & Open Source License",
                .fr: "Dépôt GitHub et licence open source",
                .ja: "GitHub オープンソースリポジトリとライセンス",
                .es: "Repositorio GitHub y licencia de código abierto",
                .ko: "GitHub 오픈 소스 저장소 및 라이선스",
                .ru: "Репозиторий GitHub и лицензия открытого исходного кода",
                .uk: "Репозиторій GitHub та ліцензія з відкритим кодом"
            ],
            subtitles: [
                .zhHans: "访问项目开源仓库并查看 MIT 开源许可证",
                .zhHant: "造訪專案開源倉庫並查看 MIT 開源許可證",
                .en: "Visit official open-source GitHub repository and view MIT license",
                .fr: "Visitez le dépôt GitHub officiel et consultez la licence MIT",
                .ja: "公式GitHubリポジトリを訪問し、MITライセンスを確認",
                .es: "Visite el repositorio oficial de GitHub y consulte la licencia MIT",
                .ko: "공식 GitHub 저장소 방문 및 MIT 라이선스 확인",
                .ru: "Посетите официальный репозиторий GitHub и просмотрите лицензию MIT",
                .uk: "Відвідайте офіційний репозиторій GitHub та перегляньте ліцензію MIT"
            ],
            section: .settings,
            icon: "link",
            gradientColors: [Color.gray, Color.secondary],
            keywords: ["github", "开源", "開源", "仓库", "倉庫", "repo", "作者", "关于", "關於"]
        )
    ]
    
    private var filteredFeatures: [LocalizedSearchItem] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            return allFeatures
        }
        return allFeatures.filter { item in
            let title = item.title(for: curLang).lowercased()
            let subtitle = item.subtitle(for: curLang).lowercased()
            let sectionTitle = item.section.title.lowercased()
            return title.contains(q) ||
                   subtitle.contains(q) ||
                   sectionTitle.contains(q) ||
                   item.keywords.contains { $0.lowercased().contains(q) }
        }
    }
    
    public init(isPresented: Binding<Bool>, onSelectSection: @escaping (NavigationSection) -> Void) {
        self._isPresented = isPresented
        self.onSelectSection = onSelectSection
    }
    
    public var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.15)) {
                        isPresented = false
                    }
                }
            
            // Spotlight Glass Card
            VStack(spacing: 0) {
                // Search Input Header
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField(L10n("search_placeholder"), text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15))
                        .focused($isFieldFocused)
                        .onSubmit {
                            if let first = filteredFeatures.first {
                                selectFeature(first)
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text("ESC")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.primary.opacity(0.08))
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                
                Divider().opacity(0.3)
                
                // Results List
                if filteredFeatures.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "questionmark.folder")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.top, 30)
                        
                        Text(L10n("search_no_results"))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 30)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(filteredFeatures) { item in
                                resultRow(item)
                            }
                        }
                        .padding(8)
                    }
                    .frame(maxHeight: 380)
                }
            }
            .frame(width: 540)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(NSColor.windowBackgroundColor).opacity(0.75))
                    
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), Color.primary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.25), radius: 30, x: 0, y: 15)
            .padding(.bottom, 100)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFieldFocused = true
            }
        }
    }
    
    private func resultRow(_ item: LocalizedSearchItem) -> some View {
        Button {
            selectFeature(item)
        } label: {
            HStack(spacing: 12) {
                // Section Squircle Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: item.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 28, height: 28)
                
                // Title and Subtitle
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.title(for: curLang))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text(item.section.title)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(
                                Capsule()
                                    .fill(Color.primary.opacity(0.06))
                            )
                    }
                    
                    Text(item.subtitle(for: curLang))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
        }
        .buttonStyle(.plain)
    }
    
    private func selectFeature(_ item: LocalizedSearchItem) {
        withAnimation(.easeOut(duration: 0.15)) {
            isPresented = false
            onSelectSection(item.section)
        }
    }
}
