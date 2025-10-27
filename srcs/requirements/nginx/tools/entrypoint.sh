set -e

CERT_DIR=/etc/nginx/certs
KEY=${CERT_DIR}/server.key
CRT=${CERT_DIR}/server.crt

mkdir -p "${CERT_DIR}"

if [ ! -f "${CRT}" ] || [ ! -f "${KEY}" ]; then
  openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -subj "/CN=${DOMAIN_NAME}" \
    -keyout "${KEY}" -out "${CRT}"
fi

exec "$@"
