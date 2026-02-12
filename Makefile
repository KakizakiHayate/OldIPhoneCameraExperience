.PHONY: help lint lint-fix test build clean open check ci

# デフォルトターゲット
.DEFAULT_GOAL := help

# プロジェクト設定
PROJECT = OldIPhoneCameraExperience.xcodeproj
SCHEME = OldIPhoneCameraExperience
SIMULATOR = platform=iOS Simulator,name=iPhone 16

# ===== Lintチェック =====
## SwiftLint実行
lint:
	@echo "Running SwiftLint..."
	@swiftlint

## SwiftLint自動修正
lint-fix:
	@echo "Running SwiftLint auto-fix..."
	@swiftlint --fix
	@echo ""
	@echo "Running lint check after fix..."
	@$(MAKE) lint

# ===== テスト =====
## ユニットテスト実行
test:
	@echo "Running tests..."
	@xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination '$(SIMULATOR)' \
		-quiet

# ===== ビルド =====
## リリースビルド
build:
	@echo "Building release..."
	@xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination '$(SIMULATOR)' \
		-configuration Release \
		-quiet

# ===== 開発支援 =====
## DerivedDataクリア + ビルドキャッシュ削除
clean:
	@echo "Cleaning DerivedData..."
	@xcodebuild clean \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-quiet
	@rm -rf ~/Library/Developer/Xcode/DerivedData/$(SCHEME)-*
	@echo "DerivedData cleaned."

## Xcodeでプロジェクトを開く
open:
	@open $(PROJECT)

# ===== 品質チェック =====
## lint + test を一括実行
check:
	@echo "Running full check..."
	@$(MAKE) lint
	@echo ""
	@$(MAKE) test

## CI用全チェック(lint + test + build)
ci:
	@echo "Running CI pipeline..."
	@$(MAKE) lint
	@echo ""
	@$(MAKE) test
	@echo ""
	@$(MAKE) build
	@echo ""
	@echo "CI pipeline completed!"

# ===== ヘルプ =====
## コマンド一覧表示
help:
	@echo "Available commands:"
	@echo ""
	@echo "  Lint:"
	@echo "    make lint          - Run SwiftLint"
	@echo "    make lint-fix      - Auto-fix SwiftLint issues"
	@echo ""
	@echo "  Test:"
	@echo "    make test          - Run unit tests"
	@echo ""
	@echo "  Build:"
	@echo "    make build         - Build release"
	@echo ""
	@echo "  Development:"
	@echo "    make clean         - Clean DerivedData and build cache"
	@echo "    make open          - Open project in Xcode"
	@echo ""
	@echo "  Quality:"
	@echo "    make check         - Run lint + test"
	@echo "    make ci            - Run full CI pipeline (lint + test + build)"
