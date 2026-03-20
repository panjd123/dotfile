# List cached Hugging Face models grouped by namespace prefix.
hf_list() {
    local CACHE_DIR="${HF_HOME:-$HOME/.cache}/huggingface/hub"

    if [ ! -d "$CACHE_DIR" ]; then
        echo "Cache directory does not exist: $CACHE_DIR"
        return 1
    fi

    declare -A grouped_models

    # 遍历所有模型目录
    for dir in "$CACHE_DIR"/models--*/; do
        local model_dir
        model_dir=$(basename "$dir")
        # 去掉 models-- 前缀
        local model_name="${model_dir//models--/}"
        # 将 -- 替换为 /，得到 user/model-name
        model_name="${model_name//--//}"
        # 取前缀作为分组 key
        local prefix="${model_name%%/*}"
        grouped_models["$prefix"]+="$model_name"$'\n'
    done

    echo "Models in Hugging Face cache (grouped by prefix):"
    echo "-------------------------------------------------"

    # 输出分组，前缀排序
    for prefix in $(printf "%s\n" "${!grouped_models[@]}" | sort); do
        echo "$prefix:"
        while IFS= read -r model; do
            [ -z "$model" ] && continue
            echo "  - $model"
        done <<< "$(printf "%s" "${grouped_models[$prefix]}" | sort)"
    done
}
alias hf-list='hf_list'
