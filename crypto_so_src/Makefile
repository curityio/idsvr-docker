OUT_DIR ?= .
OPENSSL_DIR ?= /build

all crypto.so: crypto.c
	gcc -s -o $(OUT_DIR)/crypto.so -fPIC -I. -Wall -O2 -DHAVE_DYNAMIC_CRYPTO_LIB crypto.c -lcrypto -shared -I$(OPENSSL_DIR)/include -L$(OPENSSL_DIR)/lib

clean:
	rm -f crypto.so
