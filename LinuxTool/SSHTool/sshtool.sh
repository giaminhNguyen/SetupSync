#!/usr/bin/env bash
# Công cụ quản lý SSH - Phiên bản Linux
# Tương đương SSHTool.bat trên Windows

set -u
shopt -s nullglob

SSH_DIR="${HOME}/.ssh"
CONFIG_FILE="${SSH_DIR}/config"
TMP_FILE="${SSH_DIR}/config.tmp"

# ===== Màu ANSI =====
C_RESET=$'\033[0m'
C_RED=$'\033[1;31m'
C_GREEN=$'\033[1;32m'
C_YELLOW=$'\033[1;33m'
C_BLUE=$'\033[1;34m'
C_MAGENTA=$'\033[1;35m'
C_CYAN=$'\033[1;36m'
C_WHITE=$'\033[1;37m'
C_GRAY=$'\033[0;37m'

# ===== Khởi tạo =====
init_ssh_dir() {
    if [[ ! -d "$SSH_DIR" ]]; then
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
        msg_info "Đã tạo thư mục SSH: $SSH_DIR"
    fi
    if [[ ! -f "$CONFIG_FILE" ]]; then
        : > "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"
        msg_info "Đã tự động tạo file config rỗng: $CONFIG_FILE"
        echo
        read -rp "  Nhấn Enter để tiếp tục..."
    fi
}

# ===== Tiện ích hiển thị =====
header() {
    printf "%s╔════════════════════════════════════════════════════════════════════╗%s\n" "$C_CYAN" "$C_RESET"
    printf "%s║                       CÔNG CỤ QUẢN LÝ SSH                          ║%s\n" "$C_GREEN" "$C_RESET"
    printf "%s╠════════════════════════════════════════════════════════════════════╣%s\n" "$C_CYAN" "$C_RESET"
    printf "%s║  Thư mục SSH: %-52s ║%s\n" "$C_CYAN" "$SSH_DIR" "$C_RESET"
    printf "%s╚════════════════════════════════════════════════════════════════════╝%s\n" "$C_CYAN" "$C_RESET"
}

box() {
    local title="$1"
    printf "%s╔════════════════════════════════════════════════════════════════════╗%s\n" "$C_GREEN" "$C_RESET"
    printf "%s║%-68s║%s\n" "$C_GREEN" "  $title" "$C_RESET"
    printf "%s╚════════════════════════════════════════════════════════════════════╝%s\n" "$C_GREEN" "$C_RESET"
}

menu_item() {
    local num="$1" text="$2" color="${3:-$C_CYAN}"
    printf "  %s[%s]%s %s\n" "$color" "$num" "$C_RESET" "$text"
}

msg_ok()    { printf "\n  %s[THÀNH CÔNG]%s %s\n" "$C_GREEN"   "$C_RESET" "$1"; }
msg_error() { printf "\n  %s[LỖI]%s %s\n"        "$C_RED"     "$C_RESET" "$1"; }
msg_warn()  { printf "\n  %s[CẢNH BÁO]%s %s\n"   "$C_YELLOW"  "$C_RESET" "$1"; }
msg_info()  { printf "\n  %s[THÔNG TIN]%s %s\n"  "$C_MAGENTA" "$C_RESET" "$1"; }

pause_menu() {
    echo
    read -rp "  $(printf '%s' "$C_MAGENTA")Nhấn Enter để quay về menu...$(printf '%s' "$C_RESET")"
}

pause_manage_key() {
    echo
    read -rp "  $(printf '%s' "$C_MAGENTA")Nhấn Enter để quay về quản lý SSH key...$(printf '%s' "$C_RESET")"
}

# ===== Clipboard =====
detect_clipboard() {
    if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null 2>&1; then
        CLIP_CMD="wl-copy"
    elif command -v xclip >/dev/null 2>&1; then
        CLIP_CMD="xclip -selection clipboard"
    elif command -v xsel >/dev/null 2>&1; then
        CLIP_CMD="xsel --clipboard --input"
    elif command -v pbcopy >/dev/null 2>&1; then
        CLIP_CMD="pbcopy"
    else
        CLIP_CMD=""
    fi
}

copy_to_clipboard() {
    local file="$1"
    if [[ -z "${CLIP_CMD:-}" ]]; then
        msg_warn "Không tìm thấy công cụ clipboard (xclip/xsel/wl-copy). Hiển thị nội dung để copy thủ công:"
        echo
        printf "%s" "$C_YELLOW"
        cat "$file"
        printf "%s\n" "$C_RESET"
        return 1
    fi
    # shellcheck disable=SC2086
    cat "$file" | $CLIP_CMD
}

# ===== Liệt kê key =====
list_key_files() {
    local f
    for f in "$SSH_DIR"/*; do
        [[ -f "$f" ]] || continue
        local name
        name="$(basename "$f")"
        case "$name" in
            config|known_hosts|known_hosts.old|authorized_keys|environment|rc) continue ;;
        esac
        [[ "$name" == *.pub ]] && continue
        printf '%s\n' "$name"
    done
}

show_keys_select() {
    KEY_LIST=()
    local name
    while IFS= read -r name; do
        KEY_LIST+=("$name")
    done < <(list_key_files)

    if [[ ${#KEY_LIST[@]} -eq 0 ]]; then
        msg_error "Không có SSH key nào."
        return 1
    fi

    local i=1
    for name in "${KEY_LIST[@]}"; do
        printf "  %s[%d]%s %s\n" "$C_YELLOW" "$i" "$C_RESET" "$name"
        ((i++))
    done
    echo
    return 0
}

get_key_by_index() {
    local idx="$1"
    if ! [[ "$idx" =~ ^[0-9]+$ ]]; then return 1; fi
    if (( idx < 1 || idx > ${#KEY_LIST[@]} )); then return 1; fi
    SELECTED_KEY="${KEY_LIST[$((idx-1))]}"
    return 0
}

# ===== Danh sách & copy public key =====
list_keys_menu() {
    while true; do
        clear
        header
        echo
        box "DANH SÁCH SSH KEY VÀ PUBLIC KEY"
        echo

        KEY_LIST=()
        local name
        while IFS= read -r name; do
            KEY_LIST+=("$name")
        done < <(list_key_files)

        if [[ ${#KEY_LIST[@]} -eq 0 ]]; then
            msg_error "Không tìm thấy SSH key nào."
            echo
        else
            local i=1
            for name in "${KEY_LIST[@]}"; do
                local path="$SSH_DIR/$name"
                local key_type="(không rõ)"
                local key_date
                key_date="$(date -r "$path" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo '?')"
                if [[ -f "$path.pub" ]]; then
                    key_type="$(awk '{print $1; exit}' "$path.pub" 2>/dev/null || echo '(không rõ)')"
                fi
                printf "  %s[%d]%s %s\n" "$C_YELLOW" "$i" "$C_RESET" "$name"
                printf "      %sLoại  %s : %s\n" "$C_BLUE" "$C_RESET" "$key_type"
                printf "      %sNgày  %s : %s\n" "$C_BLUE" "$C_RESET" "$key_date"
                if [[ -f "$path.pub" ]]; then
                    printf "      %sPublic%s : %s%s.pub%s\n" "$C_BLUE" "$C_RESET" "$C_GREEN" "$name" "$C_RESET"
                else
                    printf "      %sPublic%s : %s(không tìm thấy)%s\n" "$C_BLUE" "$C_RESET" "$C_RED" "$C_RESET"
                fi
                echo
                ((i++))
            done
        fi

        printf "  %s[C]%s Copy public key theo số\n" "$C_GREEN" "$C_RESET"
        printf "  %s[M]%s Quay về menu\n" "$C_CYAN" "$C_RESET"
        echo
        read -rp "  Chọn thao tác: " choice
        case "${choice,,}" in
            c) copy_pub_menu ;;
            m|"") return ;;
            *) ;;
        esac
    done
}

copy_pub_menu() {
    clear
    header
    echo
    box "COPY PUBLIC KEY"
    echo
    show_keys_select || { pause_menu; return; }
    read -rp "  Nhập số key để copy public key (hoặc Q để về menu): " idx
    [[ "${idx,,}" == "q" || -z "$idx" ]] && return

    if ! get_key_by_index "$idx"; then
        msg_error "Số không hợp lệ."
        pause_menu
        return
    fi

    local pub="$SSH_DIR/$SELECTED_KEY.pub"
    if [[ ! -f "$pub" ]]; then
        msg_error "Không tìm thấy file public key."
        pause_menu
        return
    fi

    if copy_to_clipboard "$pub"; then
        msg_ok "Đã copy public key vào clipboard: $pub"
    fi
    pause_menu
}

# ===== Quản lý SSH key =====
manage_key_menu() {
    while true; do
        clear
        header
        echo
        box "QUẢN LÝ SSH KEY"
        echo
        menu_item 1 "Tạo SSH mới"               "$C_CYAN"
        menu_item 2 "Chỉnh sửa SSH key"         "$C_MAGENTA"
        menu_item 3 "Xoá SSH key"               "$C_RED"
        menu_item 4 "Test kết nối SSH"          "$C_BLUE"
        menu_item 0 "Quay về menu chính"        "$C_GRAY"
        echo
        read -rp "  Chọn thao tác: " opt
        case "$opt" in
            1) create_key ;;
            2) edit_key ;;
            3) delete_key ;;
            4) test_ssh ;;
            0|"") return ;;
        esac
    done
}

create_key() {
    clear
    header
    echo
    box "TẠO SSH MỚI"
    echo

    read -rp "  Tên key mới (Q để quay lại): " new_key
    [[ "${new_key,,}" == "q" || -z "$new_key" ]] && return

    if [[ "$new_key" =~ [[:space:]\&\^\<\>\|\;\,\=\%] ]]; then
        msg_error "Tên key không được chứa khoảng trắng hoặc ký tự đặc biệt."
        pause_manage_key
        return
    fi

    read -rp "  Email / comment (Q để quay lại): " new_email
    [[ "${new_email,,}" == "q" || -z "$new_email" ]] && return

    if [[ -e "$SSH_DIR/$new_key" ]]; then
        msg_error "Key đã tồn tại: $new_key"
        pause_manage_key
        return
    fi

    echo
    printf "  %sChọn loại key:%s\n" "$C_GREEN" "$C_RESET"
    printf "  %s[1]%s ed25519  (khuyên dùng - nhanh, an toàn, key ngắn)\n" "$C_YELLOW" "$C_RESET"
    printf "  %s[2]%s rsa 4096 (tương thích rộng, hỗ trợ hệ thống cũ)\n"   "$C_YELLOW" "$C_RESET"
    printf "  %s[3]%s ecdsa    (cân bằng giữa tốc độ và tương thích)\n"   "$C_YELLOW" "$C_RESET"
    echo
    read -rp "  Chọn loại key: " kt
    local key_type="" bits=()
    case "$kt" in
        1) key_type="ed25519" ;;
        2) key_type="rsa";    bits=(-b 4096) ;;
        3) key_type="ecdsa";  bits=(-b 521) ;;
        *) msg_error "Lựa chọn không hợp lệ."; pause_manage_key; return ;;
    esac

    echo
    printf "  %sĐang tạo key loại %s...%s\n" "$C_YELLOW" "$key_type" "$C_RESET"
    ssh-keygen -t "$key_type" "${bits[@]}" -C "$new_email" -f "$SSH_DIR/$new_key"

    msg_ok "Hoàn tất. Đã tạo key $key_type: $new_key"
    pause_manage_key
}

delete_key() {
    clear
    header
    echo
    box "XOÁ SSH KEY"
    echo

    show_keys_select || { pause_manage_key; return; }
    read -rp "  Chọn số key cần xoá (hoặc Q để quay lại): " idx
    [[ "${idx,,}" == "q" || -z "$idx" ]] && return

    if ! get_key_by_index "$idx"; then
        msg_error "Số key không hợp lệ."
        pause_manage_key
        return
    fi

    msg_warn "Bạn sắp xoá: $SELECTED_KEY"
    read -rp "  Xác nhận xoá? [y/N]: " confirm
    [[ "${confirm,,}" != "y" ]] && return

    rm -f "$SSH_DIR/$SELECTED_KEY" "$SSH_DIR/$SELECTED_KEY.pub"
    remove_key_from_config "$SSH_DIR/$SELECTED_KEY"
    msg_ok "Đã xoá key."
    pause_manage_key
}

edit_key() {
    clear
    header
    echo
    box "CHỈNH SỬA SSH KEY"
    echo

    show_keys_select || { pause_manage_key; return; }
    read -rp "  Chọn số key cần chỉnh sửa (hoặc Q để quay lại): " idx
    [[ "${idx,,}" == "q" || -z "$idx" ]] && return

    if ! get_key_by_index "$idx"; then
        msg_error "Số key không hợp lệ."
        pause_manage_key
        return
    fi

    local edit_key_name="$SELECTED_KEY"
    msg_info "Key đã chọn: $edit_key_name"
    echo
    printf "  %sChọn thao tác chỉnh sửa:%s\n" "$C_GREEN" "$C_RESET"
    printf "  %s[1]%s Đổi passphrase\n" "$C_YELLOW" "$C_RESET"
    printf "  %s[2]%s Đổi comment\n"    "$C_YELLOW" "$C_RESET"
    printf "  %s[3]%s Đổi tên key\n"    "$C_YELLOW" "$C_RESET"
    printf "  %s[4]%s Quay lại\n"       "$C_YELLOW" "$C_RESET"
    echo
    read -rp "  Chọn thao tác: " act
    case "$act" in
        1) edit_passphrase "$edit_key_name" ;;
        2) edit_comment    "$edit_key_name" ;;
        3) edit_rename     "$edit_key_name" ;;
        *) return ;;
    esac
}

edit_passphrase() {
    local k="$1"
    echo
    msg_info "Đổi passphrase cho key: $k"
    echo
    printf "  %s(Bạn sẽ được yêu cầu nhập passphrase cũ, sau đó nhập passphrase mới)%s\n" "$C_YELLOW" "$C_RESET"
    echo
    if ssh-keygen -p -f "$SSH_DIR/$k"; then
        msg_ok "Đã đổi passphrase thành công."
    else
        msg_error "Đổi passphrase thất bại."
    fi
    pause_manage_key
}

edit_comment() {
    local k="$1"
    echo
    read -rp "  Nhập comment mới (Q để quay lại): " new_comment
    [[ "${new_comment,,}" == "q" || -z "$new_comment" ]] && return

    msg_info "Đang cập nhật comment cho key: $k"
    printf "  %s(Bạn có thể được yêu cầu nhập passphrase nếu key có mật khẩu)%s\n" "$C_YELLOW" "$C_RESET"
    echo
    if ssh-keygen -c -C "$new_comment" -f "$SSH_DIR/$k"; then
        msg_ok "Đã đổi comment thành công."
    else
        msg_error "Đổi comment thất bại."
    fi
    pause_manage_key
}

edit_rename() {
    local old_name="$1"
    echo
    read -rp "  Nhập tên mới cho key (Q để quay lại): " new_name
    [[ "${new_name,,}" == "q" || -z "$new_name" ]] && return

    if [[ -e "$SSH_DIR/$new_name" ]]; then
        msg_error "Key với tên $new_name đã tồn tại."
        pause_manage_key
        return
    fi

    mv "$SSH_DIR/$old_name" "$SSH_DIR/$new_name"
    if [[ -f "$SSH_DIR/$old_name.pub" ]]; then
        mv "$SSH_DIR/$old_name.pub" "$SSH_DIR/$new_name.pub"
    fi

    # Cập nhật IdentityFile trong config
    if [[ -f "$CONFIG_FILE" ]]; then
        local old_path="$SSH_DIR/$old_name"
        local new_path="$SSH_DIR/$new_name"
        # Dùng sed với delimiter | để tránh xung đột dấu /
        sed -i.bak "s|${old_path}|${new_path}|g" "$CONFIG_FILE"
        rm -f "$CONFIG_FILE.bak"
    fi

    # Cập nhật comment trong public key
    if [[ -f "$SSH_DIR/$new_name.pub" ]]; then
        awk -v name="$new_name" '{print $1, $2, name}' "$SSH_DIR/$new_name.pub" > "$SSH_DIR/$new_name.pub.tmp"
        mv "$SSH_DIR/$new_name.pub.tmp" "$SSH_DIR/$new_name.pub"
    fi

    msg_ok "Đã đổi tên key: $old_name -> $new_name"
    pause_manage_key
}

# ===== Quản lý host config =====
parse_hosts() {
    HOST_LIST=()
    HOST_HOSTNAME=()
    [[ -f "$CONFIG_FILE" ]] || return
    local current_alias="" current_hostname=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Loại bỏ khoảng trắng đầu
        local trimmed="${line#"${line%%[![:space:]]*}"}"
        # Bỏ qua dòng trống và comment
        [[ -z "$trimmed" || "$trimmed" == \#* ]] && continue

        local kw rest
        kw="${trimmed%%[[:space:]]*}"
        rest="${trimmed#"$kw"}"
        rest="${rest#"${rest%%[![:space:]]*}"}"

        if [[ "${kw,,}" == "host" ]]; then
            # Lưu host trước đó (nếu có)
            if [[ -n "$current_alias" ]]; then
                HOST_LIST+=("$current_alias")
                HOST_HOSTNAME+=("${current_hostname:-(không rõ)}")
            fi
            # Bỏ qua wildcard
            if [[ "$rest" == "*" || "$rest" == "?" ]]; then
                current_alias=""
                current_hostname=""
            else
                current_alias="$rest"
                current_hostname=""
            fi
        elif [[ "${kw,,}" == "hostname" && -n "$current_alias" ]]; then
            current_hostname="$rest"
        fi
    done < "$CONFIG_FILE"
    if [[ -n "$current_alias" ]]; then
        HOST_LIST+=("$current_alias")
        HOST_HOSTNAME+=("${current_hostname:-(không rõ)}")
    fi
}

show_hosts_table() {
    box "BẢNG HOST TRONG CONFIG"
    echo
    printf "  ╔══════╦══════════════════════════════════════╦════════════════════╗\n"
    printf "  ║ %-4s ║ %-36s ║ %-18s ║\n" "STT" "ALIAS" "HOSTNAME"
    printf "  ╠══════╬══════════════════════════════════════╬════════════════════╣\n"
    parse_hosts
    if [[ ${#HOST_LIST[@]} -eq 0 ]]; then
        printf "  ║ %s%-64s%s ║\n" "$C_RED" "(Chưa có host nào)" "$C_RESET"
    else
        local i=1
        for alias in "${HOST_LIST[@]}"; do
            local hn="${HOST_HOSTNAME[$((i-1))]}"
            local alias_disp="${alias:0:36}"
            local hn_disp="${hn:0:18}"
            printf "  ║ %s%-4d%s ║ %-36s ║ %-18s ║\n" "$C_YELLOW" "$i" "$C_RESET" "$alias_disp" "$hn_disp"
            ((i++))
        done
    fi
    printf "  ╚══════╩══════════════════════════════════════╩════════════════════╝\n"
    echo
}

get_host_by_index() {
    local idx="$1"
    if ! [[ "$idx" =~ ^[0-9]+$ ]]; then return 1; fi
    if (( idx < 1 || idx > ${#HOST_LIST[@]} )); then return 1; fi
    SELECTED_HOST="${HOST_LIST[$((idx-1))]}"
    return 0
}

manage_host_menu() {
    clear
    header
    echo
    box "THÊM / SỬA / XOÁ CẤU HÌNH HOST"
    echo

    show_keys_select || { pause_menu; return; }
    read -rp "  Chọn số SSH key (hoặc Q để về menu): " idx
    [[ "${idx,,}" == "q" || -z "$idx" ]] && return

    if ! get_key_by_index "$idx"; then
        msg_error "Số key không hợp lệ."
        pause_menu
        return
    fi

    msg_info "Key đã chọn: $SELECTED_KEY"
    echo
    show_hosts_table
    read -rp "  Nhập số host để sửa/xoá, hoặc Enter để thêm mới (Q để về menu): " host_choice
    [[ "${host_choice,,}" == "q" ]] && return

    if [[ -z "$host_choice" ]]; then
        add_host
        return
    fi

    if ! get_host_by_index "$host_choice"; then
        msg_error "Số host không hợp lệ."
        pause_menu
        return
    fi

    msg_info "Host đã chọn: $SELECTED_HOST"
    printf "  %s[1]%s Sửa block\n"  "$C_YELLOW" "$C_RESET"
    printf "  %s[2]%s Xoá block\n"  "$C_YELLOW" "$C_RESET"
    printf "  %s[3]%s Quay lại\n"   "$C_YELLOW" "$C_RESET"
    read -rp "  Chọn thao tác: " act
    case "$act" in
        1) edit_host ;;
        2) delete_host ;;
        *) return ;;
    esac
}

read_with_default() {
    local prompt="$1" default="$2" __outvar="$3"
    local val
    read -rp "  $prompt: " val
    [[ "${val,,}" == "q" ]] && return 1
    [[ -z "$val" ]] && val="$default"
    printf -v "$__outvar" '%s' "$val"
    return 0
}

add_host() {
    local real_host alias_new ssh_user ssh_port
    read_with_default "HostName thật (mặc định: github.com)" "github.com" real_host || return
    read_with_default "Alias trong config" "$real_host" alias_new || return
    read_with_default "User SSH (mặc định: git)" "git" ssh_user || return
    read_with_default "Port SSH (mặc định: 22)" "22" ssh_port || return

    append_block "$alias_new" "$real_host" "$ssh_user" "$ssh_port" "$SSH_DIR/$SELECTED_KEY"
    msg_ok "Đã thêm block cấu hình."
    pause_menu
}

edit_host() {
    local target="$SELECTED_HOST"
    local real_host alias_new ssh_user ssh_port
    read_with_default "HostName thật mới (mặc định: github.com)" "github.com" real_host || return
    read_with_default "Alias mới" "$target" alias_new || return
    read_with_default "User SSH mới (mặc định: git)" "git" ssh_user || return
    read_with_default "Port SSH mới (mặc định: 22)" "22" ssh_port || return

    remove_host_block "$target"
    append_block "$alias_new" "$real_host" "$ssh_user" "$ssh_port" "$SSH_DIR/$SELECTED_KEY"
    msg_ok "Đã cập nhật block cấu hình."
    pause_menu
}

delete_host() {
    remove_host_block "$SELECTED_HOST"
    msg_ok "Đã xoá block host: $SELECTED_HOST"
    pause_menu
}

append_block() {
    local alias="$1" hostname="$2" user="$3" port="$4" identity="$5"
    {
        echo
        echo "Host $alias"
        echo "    HostName $hostname"
        echo "    User $user"
        echo "    Port $port"
        echo "    IdentityFile $identity"
        echo "    IdentitiesOnly yes"
    } >> "$CONFIG_FILE"
}

remove_host_block() {
    local target="$1"
    [[ -f "$CONFIG_FILE" ]] || return 0
    awk -v target="$target" '
        BEGIN { skip=0 }
        {
            line=$0
            trimmed=line
            sub(/^[ \t]+/, "", trimmed)
            # Tách keyword đầu
            n=split(trimmed, parts, /[ \t]+/)
            kw=tolower(parts[1])
            if (kw == "host") {
                rest=trimmed
                sub(/^[Hh][Oo][Ss][Tt][ \t]+/, "", rest)
                if (rest == target) {
                    skip=1
                    next
                } else {
                    skip=0
                }
            }
            if (skip==0) print line
        }
    ' "$CONFIG_FILE" > "$TMP_FILE"
    mv "$TMP_FILE" "$CONFIG_FILE"
}

remove_key_from_config() {
    local keypath="$1"
    [[ -f "$CONFIG_FILE" ]] || return 0
    grep -F -v "$keypath" "$CONFIG_FILE" > "$TMP_FILE" || true
    mv "$TMP_FILE" "$CONFIG_FILE"
}

# ===== Test SSH =====
test_ssh() {
    clear
    header
    echo
    box "TEST KẾT NỐI SSH"
    echo

    parse_hosts
    if [[ ${#HOST_LIST[@]} -eq 0 ]]; then
        msg_error "Chưa có host nào trong config để test."
        pause_manage_key
        return
    fi
    show_hosts_table

    read -rp "  Chọn số host để test (hoặc Q để quay lại): " idx
    [[ "${idx,,}" == "q" || -z "$idx" ]] && return

    if ! get_host_by_index "$idx"; then
        msg_error "Số host không hợp lệ."
        pause_manage_key
        return
    fi

    msg_info "Đang test kết nối tới: $SELECTED_HOST"
    echo
    printf "  %s─────────────────────────────────────────────────────────%s\n" "$C_YELLOW" "$C_RESET"
    echo
    ssh -T "$SELECTED_HOST"
    local ssh_exit=$?
    echo
    printf "  %s─────────────────────────────────────────────────────────%s\n" "$C_YELLOW" "$C_RESET"
    echo

    if [[ $ssh_exit -eq 0 ]]; then
        msg_ok "Kết nối thành công!"
    elif [[ $ssh_exit -eq 1 ]]; then
        msg_ok "Xác thực thành công! (Server không cho phép shell - bình thường với GitHub/GitLab)"
    else
        msg_error "Kết nối thất bại (exit code: $ssh_exit). Kiểm tra lại cấu hình."
    fi
    pause_manage_key
}

# ===== Xem config =====
show_config() {
    clear
    header
    echo
    box "NỘI DUNG CONFIG"
    echo

    if [[ ! -f "$CONFIG_FILE" ]]; then
        msg_error "Chưa có file config."
    else
        if command -v less >/dev/null 2>&1 && [[ -s "$CONFIG_FILE" ]]; then
            cat "$CONFIG_FILE"
        else
            cat "$CONFIG_FILE"
        fi
    fi
    echo
    pause_menu
}

# ===== Menu chính =====
main_menu() {
    while true; do
        clear
        header
        echo
        box "MENU CHÍNH"
        echo
        menu_item 1 "Danh sách SSH key / Copy public key"           "$C_GREEN"
        menu_item 2 "Quản lý SSH key (tạo / sửa / xoá / test)"      "$C_CYAN"
        menu_item 3 "Thêm / sửa / xoá cấu hình host"                "$C_MAGENTA"
        menu_item 4 "Xem nội dung config"                           "$C_YELLOW"
        menu_item 0 "Thoát"                                         "$C_GRAY"
        echo
        read -rp "  Chọn chức năng: " opt
        case "$opt" in
            1) list_keys_menu ;;
            2) manage_key_menu ;;
            3) manage_host_menu ;;
            4) show_config ;;
            0|q|Q) clear; exit 0 ;;
        esac
    done
}

# ===== Bootstrap =====
trap 'printf "%s" "$C_RESET"; exit' INT TERM
detect_clipboard
init_ssh_dir
main_menu
