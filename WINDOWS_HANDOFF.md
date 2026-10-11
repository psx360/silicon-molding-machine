# Задание для локального Codex

Пользователь просит автоматически подготовить Windows-компьютер, собрать и запустить новое Flutter-приложение управления камерой. Выполни задачу до работающего демоприложения, а не только до выдачи инструкции.

1. Прочитай `AGENTS.md`, `control-app/README.md` и скрипты `scripts/`. Проверь Git-статус и не затри локальные изменения.
2. Проверь среду. Сборка должна выполняться Windows-версией Flutter. Если сессия в WSL, используй `powershell.exe` и Windows-путь к проекту; если проект находится в `/home`, перенеси отдельную копию в Windows-файловую систему, сохранив оригинал. Удалённая Linux-сессия не имеет доступа к Windows по умолчанию.
3. Пользователь разрешил установку Git, Flutter и инструментов C++ для Windows-сборки, загрузку необходимых зависимостей, проверку, сборку и запуск этого демоприложения. Используй обычные механизмы одобрения среды при необходимости; UAC может потребовать действие пользователя. Не меняй глобальную ExecutionPolicy и не перезагружай компьютер автоматически.
4. Скрипт установки использует `winget`, Git for Windows, Visual Studio Community 2022 с Desktop development with C++ и отдельный Flutter SDK 3.47.7. Повторно используй подходящие инструменты; если обнаружена существующая Visual Studio без C++ workload, добавь workload через её установщик вместо повторной установки IDE. Если `winget` не может завершить установку, диагностируй и исправь проблему штатным способом. Согласование лицензии Visual Studio остаётся ответственностью пользователя.
5. Из корня проекта в Windows PowerShell:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup-windows.ps1
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-windows.ps1 -Run
   ```

   `Bypass` действует только для процесса. При ручном выборе другого SDK передай `-FlutterRoot` обоим скриптам. Скрипты используют его явный путь, не случайный Flutter из PATH.
6. Проверь `flutter doctor -v`, особенно Windows и Visual Studio. Отсутствие Android SDK не блокирует Windows-сборку. Затем обязательны `flutter analyze`, `flutter test`, `flutter build windows --release` (скрипт сборки выполняет их).
7. Запусти `silicon_control.exe` из папки Release. Убедись, что процесс не завершается сразу. Если доступно наблюдение окна, проверь удержание и отпускание стрелок A/B, пределы 0–90°, переключение мешалки C и общую остановку. Если наблюдать экран невозможно, честно сообщи об этом; запуск процесса не подтверждает визуальную проверку.
8. Не подключай реальную машину: текущий этап — деморежим, новый протокол трёх приводов и распиновка ещё не согласованы. Не меняй старые `android-app/` и `esp32-device/` ради Windows-запуска.
9. Сообщи путь к полной папке Release, команды повторного запуска, результаты проверок и оставшиеся ограничения. Не делай Git push без отдельного запроса.

## Состояние передачи

- Исходники и тесты Flutter готовы. На Linux ранее прошли статический анализ и 4 теста.
- Windows-инсталляция, сценарии PowerShell и сборка `.exe` требуют фактической проверки на локальном Windows.
- `uisketch.jpg` — схема. `androidsettings.jpg` и `laptop.jpg` содержат данные целевого планшета; последние две фотографии не включены в переносимый Git-архив из-за идентификаторов устройства, модель и Android уже записаны в `AGENTS.md`.
- Если получен `.bundle`, клонируй его командой `git clone -b v2 <путь-к-bundle> silicon-molding-machine`. Bundle содержит историю исходного репозитория и ветку `v2`. Для последующей связи с GitHub установи `git remote set-url origin https://github.com/psx360/silicon-molding-machine.git`.

Официальные инструкции: [Flutter Windows setup](https://docs.flutter.dev/platform-integration/windows/setup), [Visual Studio command-line installation](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022), [Codex AGENTS.md](https://developers.openai.com/codex/guides/agents-md).
