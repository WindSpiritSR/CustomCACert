# Custom CA Cert

This Magisk module can install custom CA certificate to the system store by mount-bind `com.android.conscrypt`

Support Android 14

# Usage

## Generate certificate hash

`openssl x509 -subject_hash_old -in cert_name.pem`

Rename certificate file to `cert_hash.0` like `364618e0.0`

Put your certificate file to `system/etc/security/cacerts`

## Zip all files

Run `zip -r CustomCACert.zip ./*` in `CustomCACert` module folder. Put all files into zip archive, instead of zipping a single directory

## Install module zip in Magisk
