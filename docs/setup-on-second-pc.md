# Подключение второго компьютера к разработке

Эта инструкция поможет скачать проект на другой компьютер, запустить его в Godot и безопасно отправлять изменения в общий репозиторий.

## 1. Получить доступ к GitHub

Репозиторий проекта:

```text
https://github.com/lexuss1979/family-game
```

Если репозиторий приватный, владелец должен открыть на GitHub `Settings → Collaborators → Add people`, добавить аккаунт второго разработчика и дождаться, пока приглашение будет принято.

Для чтения публичного репозитория приглашение не требуется, но без доступа Collaborator отправлять изменения обратно нельзя.

## 2. Установить необходимые программы

Понадобятся:

- Git for Windows;
- Godot `4.7` для Windows, 64-bit Standard.

Проект рассчитан на Godot 4.7. Более новая версия может предложить обновить формат проекта, поэтому на всех компьютерах лучше использовать одинаковую версию.

Godot не требует установки. ZIP-архив можно распаковать, например, сюда:

```text
C:\Tools\Godot\4.7\
```

В каталоге должны находиться файлы:

```text
Godot_v4.7-stable_win64.exe
Godot_v4.7-stable_win64_console.exe
```

## 3. Настроить Git

Один раз выполнить в PowerShell, подставив имя и почту разработчика:

```powershell
git config --global user.name "Имя разработчика"
git config --global user.email "email@example.com"
```

Почту желательно использовать ту же, которая добавлена в аккаунт GitHub.

## 4. Скачать проект

Рекомендуется хранить проект в обычной локальной папке, не в OneDrive:

```powershell
mkdir C:\projects -ErrorAction SilentlyContinue
cd C:\projects
git clone https://github.com/lexuss1979/family-game.git
cd family-game
```

Проверить загруженную версию:

```powershell
git status
git log -1 --oneline
```

## 5. Открыть проект в Godot

1. Запустить `C:\Tools\Godot\4.7\Godot_v4.7-stable_win64.exe`.
2. Нажать `Import`.
3. Выбрать `C:\projects\family-game\project.godot`.
4. Нажать `Import & Edit`.
5. Дождаться первого импорта изображений.
6. Нажать `F5` или кнопку запуска проекта.

Каталог `.godot` создаётся автоматически и не должен добавляться в Git.

## 6. Проверить проект из консоли

Из каталога проекта можно выполнить smoke-тест:

```powershell
cd C:\projects\family-game
& "C:\Tools\Godot\4.7\Godot_v4.7-stable_win64_console.exe" --headless --path . --script res://tools/smoke_test.gd
```

В конце должно появиться сообщение `Smoke test passed`.

## 7. Начать новую задачу

Не рекомендуется работать вдвоём непосредственно в `main`. Для каждой задачи лучше создавать отдельную ветку:

```powershell
cd C:\projects\family-game
git switch main
git pull --ff-only
git switch -c son/task-name
```

Вместо `task-name` нужно использовать короткое описание, например:

```powershell
git switch -c son/add-kitchen-table
```

## 8. Сохранить и отправить изменения

Проверить, какие файлы изменились:

```powershell
git status --short
git diff
```

Добавить только файлы текущей задачи, например:

```powershell
git add scripts/main.gd assets/furniture/kitchen-table.png
git commit -m "Add kitchen table"
git push -u origin son/add-kitchen-table
```

При первом `push` Git for Windows обычно открывает браузер для входа в GitHub. После отправки ветки на GitHub нужно создать Pull Request в `main`.

## 9. Получить свежие изменения

Перед началом следующей задачи:

```powershell
git switch main
git pull --ff-only
```

После этого создаётся новая рабочая ветка.

## 10. Как уменьшить число конфликтов

- Не редактировать одновременно один и тот же `.gd`-файл.
- Заранее договариваться, кто работает с конкретным исходным изображением в `design`.
- PNG-файлы нельзя автоматически объединить при конфликте.
- Перед созданием ветки всегда обновлять `main`.
- Перед коммитом проверять `git status --short` и не использовать `git add .`, если в каталоге есть посторонние файлы.
- Не добавлять в Git каталог `.godot` и временные файлы редактора.

Если возник конфликт, не удаляйте чужие изменения и не используйте `git reset --hard`. Лучше остановиться и вместе определить, какую версию файла сохранить.

## Короткий ежедневный сценарий

```powershell
git switch main
git pull --ff-only
git switch -c son/new-task

# Работа в Godot

git status --short
git add <нужные файлы>
git commit -m "Describe the change"
git push -u origin son/new-task
```

После этого создаётся Pull Request на GitHub.
