#!/bin/bash

# Check if domain name is provided as argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <domain_name>"
else
    # Domain name
    domain=$1

    # Generate private key
    openssl genrsa -out "${domain}.test.key" 2048

    # Generate certificate signing request
    openssl req -new -key "${domain}.test.key" -out "${domain}.test.csr" -subj "/CN=${domain}"

    # Create a certificate configuration file
    cat <<EOF > "${domain}.test.ext"
        authorityKeyIdentifier=keyid,issuer
        basicConstraints=CA:FALSE
        keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
        subjectAltName = @alt_names

        [alt_names]
        DNS.1 = ${domain}.euler.local
EOF

    # Sign the certificate using the CA
    openssl x509 -req -in "${domain}.test.csr" -CA myCA.pem -CAkey myCA.key -CAcreateserial -out "${domain}.test.crt" -days 365 -sha256 -extfile "${domain}.test.ext"

    # Clean up temporary files
    rm "${domain}.test.csr" "${domain}.test.ext"

    echo "Certificates for domain ${domain} generated successfully."

    # Append certificate details to certs-traefik.yml file
    cat <<EOF >> certs-traefik.yml
    - certFile: /etc/certs/${domain}.test.crt
      keyFile: /etc/certs/${domain}.test.key
EOF

    echo "Certificate details appended to certs-traefik.yml file."

fi
