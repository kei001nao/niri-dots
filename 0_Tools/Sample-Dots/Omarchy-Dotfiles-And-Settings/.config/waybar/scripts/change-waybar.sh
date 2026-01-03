#!/bin/bash

WAYBAR_DIR="$HOME/.config/waybar"
TEMPLATES_DIR="$WAYBAR_DIR/templates"

# 対象となる設定ファイルのベース名
CSS_FILE="style.css"
CONFIG_FILE="config.jsonc"

# 1. テンプレートディレクトリ内のファイルから、利用可能な「テーマ番号」のリストを動的に生成する
# style-X.css の 'X' の部分だけを抽出し、重複を排除してソートする
THEME_INDICES=( $(ls -1 "$TEMPLATES_DIR"/style-*.css | grep -oP 'style-\K\d+(?=\.css)' | sort -n | uniq) )

NUM_THEMES=${#THEME_INDICES[@]}

# テーマが1つ以下しかなければ何もしない
if [ "$NUM_THEMES" -le 1 ]; then
    echo "切り替え可能なテーマが2つ以上ありません。見つかったテーマ番号: ${THEME_INDICES[@]}"
    exit 1
fi

# 2. 現在の style.css のリンク先から、現在のテーマ番号を取得する
CURRENT_CSS_TARGET=$(readlink "$WAYBAR_DIR/$CSS_FILE" | xargs basename)
# 正規表現を使って番号を抽出
CURRENT_INDEX_STR=$(echo "$CURRENT_CSS_TARGET" | grep -oP 'style-\K\d+(?=\.css)')

CURRENT_THEME_INDEX=-1
# 現在の番号がリストの何番目（インデックス）にあるか探す
for i in "${!THEME_INDICES[@]}"; do
   if [[ "${THEME_INDICES[$i]}" == "$CURRENT_INDEX_STR" ]]; then
       CURRENT_THEME_INDEX=$i
       break
   fi
done

# 3. 次のテーマのインデックス番号を計算する
if [ "$CURRENT_THEME_INDEX" -eq -1 ]; then
    echo "現在のテーマが見つかりませんでした。最初のテーマに戻します。"
    NEXT_THEME_INDEX=0
else
    # 次のテーマインデックス = (現在のインデックス + 1) % 総数
    NEXT_THEME_INDEX=$(((CURRENT_THEME_INDEX + 1) % NUM_THEMES))
fi

# 次に適用するテーマの番号（例: 1, 2, 3...）を取得
NEXT_THEME_NUM=${THEME_INDICES[$NEXT_THEME_INDEX]}

# 4. リンクを削除し、新しいペアのリンクを張り直す
rm "$WAYBAR_DIR/$CSS_FILE" "$WAYBAR_DIR/$CONFIG_FILE"

ln -s "$TEMPLATES_DIR/style-$NEXT_THEME_NUM.css" "$WAYBAR_DIR/$CSS_FILE"
ln -s "$TEMPLATES_DIR/config-$NEXT_THEME_NUM.jsonc" "$WAYBAR_DIR/$CONFIG_FILE"

echo "テーマを $NEXT_THEME_NUM 番に切り替えました。"

# Waybar に設定のリロードを指示するコマンド（必要に応じてコメントアウトを外す）
sleep 0.8
omarchy-restart-waybar
#killall -SIGUSR2 waybar
