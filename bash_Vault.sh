#!/bin/bash
DB="vault.db"
AUDIT_LOG_FILE="audit.log"
KEYFILE="master.key"

init_key() {
    if [ ! -f "$KEYFILE" ]; then
        openssl rand -base64 32 > "$KEYFILE"
    fi
}

enc() {
    echo -n "$1" | openssl enc -aes-256-cbc -pbkdf2 -salt -pass file:"$KEYFILE" 2>/dev/null | base64
}

dec() {
    echo -n "$1" | base64 -d | openssl enc -aes-256-cbc -d -pbkdf2 -pass file:"$KEYFILE" 2>/dev/null
}

gen_pass() {
    len="$1"
    if [ -z "$len" ]; then len=12; fi
    tr -dc A-Za-z0-9 </dev/urandom | head -c "$len"
}

initdb() {

    sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS vault (id INTEGER PRIMARY KEY, key TEXT UNIQUE, value TEXT);" 2>/dev/null


}

add() {


    k="$1"
    v="$2"



    if [ -z "$k" ] || [ -z "$v" ]; then
        echo "Please enter both a key and a value."
        return 1
    fi



    if ! sqlite3 "$DB" "INSERT INTO vault (key,value) VALUES ('$k','$v');" 2>/tmp/_add_err; then
        echo "Error adding entry:"
        cat /tmp/_add_err
        return 1
    else
        echo "Entry added successfully."
        return 0
    fi
}

find_entry() {
    x="$1"
    if [ -z "$x" ]; then
        return 1
    fi

    exists=$(sqlite3 "$DB" "SELECT 1 FROM vault WHERE key='$x';")

    if [ -z "$exists" ]; then
        return 1
    else
        return 0
    fi
}

edit_entry() {
    a="$1"
    b="$2"

    if [ -z "$a" ] || [ -z "$b" ]; then
        echo "Please provide a key and a new value."
        return 1
    fi

    if ! find_entry "$a"; then
        echo "That key does not exist."
        return 1
    fi

    if ! sqlite3 "$DB" "UPDATE vault SET value='$b' WHERE key='$a';" 2>/tmp/_edit_err; then
        echo "Failed to update entry."
        cat /tmp/_edit_err
        return 1
    else
        echo "Entry updated."
        return 0
    fi
}

delete_entry() {
    zzz="$1"

    if [ -z "$zzz" ]; then
        echo "Please enter a key to delete."
        return 1
    fi


    if ! find_entry "$zzz"; then
        echo "No entry found for that key."
        return 1
    fi




    if ! sqlite3 "$DB" "DELETE FROM vault WHERE key='$zzz';" 2>/tmp/_del_err; then
        echo "Failed to delete entry."
        cat /tmp/_del_err
        return 1
    else
        echo "Entry deleted."
        return 0
    fi
}

record_event() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$USER] - INFO: $1" >> "$AUDIT_LOG_FILE"
}

record_failed_access() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$USER] - WARNING: Failed access - $1" >> "$AUDIT_LOG_FILE"
}

view_audit_log() {
    less "$AUDIT_LOG_FILE"
}

init_key
initdb

echo ""
echo "Password Vault"
echo "---------------"
echo "1) Add entry"
echo "2) Find entry"
echo "3) Edit entry"
echo "4) Delete entry"
echo "5) Generate random password"
echo "6) View audit log"
echo ""
read -p "Choose an option: " o

case "$o" in

    1)
        read -p "Key: " kk
        read -p "Value: " vv
        add "$kk" "$(enc "$vv")"
        record_event "ADD key=$kk"
        ;;


    2)
        read -p "Key: " kx

        if find_entry "$kx"; then
            enc_val=$(sqlite3 "$DB" "SELECT value FROM vault WHERE key='$kx';")
            dec "$enc_val"
            record_event "FIND key=$kx"
        else
            echo "No matching entry found."
            record_failed_access "FIND key=$kx"
        fi
        ;;


    3)
        read -p "Key: " k1
        read -p "New Value: " k2
        edit_entry "$k1" "$(enc "$k2")"
        record_event "EDIT key=$k1";;


    4)
        read -p "Key: " k3
        delete_entry "$k3"
        record_event "DELETE key=$k3"
        ;;

    5)
        read -p "Length: " L
        gen_pass "$L"
        record_event "GENERATE_PASSWORD length=$L"
        ;;

    6)
        view_audit_log
        ;;

    *)
        echo "Invalid option."
        record_failed_access "INVALID_OPTION"
        ;;
esac
