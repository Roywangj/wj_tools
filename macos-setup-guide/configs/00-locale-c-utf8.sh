# Optional: /etc/profile.d/00-locale-c-utf8.sh
# For images that only ship C / C.utf8 (no en_US.UTF-8).
# Install (root): sudo cp configs/00-locale-c-utf8.sh /etc/profile.d/

export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export LC_CTYPE=C.UTF-8
